import 'dart:io' show Directory, File, Platform;
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final st = context.read<RiskAssessmentBloc>().state;
    if (st is! RiskAssessmentLoaded) return;

    final pdf = pw.Document();

    final bgImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/ic_socio_climatic_dia.webp')).buffer.asUint8List(),
    );
    final barImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/hazard_bar.png')).buffer.asUint8List(),
    );
    final rainbowGaugeImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/rainbow_color.png')).buffer.asUint8List(),
    );
    final pointerArrowImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/score_arrow.png')).buffer.asUint8List(),
    );

    String asFixed(dynamic val) {
      if (val == null) return '0.00';
      if (val is num) return val.toStringAsFixed(2);
      if (val is String) {
        return double.tryParse(val)?.toStringAsFixed(2) ?? '0.00';
      }
      return '0.00';
    }

    String hazardLevelFromValue(double v) {
      if (v < 0.254952719) return 'Very Low';
      if (v < 0.359426855) return 'Low';
      if (v < 0.419781228) return 'Medium';
      if (v < 0.512033541) return 'High';
      return 'Very High';
    }

    String exposureLevelFromValue(double v) {
      if (v < 0.3629) return 'Very Low';
      if (v < 0.4252) return 'Low';
      if (v < 0.4670) return 'Medium';
      if (v < 0.5131) return 'High';
      return 'Very High';
    }

    PdfColor riskColor(String level) {
      switch (level.toLowerCase()) {
        case 'very low':
          return PdfColors.green;
        case 'low':
          return PdfColors.lightGreen;
        case 'medium':
          return PdfColors.yellow;
        case 'high':
          return PdfColors.orange;
        case 'very high':
          return PdfColors.red;
        default:
          return PdfColors.grey;
      }
    }

    /// --- Gauge with perfectly aligned pointer arrow ---
    pw.Widget gaugeWithPointerArrow({
      required double value, // from 0.0 to 1.0
      required pw.MemoryImage gaugeImage,
      required pw.MemoryImage pointerImage,
      double width = 500,
      double height = 250,
      double arcRadius = 205, // radius of the rainbow arc (tune as per your PNG)
      double centerYOffset = 75, // vertical offset from bottom (tune as per your PNG)
      double arrowWidth = 30, // pointer PNG width
      double arrowHeight = 110, // pointer PNG height (tip to base)
    }) {
      // Center of the arc
      final centerX = width / 2;
      final centerY = height - centerYOffset;

      // Angle from left (π) to right (0)
      final angle = pi * (1 - value.clamp(0.0, 1.0));

      // The base of the arrow is at (centerX, centerY)
      // The pointer is rotated to match the arc angle
      return pw.Container(
        width: width,
        height: height,
        alignment: pw.Alignment.center,
        child: pw.Stack(
          alignment: pw.Alignment.center,
          children: [
            pw.Image(gaugeImage, width: width, height: height, fit: pw.BoxFit.contain),
            // Pointer arrow (base at center, rotated to point at value)
            pw.Positioned(
              left: centerX - arrowWidth / 2,
              top: centerY - arrowHeight,
              child: pw.Transform.rotate(
                angle: -angle,
                //origin: pw.Offset(arrowWidth / 2, arrowHeight),
                child: pw.Image(pointerImage, width: arrowWidth, height: arrowHeight),
              ),
            ),
          ],
        ),
      );
    }

    // --- Main calculation logic ---
    final formattedAnswers = answers.map((k, v) => MapEntry(k, v.toString()));
    final vulnDetails = computeVulnerabilityDetails(formattedAnswers);
    final vulnVal = vulnDetails['score'] as double;

    // Log vulnerability values used in score calculation with question numbers
    final vulnValues = Map<String, double>.from(
        vulnDetails['values'] as Map<String, dynamic>);
    final vulnSum = vulnDetails['sum'] as double;
    final vulnWeight = vulnDetails['weight'] as double;
    int _idx = 1;
    print('Vulnerability calculation details:');
    vulnValues.forEach((label, value) {
      // Print raw accepted value without rounding so users can see the
      // precise contribution from each question.
      print('$_idx. $label: $value');
      _idx++;
    });

    // Vulnerability sum and weight
    print('Vulnerability sum: $vulnSum, weight: $vulnWeight');

    final expDetails = computeExposureDetails(formattedAnswers);
    final expVal = expDetails['score'] as double;

    double hazardVal = LocationService().hazardFor(district ?? '');
    String hazardScore = hazardVal.toStringAsFixed(2);
    String vulnerabilityScore = vulnVal.toStringAsFixed(2);
    String exposureScore = expVal.toStringAsFixed(2);
    String riskScore = asFixed(st.answers['riskScore']);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          final hazardLevel = hazardLevelFromValue(hazardVal);
          final hazardValueForBar = hazardVal.clamp(0.0, 1.0);
          final exposureLevel = exposureLevelFromValue(expVal);
          final exposureValueForBar = expVal.clamp(0.0, 1.0);

          return pw.Stack(
            children: [
              pw.Positioned.fill(
                child: pw.Opacity(
                  opacity: 0.10,
                  child: pw.Image(bgImage, fit: pw.BoxFit.contain),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: pw.Column(
                  children: [
                    pw.Container(
                      width: double.infinity,
                      height: 90,
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#009688'),
                        borderRadius: const pw.BorderRadius.only(
                          bottomLeft: pw.Radius.circular(100),
                          bottomRight: pw.Radius.circular(100),
                        ),
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(
                            'Socio-climatic Risk of',
                            style: pw.TextStyle(
                              fontSize: 32,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                          pw.Text(
                            'Smallholder Dairy Farmer',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.yellow,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 20),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(children: [
                            pw.Text(
                              'Name of the dairy farmer: ',
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.normal,
                              ),
                            ),
                            pw.Text(
                              name,
                              style: const pw.TextStyle(
                                fontSize: 18,
                                color: PdfColors.blueAccent,
                              ),
                            ),
                          ]),
                          pw.SizedBox(height: 10),
                          pw.Row(children: [
                            pw.Text(
                              'State: ',
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.brown400,
                              ),
                            ),
                            pw.Text(
                              stateName ?? '',
                              style: const pw.TextStyle(
                                fontSize: 18,
                                color: PdfColors.blueAccent,
                              ),
                            ),
                            pw.Spacer(),
                            pw.Text(
                              'Block: ',
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.brown400,
                              ),
                            ),
                            pw.Text(
                              block,
                              style: const pw.TextStyle(
                                fontSize: 18,
                                color: PdfColors.blueAccent,
                              ),
                            ),
                          ]),
                          pw.SizedBox(height: 5),
                          pw.Row(children: [
                            pw.Text(
                              'District: ',
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.brown400,
                              ),
                            ),
                            pw.Text(
                              district ?? '',
                              style: const pw.TextStyle(
                                fontSize: 18,
                                color: PdfColors.blueAccent,
                              ),
                            ),
                            pw.Spacer(),
                            pw.Text(
                              'Village: ',
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.brown400,
                              ),
                            ),
                            pw.Text(
                              village,
                              style: const pw.TextStyle(
                                fontSize: 18,
                                color: PdfColors.blueAccent,
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    ReportGenerator.imageScoreBarWithArrow(
                      label: '1. Vulnerability score',
                      score: vulnerabilityScore,
                      value: double.tryParse(vulnerabilityScore) ?? 0.0,
                      barImage: barImage,
                      pointerImage: pointerArrowImage,
                      level: hazardLevelFromValue(
                          double.tryParse(vulnerabilityScore) ?? 0.0),
                      levelColor: riskColor(hazardLevelFromValue(
                          double.tryParse(vulnerabilityScore) ?? 0.0)),
                    ),
                    pw.SizedBox(height: 10),
                    ReportGenerator.imageScoreBarWithArrow(
                      label: '2. Exposure score',
                      score: exposureScore,
                      value: exposureValueForBar,
                      barImage: barImage,
                      pointerImage: pointerArrowImage,
                      level: exposureLevel,
                      levelColor: riskColor(exposureLevel),
                    ),
                    pw.SizedBox(height: 10),
                    ReportGenerator.imageScoreBarWithArrow(
                      label: '3. Hazard score',
                      score: hazardScore,
                      value: hazardValueForBar,
                      barImage: barImage,
                      pointerImage: pointerArrowImage,
                      level: hazardLevel,
                      levelColor: riskColor(hazardLevel),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Center(
                      child: gaugeWithPointerArrow(
                        value: double.tryParse(riskScore) ?? 0.0,
                        gaugeImage: rainbowGaugeImage,
                        pointerImage: pointerArrowImage,
                        width: 500,
                        height: 250,
                        arcRadius: 205,      // <---- Tune for your PNG for perfect fit
                        centerYOffset: 75,   // <---- Tune for your PNG for perfect fit
                        arrowWidth: 30,
                        arrowHeight: 110,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.RichText(
                      text: const pw.TextSpan(
                        style: pw.TextStyle(fontSize: 16),
                        children: [
                          pw.TextSpan(
                            text: 'Disclaimer: ',
                            style: pw.TextStyle(
                              color: PdfColors.blue,
                            ),
                          ),
                          pw.TextSpan(
                            text: 'Above socio-climatic risk score is calculated based on information provided by the farmer.',
                            style: pw.TextStyle(
                              color: PdfColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    Directory downloadsDir;
    if (Platform.isAndroid) {
      downloadsDir = Directory('/storage/emulated/0/Download');
    } else {
      downloadsDir = (await getDownloadsDirectory())!;
    }
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final outFile = File('${downloadsDir.path}/$fileName');
    await outFile.writeAsBytes(await pdf.save());

    const androidDetails = AndroidNotificationDetails(
      'reports',
      'Reports',
      channelDescription: 'Your report is ready to open',
      importance: Importance.high,
      priority: Priority.high,
    );
    await notifications.show(
      0,
      'Report saved',
      'Tap to open your PDF',
      const NotificationDetails(android: androidDetails),
      payload: outFile.path,
    );
  }

  static pw.Widget imageScoreBarWithArrow({
    required String label,
    required String score,
    required double value,
    required pw.MemoryImage barImage,
    required pw.MemoryImage pointerImage,
    double barWidth = 180,
    double barHeight = 33,
    String? level,
    PdfColor? levelColor,
  }) {
    value = value.clamp(0.0, 1.0);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.SizedBox(
            width: 190,
            child: pw.Text(
              label,
              style:
              pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
            ),
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
                  child:
                  pw.Image(barImage, width: barWidth, height: barHeight),
                ),
                pw.Positioned(
                  left: (barWidth - 22) * value,
                  top: 0,
                  child: pw.Image(pointerImage, width: 22, height: 22),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Container(
            width: 40,
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(
              score,
              style:
              pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Container(
            width: 50,
            child: pw.Text(
              level ?? '',
              style: pw.TextStyle(
                fontSize: 15,
                color: levelColor ?? PdfColors.black,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pointerCircle(double size) {
    return pw.Container(
      width: size,
      height: size,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        shape: pw.BoxShape.circle,
        border: pw.Border.all(color: PdfColors.blue, width: 2),
      ),
    );
  }
}
