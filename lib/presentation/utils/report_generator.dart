import 'dart:io' show Directory, File, Platform;
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/services/location_service.dart';
import '../../logic/risk_assessment/bloc/risk_assessment_bloc.dart';
import '../../logic/risk_assessment/bloc/risk_assessment_state.dart';
import '../../logic/score_calculate/question_weight.dart';

class ReportGenerator {
  // ==== Excel normalization constants ====
  static const double _expMin = 0.1964;
  static const double _expMax = 0.6196;

  static const double _hazMin = 0.1125;
  static const double _hazMax = 0.5672;

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

  static String _asFixed(dynamic val, {int digits = 3}) {
    if (val == null) return '0.${'0' * digits}';
    if (val is num) return val.toStringAsFixed(digits);
    if (val is String)
      return (double.tryParse(val) ?? 0).toStringAsFixed(digits);
    return '0.${'0' * digits}';
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
    await initPermissions();
    final st = context
        .read<RiskAssessmentBloc>()
        .state;
    if (st is! RiskAssessmentLoaded) return;

    // ==== 1) Get RAW model scores (0..1) ====
    final formattedAnswers = answers.map((k, v) => MapEntry(k, v.toString()));

    // These come from your existing scoring fns (pre-accepted 0..1)
    final vulnDetails = computeVulnerabilityDetails(formattedAnswers);
    final expDetails = computeExposureDetails(formattedAnswers);

    final double rawVuln = (vulnDetails['score'] as double?) ?? 0.0;
    final double rawExp = (expDetails['score'] as double?) ?? 0.0;

    // IMPORTANT: raw hazard from LocationService (e.g., "Ambala")
    final double rawHazard = LocationService().hazardFor(district ?? '');

    // ==== 2) Convert to ACCEPTED values using your Excel formulas ====
    final double acceptedExposure = _clamp01(
        _normalize(rawExp, _expMin, _expMax));
    final double acceptedHazard = _clamp01(
        _normalize(rawHazard, _hazMin, _hazMax));
    final double acceptedVulnerability = _clamp01(
        _normalize(rawVuln, _vulnMin, _vulnMax));

    // ==== 3) Status labels ====
    final String exposureStatus = _bandLabel(acceptedExposure);
    final String hazardStatus = _bandLabel(acceptedHazard);
    final String vulnerabilityStatus = _bandLabel(acceptedVulnerability);

    // ==== 4) Risk (Calculated + Accepted) ====
    final double calculatedRisk = acceptedExposure * acceptedHazard *
        acceptedVulnerability;
    final double acceptedRisk = calculatedRisk /
        _riskDivisor; // no clamp (per Excel)
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
            pw.Text(label, style: pw.TextStyle(
                fontSize: 18, font: garamondSemiBold)),
          ],
        ),
      );
    }

    pw.Widget _gaugeWithPointerDot({
      required double value,
      required pw.MemoryImage gaugeImage,
      required pw.MemoryImage pointerImage,
      double width = 500,
      double height = 250,
      double centerYOffset = 75,
      double dotSize = 22,
    }) {
      // Pointer is clamped for drawing only.
      final clamped = _clamp01(value);
      final centerX = width / 2;
      final centerY = height - centerYOffset;
      final angle = pi * (1 - clamped); // 0..1 -> 180..0 deg

      return pw.Container(
        width: width,
        height: height,
        alignment: pw.Alignment.center,
        child: pw.Stack(
          children: [
            pw.Image(gaugeImage, width: width,
                height: height,
                fit: pw.BoxFit.contain),
            pw.Positioned(
              left: centerX - dotSize / 4,
              right: 0,
              top: centerY - dotSize - 133, // tuned for your asset
              child: pw.Transform.rotate(
                angle: -angle,
                child: pw.Image(pointerImage, width: dotSize, height: dotSize),
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget _imageScoreBarWithArrow({
      required String label,
      required String scoreText, // accepted value
      required double value, // accepted value for pointer
      required String status, // band label
      required pw.MemoryImage barImage,
      required pw.MemoryImage pointerImage,
      pw.Font? font,
      double barWidth = 175,
      double barHeight = 33,
    }) {
      final clamped = _clamp01(value);
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 15),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.SizedBox(
              width: 220,
              child: pw.Text(label,
                  style: pw.TextStyle(fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      font: font)),
            ),
            pw.SizedBox(width: 6),
            pw.Container(
              width: barWidth,
              height: barHeight + 20,
              child: pw.Stack(
                children: [
                  pw.Positioned(
                    left: 0,
                    top: 14,
                    child: pw.Image(
                        barImage, width: barWidth, height: barHeight),
                  ),
                  pw.Positioned(
                    left: (barWidth - 22) * clamped,
                    top: 0,
                    child: pw.Image(pointerImage, width: 22, height: 22),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Container(
              width: 62,
              alignment: pw.Alignment.center,
              child: pw.Text(scoreText,
                  style: pw.TextStyle(fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      font: font)),
            ),
            pw.SizedBox(width: 6),
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

    // ---- Single extra-long page so NO content is cut off (no font weight change) ----
    final PdfPageFormat longA4 = PdfPageFormat.a4.copyWith(
      width: PdfPageFormat.a4.width,
      height: PdfPageFormat.a4.height * 1.4,
      // ~2.6x taller than A4 to fit everything
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
          final date = DateFormat('MMM d, yyyy').format(DateTime.now());
          return pw.Stack(
            children: [
              // Background image centered
              pw.Positioned.fill(
                child: pw.Center(
                  child: pw.Opacity(
                    opacity: 0.1,
                    child: pw.Image(
                      bgImage,
                      fit: pw.BoxFit.contain, // keep aspect ratio and center
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

                  // Farmer meta (wrap-safe, no truncation)
                  pw.Padding(
                    padding: pw.EdgeInsets.symmetric(horizontal: 20),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Name line (wrap value)
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

                        // State | Block (both wrap independently)
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Expanded(
                              child: pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'State: ',
                                    style: pw.TextStyle(fontSize: 22,
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
                                    style: pw.TextStyle(fontSize: 22,
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

                        // District | Village
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

                  // === Show ACCEPTED values + Status ===
                  _imageScoreBarWithArrow(
                    label: '1. Vulnerability score',
                    scoreText: _asFixed(acceptedVulnerability, digits: 3),
                    value: acceptedVulnerability,
                    status: vulnerabilityStatus,
                    barImage: barImage,
                    pointerImage: pointerArrowImage,
                    font: garamondBold,
                  ),
                  pw.SizedBox(height: 6),
                  _imageScoreBarWithArrow(
                    label: '2. Exposure score',
                    scoreText: _asFixed(acceptedExposure, digits: 3),
                    value: acceptedExposure,
                    status: exposureStatus,
                    barImage: barImage,
                    pointerImage: pointerArrowImage,
                    font: garamondBold,
                  ),
                  pw.SizedBox(height: 6),
                  _imageScoreBarWithArrow(
                    label: '3. Hazard score',
                    scoreText: _asFixed(acceptedHazard, digits: 3),
                    value: acceptedHazard,
                    status: hazardStatus,
                    barImage: barImage,
                    pointerImage: pointerArrowImage,
                    font: garamondBold,
                  ),

                  pw.SizedBox(height: 18),

                  // === Gauge uses ACCEPTED RISK ===
                  // Centered, larger meter, and final score with 2 decimals
                  pw.Center(
                    child: pw.Stack(
                      alignment: pw.Alignment.center,
                      children: [
                        _gaugeWithPointerDot(
                          value: acceptedRisk,
                          gaugeImage: rainbowGaugeImage,
                          pointerImage: pointerDotImage,
                          width: 640,
                          // increased size
                          height: 340,
                          // increased size
                          centerYOffset: 78,
                          // tweak pointer center for larger height
                          dotSize: 26, // slightly bigger pointer
                        ),
                        pw.Column(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Text(
                              date,
                              style: pw.TextStyle(
                                  fontSize: 14, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              _asFixed(acceptedRisk, digits: 2),
                              // show up to two digits
                              style: pw.TextStyle(
                                fontSize: 36,
                                // a bit larger to match bigger meter
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('#0303ff'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 5),

                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text('Your socio-climatic risk is calculated to be',
                            style: pw.TextStyle(
                                fontSize: 24, font: garamondBold)),
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
                              style: pw.TextStyle(fontSize: 24,
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

                  // Legend centered
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
                          style: pw.TextStyle(fontSize: 24,
                              color: disclaimerColor,
                              font: garamondExtraBold),
                        ),
                        pw.Text(
                          'Above socio-climatic risk score is calculated based on information provided by the farmer.',
                          style: pw.TextStyle(
                              fontSize: 20, color: PdfColors.black,font: garamondMedium),

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

    // ==== Save ====
    Directory downloadsDir;
    if (Platform.isAndroid) {
      downloadsDir = Directory('/storage/emulated/0/Download');
    } else {
      downloadsDir = (await getDownloadsDirectory())!;
    }
    if (!await downloadsDir.exists()) await downloadsDir.create(
        recursive: true);

    final fileName = 'report_${DateTime
        .now()
        .millisecondsSinceEpoch}.pdf';
    final outFile = File('${downloadsDir.path}/$fileName');
    await outFile.writeAsBytes(await pdf.save());

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
  }
}
