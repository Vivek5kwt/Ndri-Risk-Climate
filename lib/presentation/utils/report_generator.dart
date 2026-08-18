import 'dart:io' show Directory, File, Platform;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../data/services/location_service.dart';
import '../../logic/risk_assessment/bloc/risk_assessment_bloc.dart';
import '../../logic/risk_assessment/bloc/risk_assessment_state.dart';
import '../../logic/score_calculate/question_weight.dart';

class ReportGenerator {
  // ==== Excel normalization constants ====
  // Exposure (B3):
  static const double _expMin = 0.1964;
  static const double _expMax = 0.6196;

  // Hazard:
  static const double _hazMin = 0.1125;
  static const double _hazMax = 0.5672;

  // Vulnerability (D3):
  static const double _vulnMin = 0.3967;
  static const double _vulnMax = 0.857;

  // Risk normalization divisor from Excel
  static const double _riskDivisor = 0.61779;

  // ===== Helpers =====
  static double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

  static String _bandLabel(double v) {
    if (v < 0.2) return 'Very Low';
    if (v <= 0.4) return 'Low';
    if (v <= 0.6) return 'Moderate';
    if (v <= 0.8) return 'High';
    return 'Very High';
  }

  // Exposure specific bands based on RAW exposure value (B3)
  // Very Low (0.1694 – 0.3628)
  // Low       (0.3629 – 0.4251)
  // Medium    (0.4252 – 0.4669)
  // High      (0.4670 – 0.5130)
  // Very High (0.5131 – 0.6196)
  static String _exposureBandLabel(double b3) {
    if (b3 < 0.1694) return 'Very Low';
    if (b3 <= 0.3628) return 'Very Low';
    if (b3 <= 0.4251) return 'Low';
    if (b3 <= 0.4669) return 'Medium';
    if (b3 <= 0.5130) return 'High';
    return 'Very High';
  }

  /// Standard rounding (used for the big risk number with 2 decimals).
  static String _asFixed(num val, {int digits = 3}) {
    return (val).toStringAsFixed(digits);
  }

  /// Truncate (floor) to N decimals (for 3-dp display on bars).
  static String _toFixedTrunc(num val, {int digits = 3}) {
    if (digits < 0) digits = 0;
    final p = pow(10, digits).toDouble();
    final t = (val * p).floor() / p;
    return t.toStringAsFixed(digits);
  }

  static PdfColor _riskColor(String level) {
    switch (level.toLowerCase()) {
      case 'very low':
        return PdfColor.fromHex('#1d4517');
      case 'low':
        return PdfColor.fromHex('#03cd03');
      case 'moderate':
        return PdfColor.fromHex('#0303ff');
      case 'high':
        return PdfColor.fromHex('#ff0303');
      case 'very high':
        return PdfColor.fromHex('#c10303');
      default:
        return PdfColors.grey;
    }
  }

  static double _normalize(double raw, double minV, double maxV) {
    if (maxV == minV) return 0;
    return (raw - minV) / (maxV - minV);
  }

  static Future<void> generate({
    required BuildContext context,
    required Map<String, dynamic> answers,
    required FlutterLocalNotificationsPlugin notifications,
    required Future<void> Function() initPermissions,
    required String name,
    required String block,
    required String village,
    String? stateName,
    String? district,
  }) async {
    final st = context.read<RiskAssessmentBloc>().state;
    final messenger = ScaffoldMessenger.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    await initPermissions();
    if (st is! RiskAssessmentLoaded) {
      throw StateError('Report data is still loading. Please try again.');
    }

    // ==== 1) RAW scores ====
    final formattedAnswers = answers.map((k, v) => MapEntry(k, v.toString()));

    final vulnDetails = computeVulnerabilityDetails(formattedAnswers);
    final expDetails = computeExposureDetails(formattedAnswers);

    debugPrint('Exposure question values:');
    (expDetails['values'] as Map<String, double>)
        .forEach((k, v) => debugPrint('$k: $v'));
    debugPrint('Exposure sum: ${expDetails['sum']}');

    debugPrint('Vulnerability question values:');
    (vulnDetails['values'] as Map<String, double>)
        .forEach((k, v) => debugPrint('$k: $v'));
    debugPrint('Vulnerability sum: ${vulnDetails['sum']}');

    // Final averages B3 (Exposure) and D3 (Vulnerability)
    final double b3Exposure = (expDetails['score'] as double?) ?? 0.0;
    final double d3Vulnerability = (vulnDetails['score'] as double?) ?? 0.0;
    final double rawHazard = LocationService().hazardFor(district ?? '');

    // ==== 2) Normalize per Excel ====
    final double acceptedExposure = _clamp01(_normalize(
        b3Exposure, _expMin, _expMax)); // (B3 - 0.1964) / (0.6196 - 0.1964)
    final double acceptedVulnerability = _clamp01(_normalize(d3Vulnerability,
        _vulnMin, _vulnMax)); // (D3 - 0.3967) / (0.857 - 0.3967)
    final double acceptedHazard =
        _clamp01(_normalize(rawHazard, _hazMin, _hazMax));

    // Logs to verify against Excel
    debugPrint(
        'B3 (raw exposure)..................: ${b3Exposure.toStringAsFixed(9)}');
    debugPrint(
        'Accepted Exposure (0-1).............: ${acceptedExposure.toStringAsFixed(9)}');
    debugPrint(
        'D3 (raw vulnerability)..............: ${d3Vulnerability.toStringAsFixed(9)}');
    debugPrint(
        'Accepted Vulnerability (0-1)........: ${acceptedVulnerability.toStringAsFixed(9)}');
    debugPrint(
        'Accepted Hazard (0-1)...............: ${acceptedHazard.toStringAsFixed(9)}');

    // ==== 3) Status labels ====
    final String exposureStatus = _exposureBandLabel(b3Exposure);
    final String vulnerabilityStatus = _bandLabel(acceptedVulnerability);
    final String hazardStatus = _bandLabel(acceptedHazard);

    // ==== 4) Risk ====
    final double calculatedRisk =
        acceptedExposure * acceptedHazard * acceptedVulnerability;
    final double acceptedRisk =
        calculatedRisk / _riskDivisor; // per Excel (no clamp)
    final String riskStatus = _bandLabel(acceptedRisk);

    // ==== 5) Build PDF ====
    final pdf = pw.Document();

    // Fonts & images
    final garamondRegular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/EBGaramond-Regular.ttf'),
    );
    final garamondBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/EBGaramond-Bold.ttf'),
    );
    final garamondMedium = pw.Font.ttf(
      await rootBundle.load('assets/fonts/EBGaramond-Medium.ttf'),
    );
    final garamondSemiBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/EBGaramond-SemiBold.ttf'),
    );
    final garamondExtraBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/EBGaramond-ExtraBold.ttf'),
    );

    final bgImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/ic_socio_climatic_dia.webp'))
          .buffer
          .asUint8List(),
    );
    final barImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/hazard_bar.png'))
          .buffer
          .asUint8List(),
    );
    final rainbowGaugeImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/rainbow_color.png'))
          .buffer
          .asUint8List(),
    );
    final pointerArrowImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/score_arrow.png'))
          .buffer
          .asUint8List(),
    );
    final pointerDotImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/white_dot.png'))
          .buffer
          .asUint8List(),
    );

    // Colors
    final stateBlockLabelColor = PdfColor.fromHex('#843b0c');
    final yellowLabelColor = PdfColor.fromHex('#ffff03');
    final bgBlueColor = PdfColor.fromHex('#01949a');
    final disclaimerColor = PdfColor.fromHex('#7232a1');

    pw.Widget _legendRow(PdfColor color, String label) {
      return pw.Padding(
        padding: pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Container(
              width: 22,
              height: 22,
              decoration: pw.BoxDecoration(
                color: color,
                borderRadius: pw.BorderRadius.circular(3),
                border: pw.Border.all(color: PdfColors.black, width: 1.2),
              ),
            ),
            pw.SizedBox(width: 7),
            pw.Text(label,
                style: pw.TextStyle(fontSize: 18, font: garamondSemiBold)),
          ],
        ),
      );
    }

    // ------------------ Calibrated Gauge (pointer drawn LAST) ------------------
    pw.Widget _gaugeWithPointerCalibrated({
      required double value, // clamped to [0,1]
      required pw.MemoryImage gaugeImage,
      required pw.MemoryImage pointerImage,
      double width = 640,
      double height = 340,
      // Anchor positions as fractions of (width,height). Tuned to rainbow_color.png.
      double leftFracX = 0.155,
      double leftFracY = 0.76,
      double topFracX = 0.500,
      double topFracY = 0.245,
      double rightFracX = 0.845,
      double rightFracY = 0.76,
      // Move pointer inward to sit roughly mid-thickness of the ring.
      double radialOffset = 8.0,
      double pointerSize = 26,
      bool rotatePointerAlongTangent = false,
    }) {
      final v = _clamp01(value);

      // Resolve anchors to absolute pixels
      final x1 = width * leftFracX, y1 = height * leftFracY;
      final x2 = width * topFracX, y2 = height * topFracY;
      final x3 = width * rightFracX, y3 = height * rightFracY;

      // Circumcircle through 3 points
      final double d = 2 * (x1 * (y2 - y3) + x2 * (y3 - y1) + x3 * (y1 - y2));

      // Fallback if nearly collinear
      double cx, cy, r;
      if (d.abs() < 1e-6) {
        cx = width / 2;
        cy = height - 72;
        r = width / 2 - 155;
      } else {
        final double x1s = x1 * x1 + y1 * y1;
        final double x2s = x2 * x2 + y2 * y2;
        final double x3s = x3 * x3 + y3 * y3;

        cx = (x1s * (y2 - y3) + x2s * (y3 - y1) + x3s * (y1 - y2)) / d;
        cy = (x1s * (x3 - x2) + x2s * (x1 - x3) + x3s * (x2 - x1)) / d;
        r = sqrt((x1 - cx) * (x1 - cx) + (y1 - cy) * (y1 - cy));
      }

      // Angles for the left and right anchors
      double aLeft = atan2(y1 - cy, x1 - cx);
      double aRight = atan2(y3 - cy, x3 - cx);
      if (aLeft < aRight) aLeft += 2 * pi; // ensure we sweep across the top arc

      final angle = aLeft + (aRight - aLeft) * v;
      final rAdj = max(1.0, r - radialOffset);

      final px = cx + rAdj * cos(angle);
      final py = cy + rAdj * sin(angle);

      final needle = rotatePointerAlongTangent
          ? pw.Transform.rotate(
              angle: -(pi / 2 - angle),
              child: pw.Image(pointerImage,
                  width: pointerSize, height: pointerSize),
            )
          : pw.Image(pointerImage, width: pointerSize, height: pointerSize);

      return pw.Container(
        width: width,
        height: height,
        alignment: pw.Alignment.center,
        child: pw.Stack(
          children: [
            // 1) gauge image
            pw.Image(gaugeImage,
                width: width, height: height, fit: pw.BoxFit.contain),

            // 2) centered date + score (this used to cover the dot)
            pw.Positioned.fill(
              child: pw.Center(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      DateFormat('MMM d, yyyy').format(DateTime.now()) + '  ',
                      style: pw.TextStyle(
                          fontSize: 30,
                          fontWeight: pw.FontWeight.bold,
                          font: garamondSemiBold),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      _asFixed(acceptedRisk, digits: 2) + '  ',
                      style: pw.TextStyle(
                        fontSize: 50,
                        font: garamondBold,
                        color: PdfColor.fromHex('#0303ff'),
                      ),
                    ),
                    pw.SizedBox(height: 3),
                  ],
                ),
              ),
            ),

            // 3) pointer ON TOP so it's always visible
            pw.Positioned(
              left: px - pointerSize / 2,
              top: py - pointerSize / 2,
              child: needle,
            ),
          ],
        ),
      );
    }
    // ------------------ /Calibrated Gauge ------------------

    pw.Widget _imageScoreBarWithArrow({
      required String label,
      required String scoreText, // (formatted string)
      required double value, // accepted 0..1 (for pointer)
      required String status,
      required pw.MemoryImage barImage,
      required pw.MemoryImage pointerImage,
      pw.Font? font,
      double barWidth = 160,
      double barHeight = 34,
    }) {
      final clamped = _clamp01(value);
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 15),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.SizedBox(
              width: 215,
              child: pw.Text(label,
                  style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      font: font)),
            ),
            pw.SizedBox(width: 5),
            pw.Container(
              width: barWidth,
              height: barHeight + 20,
              child: pw.Stack(
                children: [
                  pw.Positioned(
                    left: 0,
                    top: 14,
                    child:
                        pw.Image(barImage, width: barWidth, height: barHeight),
                  ),
                  pw.Positioned(
                    left: (barWidth - 22) * clamped,
                    top: 0,
                    child: pw.Image(pointerImage, width: 22, height: 22),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 5),
            pw.Container(
              width: 61,
              alignment: pw.Alignment.center,
              child: pw.Text(scoreText,
                  style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      font: font)),
            ),
            pw.SizedBox(width: 5),
            pw.Container(
              width: 80,
              child: pw.Text(
                status,
                style: pw.TextStyle(
                  fontSize: 20,
                  color: _riskColor(status),
                  fontWeight: pw.FontWeight.bold,
                  font: font,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ---- Single extra-long page ----
    final PdfPageFormat longA4 = PdfPageFormat.a4.copyWith(
      width: PdfPageFormat.a4.width,
      height: PdfPageFormat.a4.height * 1.4,
      marginLeft: 0,
      marginRight: 0,
      marginTop: 0,
      marginBottom: 0,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: longA4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context ctx) {
          // 3-decimal TRUNCATION for the bars (matches your Excel intent)
          final vulnText = _toFixedTrunc(acceptedVulnerability, digits: 3);
          final expoText = _toFixedTrunc(acceptedExposure, digits: 3);
          final hazText = _toFixedTrunc(acceptedHazard, digits: 3);

          return pw.Stack(
            children: [
              // Background image centered
              pw.Positioned.fill(
                child: pw.Center(
                  child: pw.Opacity(
                    opacity: 0.1,
                    child: pw.Image(
                      bgImage,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Container(
                    width: double.infinity,
                    height: 130,
                    decoration: pw.BoxDecoration(
                      color: bgBlueColor,
                      borderRadius: pw.BorderRadius.only(
                        bottomLeft: pw.Radius.circular(80),
                        bottomRight: pw.Radius.circular(80),
                      ),
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          'Socio-climatic Risk of',
                          style: pw.TextStyle(
                            fontSize: 46,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            font: garamondBold,
                          ),
                        ),
                        pw.Text(
                          'Smallholder Dairy Farmer',
                          style: pw.TextStyle(
                            fontSize: 36,
                            fontWeight: pw.FontWeight.bold,
                            color: yellowLabelColor,
                            font: garamondSemiBold,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 10),

                  // Farmer meta
                  pw.Padding(
                    padding: pw.EdgeInsets.symmetric(horizontal: 20),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(children: [
                          pw.Text('Name of the dairy farmer: ',
                              style: pw.TextStyle(
                                  fontSize: 22, font: garamondExtraBold)),
                          pw.Expanded(
                            child: pw.Text(
                              name,
                              style: pw.TextStyle(
                                  fontSize: 22,
                                  color: PdfColor.fromHex('#0303ff'),
                                  font: garamondSemiBold),
                            ),
                          ),
                        ]),
                        pw.SizedBox(height: 8),
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Expanded(
                              child: pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'State: ',
                                    style: pw.TextStyle(
                                        fontSize: 22,
                                        color: stateBlockLabelColor,
                                        font: garamondBold),
                                  ),
                                  pw.Expanded(
                                    child: pw.Text(
                                      stateName ?? '',
                                      style: pw.TextStyle(
                                          fontSize: 22,
                                          color: PdfColor.fromHex('#0303ff'),
                                          font: garamondSemiBold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            pw.SizedBox(width: 16),
                            pw.Expanded(
                              child: pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'Block: ',
                                    style: pw.TextStyle(
                                        fontSize: 22,
                                        color: stateBlockLabelColor,
                                        font: garamondBold),
                                  ),
                                  pw.Expanded(
                                    child: pw.Text(
                                      block,
                                      style: pw.TextStyle(
                                          fontSize: 22,
                                          color: PdfColor.fromHex('#0303ff'),
                                          font: garamondSemiBold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 5),
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Expanded(
                              child: pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('District: ',
                                      style: pw.TextStyle(
                                          fontSize: 22,
                                          color: stateBlockLabelColor,
                                          font: garamondBold)),
                                  pw.Expanded(
                                    child: pw.Text(
                                      district ?? '',
                                      style: pw.TextStyle(
                                          fontSize: 22,
                                          color: PdfColor.fromHex('#0303ff'),
                                          font: garamondSemiBold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            pw.SizedBox(width: 16),
                            pw.Expanded(
                              child: pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('Village: ',
                                      style: pw.TextStyle(
                                          fontSize: 22,
                                          color: stateBlockLabelColor,
                                          font: garamondBold)),
                                  pw.Expanded(
                                    child: pw.Text(
                                      village,
                                      style: pw.TextStyle(
                                          fontSize: 22,
                                          color: PdfColor.fromHex('#0303ff'),
                                          font: garamondSemiBold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 12),

                  // === Bars (3 dp truncated) ===
                  _imageScoreBarWithArrow(
                    label: '1. Vulnerability score',
                    scoreText: vulnText,
                    value: acceptedVulnerability,
                    status: vulnerabilityStatus,
                    barImage: barImage,
                    pointerImage: pointerArrowImage,
                    font: garamondBold,
                  ),
                  pw.SizedBox(height: 6),
                  _imageScoreBarWithArrow(
                    label: '2. Exposure score',
                    scoreText: expoText,
                    value: acceptedExposure,
                    status: exposureStatus,
                    barImage: barImage,
                    pointerImage: pointerArrowImage,
                    font: garamondBold,
                  ),
                  pw.SizedBox(height: 6),
                  _imageScoreBarWithArrow(
                    label: '3. Hazard score',
                    scoreText: hazText,
                    value: acceptedHazard,
                    status: hazardStatus,
                    barImage: barImage,
                    pointerImage: pointerArrowImage,
                    font: garamondBold,
                  ),

                  pw.SizedBox(height: 18),

                  // === Calibrated dynamic gauge (pointer now on TOP) ===
                  pw.Center(
                    child: _gaugeWithPointerCalibrated(
                      value: acceptedRisk,
                      gaugeImage: rainbowGaugeImage,
                      pointerImage: pointerDotImage, // or pointerArrowImage
                      width: 640,
                      height: 340,
                      leftFracX: 0.155, leftFracY: 0.76,
                      topFracX: 0.50, topFracY: 0.245,
                      rightFracX: 0.845, rightFracY: 0.76,
                      radialOffset: 8.0,
                      pointerSize: 26,
                      rotatePointerAlongTangent: false,
                    ),
                  ),

                  pw.SizedBox(height: 8),

                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text('Your socio-climatic risk is calculated to be',
                            style:
                                pw.TextStyle(fontSize: 24, font: garamondBold)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          riskStatus,
                          style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            font: garamondExtraBold,
                            color: _riskColor(riskStatus),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (riskStatus == 'High' || riskStatus == 'Very High')
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(14),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Remarks:',
                              style: pw.TextStyle(
                                  fontSize: 24,
                                  fontWeight: pw.FontWeight.bold,
                                  font: garamondExtraBold,
                                  color: stateBlockLabelColor)),
                          pw.Text(
                            'You are advised to contact your nearest KVK/ State Animal Husbandry personnel for customised adaptation plan of your dairy farm to minimise risk towards climate change.',
                            style: pw.TextStyle(
                                fontSize: 20, font: garamondMedium),
                          ),
                        ],
                      ),
                    ),

                  pw.SizedBox(height: 8),

                  // Legend
                  pw.Center(
                    child: pw.Wrap(
                      spacing: 24,
                      runSpacing: 8,
                      alignment: pw.WrapAlignment.center,
                      children: [
                        _legendRow(PdfColor.fromHex('#0ab152'), 'Very Low'),
                        _legendRow(PdfColor.fromHex('#7fcd70'), 'Low'),
                        _legendRow(PdfColor.fromHex('#f1e988'), 'Moderate'),
                        _legendRow(PdfColor.fromHex('#e07345'), 'High'),
                        _legendRow(PdfColor.fromHex('#be1505'), 'Very High'),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 20),

                  pw.Padding(
                    padding: pw.EdgeInsets.symmetric(horizontal: 12),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Disclaimer: ',
                          style: pw.TextStyle(
                              fontSize: 24,
                              color: disclaimerColor,
                              font: garamondExtraBold),
                        ),
                        pw.Text(
                          'Above socio-climatic risk score is calculated based on information provided by the farmer.',
                          style: pw.TextStyle(
                              fontSize: 20,
                              color: PdfColors.black,
                              font: garamondMedium),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // ==== Save / Share ====
    final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final pdfBytes = await pdf.save();

    // iOS apps cannot silently write into the user's Downloads folder. The
    // native share sheet lets the user preview, share, print, or Save to Files.
    if (Platform.isIOS) {
      final tempDir = await getTemporaryDirectory();
      final outFile = File('${tempDir.path}/$fileName');
      await outFile.writeAsBytes(pdfBytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(outFile.path, mimeType: 'application/pdf')],
          subject: 'Socio-Climatic Risk Report',
          title: 'Save or share report',
          sharePositionOrigin: renderBox != null && renderBox.hasSize
              ? renderBox.localToGlobal(Offset.zero) & renderBox.size
              : null,
        ),
      );
      return;
    }

    final downloadsDir = Platform.isAndroid
        ? Directory('/storage/emulated/0/Download')
        : (await getDownloadsDirectory())!;
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    final outFile = File('${downloadsDir.path}/$fileName');
    await outFile.writeAsBytes(pdfBytes, flush: true);

    const androidDetails = AndroidNotificationDetails(
      'reports',
      'Reports',
      channelDescription: 'Your report is ready',
      importance: Importance.high,
      priority: Priority.high,
    );
    await notifications.show(
      0,
      'Report saved',
      'Tap to open',
      NotificationDetails(android: androidDetails),
      payload: outFile.path,
    );

    if (messenger.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text('Report saved to Downloads as $fileName')),
      );
    }
  }
}
