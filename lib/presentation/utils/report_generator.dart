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
      double arcRadius = 205,
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
          alignment: pw.Alignment.center,
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
    final vulnVal = vulnDetails['score'] as double;
    final vulnValues = Map<String, double>.from(
        vulnDetails['values'] as Map<String, dynamic>);
    final vulnSum = vulnDetails['sum'] as double;
    final vulnWeight = vulnDetails['weight'] as double;
    int _idx = 1;
    print('Vulnerability calculation details:');
    vulnValues.forEach((label, value) {
      print('$_idx. $label: $value');
      _idx++;
    });
    const selectedLabels = [
      'Q5',
      'Q3',
      'Q11',
      'Q16',
      'Q17',
      'Q35',
      'Q37',
      'Q38',
      'Q45',
      'Q46',
      'Q47',
    ];
    print('Accepted values for selected questions:');
    for (final label in selectedLabels) {
      final value = vulnValues[label];
      if (value != null) {
        print('$label: $value');
      }
    }
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
                      level: vulnerabilityLevelFromValue(
                          double.tryParse(vulnerabilityScore) ?? 0.0),
                      levelColor: riskColor(vulnerabilityLevelFromValue(
                          double.tryParse(vulnerabilityScore) ?? 0.0)),
                    ),
                    pw.SizedBox(height: 4),
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
              /// LEGEND AT BOTTOM RIGHT
              pw.Positioned(
                right: 25,
                bottom: 25,
                child: pw.Container(
                  padding: pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.deepOrange, width: 2),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      legendRow(PdfColors.green, "Very low"),
                      legendRow(PdfColors.lightGreen, "Low"),
                      legendRow(PdfColors.yellow, "Moderate"),
                      legendRow(PdfColors.orange, "High"),
                      legendRow(PdfColors.red, "Very high"),
                    ],
                  ),
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

  /// Helper to create a legend row (color box + label)
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
          pw.Text(label, style: pw.TextStyle(fontSize: 15)),
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

  static pw.Widget vulnerabilityCategoriesTable() {
    const headers = ['Category', 'Score range'];
    const data = [
      ['Very Low', '0.3967 - 0.6227'],
      ['Low', '0.6228 - 0.7022'],
      ['Medium', '0.7023 - 0.7485'],
      ['High', '0.7486 - 0.7812'],
      ['Very High', '0.7813 - 0.8565'],
    ];
    return pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      border: pw.TableBorder.all(color: PdfColors.grey, width: 0.5),
      children: [
        pw.TableRow(
          children: headers
              .map((h) => pw.Padding(
            padding: const pw.EdgeInsets.all(2),
            child: pw.Text(
              h,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ))
              .toList(),
        ),
        ...data.map(
              (row) => pw.TableRow(
            children: row
                .map((cell) => pw.Padding(
              padding: const pw.EdgeInsets.all(2),
              child: pw.Text(
                cell,
                style: const pw.TextStyle(fontSize: 10),
              ),
            ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
