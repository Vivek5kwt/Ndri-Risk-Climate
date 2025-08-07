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

    String vulnerabilityLevelFromValue(double v) {
      if (v < 0.6228) return 'Very Low';
      if (v < 0.7023) return 'Low';
      if (v < 0.7486) return 'Medium';
      if (v < 0.7813) return 'High';
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

    pw.Widget gaugeWithPointerArrow({
      required double value,
      required pw.MemoryImage gaugeImage,
      required pw.MemoryImage pointerImage,
      double width = 500,
      double height = 250,
      double centerYOffset = 75,
      double arrowWidth = 30,
      double arrowHeight = 110,
    }) {
      final centerX = width / 2;
      final centerY = height - centerYOffset;
      final angle = pi * (1 - value.clamp(0.0, 1.0));
      return pw.Container(
        width: width,
        height: height,
        alignment: pw.Alignment.center,
        child: pw.Stack(
          children: [
            pw.Image(gaugeImage, width: width, height: height, fit: pw.BoxFit.contain),
            pw.Positioned(
              left: centerX - arrowWidth / 2,
              top: centerY - arrowHeight,
              child: pw.Transform.rotate(
                angle: -angle,
                child: pw.Image(pointerImage, width: arrowWidth, height: arrowHeight),
              ),
            ),
          ],
        ),
      );
    }

    final formattedAnswers = answers.map((k, v) => MapEntry(k, v.toString()));
    final vulnDetails = computeVulnerabilityDetails(formattedAnswers);
    final expDetails = computeExposureDetails(formattedAnswers);
    final double vulnVal = vulnDetails['score'] as double;
    final double expVal = expDetails['score'] as double;
    final double hazardVal = LocationService().hazardFor(district ?? '');

    final String hazardScore = hazardVal.toStringAsFixed(2);
    final String vulnerabilityScore = vulnVal.toStringAsFixed(2);
    final String exposureScore = expVal.toStringAsFixed(2);
    final String riskScore = asFixed(st.answers['riskScore']);

    final double finalRisk = vulnVal * expVal * hazardVal;
    final String finalRiskScore = finalRisk.toStringAsFixed(4);
    final String riskLevel = 'High';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context ctx) {
          final date = DateFormat('MMM d, yyyy').format(DateTime.now());
          return pw.Stack(
            children: [
              pw.Positioned.fill(
                child: pw.Opacity(
                  opacity: 0.1,
                  child: pw.Image(bgImage, fit: pw.BoxFit.contain),
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: double.infinity,
                      height: 90,
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#009688'),
                        borderRadius: pw.BorderRadius.only(
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
                      padding: pw.EdgeInsets.symmetric(horizontal: 20),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(children: [
                            pw.Text('Name: ', style: pw.TextStyle(fontSize: 20)),
                            pw.Text(name, style: pw.TextStyle(fontSize: 18, color: PdfColors.blueAccent)),
                          ]),
                          pw.SizedBox(height: 8),
                          pw.Row(children: [
                            pw.Text('State: ', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.brown400)),
                            pw.Text(stateName ?? '', style: pw.TextStyle(fontSize: 18, color: PdfColors.blueAccent)),
                            pw.Spacer(),
                            pw.Text('Block: ', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.brown400)),
                            pw.Text(block, style: pw.TextStyle(fontSize: 18, color: PdfColors.blueAccent)),
                          ]),
                          pw.SizedBox(height: 5),
                          pw.Row(children: [
                            pw.Text('District: ', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.brown400)),
                            pw.Text(district ?? '', style: pw.TextStyle(fontSize: 18, color: PdfColors.blueAccent)),
                            pw.Spacer(),
                            pw.Text('Village: ', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.brown400)),
                            pw.Text(village, style: pw.TextStyle(fontSize: 18, color: PdfColors.blueAccent)),
                          ]),
                        ],
                      ),
                    ),

                    pw.SizedBox(height: 12),

                    imageScoreBarWithArrow(
                      label: '1. Vulnerability',
                      score: vulnerabilityScore,
                      value: vulnVal,
                      barImage: barImage,
                      pointerImage: pointerArrowImage,
                      level: vulnerabilityLevelFromValue(vulnVal),
                      levelColor: riskColor(vulnerabilityLevelFromValue(vulnVal)),
                    ),
                    pw.SizedBox(height: 6),
                    imageScoreBarWithArrow(
                      label: '2. Exposure',
                      score: exposureScore,
                      value: expVal,
                      barImage: barImage,
                      pointerImage: pointerArrowImage,
                      level: exposureLevelFromValue(expVal),
                      levelColor: riskColor(exposureLevelFromValue(expVal)),
                    ),
                    pw.SizedBox(height: 6),
                    imageScoreBarWithArrow(
                      label: '3. Hazard',
                      score: hazardScore,
                      value: hazardVal.clamp(0.0, 1.0),
                      barImage: barImage,
                      pointerImage: pointerArrowImage,
                      level: hazardLevelFromValue(hazardVal),
                      levelColor: riskColor(hazardLevelFromValue(hazardVal)),
                    ),

                    pw.SizedBox(height: 20),

                    pw.Stack(
                      alignment: pw.Alignment.center,
                      children: [
                        gaugeWithPointerArrow(
                          value: double.tryParse(riskScore) ?? 0,
                          gaugeImage: rainbowGaugeImage,
                          pointerImage: pointerDotImage,
                        ),
                        pw.Column(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Text(date, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 6),
                            pw.Text(finalRiskScore, style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
                          ],
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 20),
                    pw.Center(
                      child: pw.Column(
                        children: [
                          pw.Text('Your socio-climatic risk is calculated to be', style: pw.TextStyle(fontSize: 16)),
                          pw.SizedBox(height: 4),
                          pw.Text(riskLevel, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
                          pw.RichText(
                            text: const pw.TextSpan(
                              style: pw.TextStyle(fontSize: 12, color: PdfColors.black),
                              children: [
                                pw.TextSpan(text: '('),
                                pw.TextSpan(text: 'very low', style: pw.TextStyle(color: PdfColors.green)),
                                pw.TextSpan(text: ' / '),
                                pw.TextSpan(text: 'low', style: pw.TextStyle(color: PdfColors.lightGreen)),
                                pw.TextSpan(text: ' / '),
                                pw.TextSpan(text: 'moderate', style: pw.TextStyle(color: PdfColors.yellow)),
                                pw.TextSpan(text: ' / '),
                                pw.TextSpan(text: 'high', style: pw.TextStyle(color: PdfColors.orange)),
                                pw.TextSpan(text: ' / '),
                                pw.TextSpan(text: 'very high', style: pw.TextStyle(color: PdfColors.red)),
                                pw.TextSpan(text: ')'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (riskLevel == 'High' || riskLevel == 'Very High') pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 12),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Remarks:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                          pw.Text(
                            'You are advised to contact your nearest KVK/ State Animal Husbandry personnel for customised adaptation plan of your dairy farm to minimise risk towards climate change.',
                            style: pw.TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    pw.SizedBox(height: 20),

                    pw.Wrap(
                      spacing: 24,
                      runSpacing: 8,
                      alignment: pw.WrapAlignment.center,
                      children: [
                        legendRow(PdfColors.green, 'Very Low'),
                        legendRow(PdfColors.lightGreen, 'Low'),
                        legendRow(PdfColors.yellow, 'Medium'),
                        legendRow(PdfColors.orange, 'High'),
                        legendRow(PdfColors.red, 'Very High'),
                      ],
                    ),

                    pw.SizedBox(height: 24),

                    pw.Text(
                      'Disclaimer: Above risk score is based on farmer responses.',
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
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
    if (!await downloadsDir.exists()) await downloadsDir.create(recursive: true);

    final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final outFile = File('${downloadsDir.path}/$fileName');
    await outFile.writeAsBytes(await pdf.save());

    const androidDetails = AndroidNotificationDetails(
      'reports', 'Reports',
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

  static pw.Widget legendRow(PdfColor color, String label) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(
            width: 18,
            height: 18,
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: pw.BorderRadius.circular(3),
              border: pw.Border.all(color: PdfColors.black, width: 1.2),
            ),
          ),
          pw.SizedBox(width: 7),
          pw.Text(label, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
  static pw.Widget imageScoreBarWithArrow({
    required String label,
    required String score,
    required double value,
    required pw.MemoryImage barImage,
    required pw.MemoryImage pointerImage,
    String? level,
    PdfColor? levelColor,
    double barWidth = 180,
    double barHeight = 33,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.SizedBox(
            width: 190,
            child: pw.Text(label, style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold)),
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
                  child: pw.Image(barImage, width: barWidth, height: barHeight),
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
            child: pw.Text(score, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(width: 6),
          pw.Container(
            width: 50,
            child: pw.Text(
              level ?? '',
              style: pw.TextStyle(fontSize: 15, color: levelColor ?? PdfColors.black, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
