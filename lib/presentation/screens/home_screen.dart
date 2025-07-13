import 'dart:convert';
import 'dart:io' show Directory, File, Platform;
import 'dart:math';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:ndri_dairy_risk/presentation/screens/preview_answers_screen.dart';
import 'package:ndri_dairy_risk/presentation/widgets/app_text.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_colors.dart';
import '../../config/app_strings.dart';
import '../../config/assets.dart';
import '../../data/models/question_model.dart';
import '../../data/services/location_service.dart';
import '../../data/services/location_state.dart';
import '../../logic/risk_assessment/bloc/risk_assessment_bloc.dart';
import '../../logic/risk_assessment/bloc/risk_assessment_event.dart';
import '../../logic/risk_assessment/bloc/risk_assessment_state.dart';
import '../../logic/score_calculate/question_weight.dart';

@pragma('vm:entry-point')
void notificationTapBackground(
    NotificationResponse notificationResponse) async {
  final payload = notificationResponse.payload;
  if (payload != null) {
    await OpenFile.open(payload);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int step = 0;
  final nameCtrl = TextEditingController();
  final blockCtrl = TextEditingController();
  final villageCtrl = TextEditingController();
  String? _selectedGender;
  late final LocationCubit loc;
  bool _loadingDists = false;
  String? selectedState, selectedDistrict;
  late FlutterLocalNotificationsPlugin _localNotifications;
  bool _loadingBasicInfo = true;

  Map<String, dynamic> _localAnswers = {};
  bool _initializingFields = false;

  final humanVars = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
  final agVars = [
    '11',
    '12',
    '13',
    '14',
    '13.1',
    '13.2',
    '13.3',
    '15',
    '16',
    '17',
    '18',
    '18.1',
    '18.2',
    '18.3',
    '18.4',
    '18.5',
    '18.6',
    '18.7',
    '18.8',
    '18.9',
    '18.10',
    '18.11',
    '18.12',
    '18.13',
    '18.14',
    '18.15',
    '18.16',
    '18.17',
    '18.18',
    '19',
    '19.1',
    '19.6',
    '19.11',
    '20',
    '21',
    '22',
    '23',
    '24',
    '25',
    '26',
    '27',
    '28'
  ];
  final livVars = [
    '30',
    '31',
    '32',
    '33',
  ];
  final socialVars = ['34', '35', '36', '37', '38'];
  final infraVars = ['39', '40', '41', '42', '43', '44'];
  final percepVars = [
    '44.1',
    '44.2',
    '44.3',
    '44.4',
    '44.5',
    '44.6',
    '44.7',
    '44.8',
    '44.9',
    '44.10',
    '44.11',
    '44.12',
    '44.13',
    '44.14',
    '44.15',
    '44.16',
  ];
  final awareVars = ['45.1', '45.2', '45.3', '45.4', '45.5', '45.6', '45.7'];
  final prepVars = [
    '46.1',
    '46.2',
    '46.3',
    '46.4',
    '46.5',
    '46.6',
    '46.7',
    '46.8',
    '46.9',
    '46.10',
    '46.11',
    '46.12',
    '46.13',
    '46.14',
    '46.15',
    '46.16',
  ];

  final _agPageCtrl = PageController();
  int agPageIdx = 0;
  final _climateCtrl = PageController();
  int climatePageIdx = 0;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    for (final c in [nameCtrl, blockCtrl, villageCtrl]) {
      c.addListener(() {
        if (_initializingFields) return;
        _saveFieldAnswers();
        setState(() {});
      });
    }

    context.read<RiskAssessmentBloc>().add(LoadQuestionsEvent());
    loc = context.read<LocationCubit>();

    _loadLocalAnswers();
  }

  Future<void> _initPermissions() async {
    if (!Platform.isAndroid) return;

/*    await Permission.storage.request();
    if (await Permission.manageExternalStorage.isDenied) {

      await Permission.manageExternalStorage.request();
    }*/
  }

  Future<void> _initNotifications() async {
    final flutterLocal = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await flutterLocal.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      onDidReceiveNotificationResponse: (resp) async {
        if (resp.payload != null) await OpenFile.open(resp.payload!);
      },
    );
    if (Platform.isAndroid) {
      final androidImpl = flutterLocal.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
    }
    _localNotifications = flutterLocal;
  }

  Future<void> _showSubmitResultDialog(BuildContext context) async
  {
    final shouldSubmit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.help_outline_rounded,
                      size: 60, color: Colors.amber),
                  const SizedBox(height: 16),
                  const Text(
                    'Are you sure to submit?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Once submitted, you cannot make changes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text("Edit"),
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle),
                        label: const Text("Yes"),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
    );
    if (shouldSubmit != true) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28)),
            backgroundColor: Colors.white,
            elevation: 14,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 34),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        scale: 1,
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.elasticOut,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Colors.green, Colors.blue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.verified_rounded,
                              color: Colors.white, size: 58),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Thank you for your submission!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "Your answers have been securely submitted.\n\n",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade900,
                                fontSize: 15.2,
                              ),
                            ),
                            TextSpan(
                              text: "Please note:\n",
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const TextSpan(
                              text:
                              "• Your responses are final and cannot be edited.\n"
                                  "• Your socio-climatic risk result has been calculated based on your answers.",
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 15,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          if (context.mounted) {
                            (context as Element).markNeedsBuild();
                          }
                          setState(() => step = 99);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          padding:
                          const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          "Continue",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      splashColor: Colors.red.withOpacity(0.15),
                      onTap: () {
                        Navigator.of(ctx).pop();
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child:
                        Icon(Icons.close_rounded, color: Colors.red, size: 28),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _generateReport() async {
    await _initPermissions();
    final st = context
        .read<RiskAssessmentBloc>()
        .state;
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
    final pointerArrowImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/score_arrow.png'))
          .buffer
          .asUint8List(),
    );
    final gaugeImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/socio_gauge.png'))
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

    pw.Widget imageScoreBarWithArrow({
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

    double getRandomScore({double min = 0.30, double max = 0.75}) {
      final random = Random();
      return min + (random.nextDouble() * (max - min));
    }

    String name = nameCtrl.text.trim();
    String stateName = selectedState ?? '';
    String district = selectedDistrict ?? '';
    String block = blockCtrl.text.trim();
    String village = villageCtrl.text.trim();

    //String vulnerabilityScore = _asFixed(st.answers['vulnerability']);
    //String exposureScore = _asFixed(st.answers['exposure']);
    String vulnerabilityScore = asFixed(getRandomScore());
    String exposureScore = asFixed(getRandomScore());
    String getTotalScore = asFixed(vulnerabilityScore).toString() +
        asFixed(exposureScore);
    String getHazardScore = asFixed(hazardLevelFromValue(200.10));
    print('getted the value $getTotalScore');

    double hazardVal = LocationService().hazardFor(district);
    String hazardScore = hazardVal.toStringAsFixed(2);
    String riskScore = asFixed(st.answers['riskScore']);
    String riskLevel = st.answers['riskLevel'] ?? 'Moderate';
    print('getted the hrisk scrore $riskLevel');
    pw.Widget buildLegendRow(PdfColor color, String label) {
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Container(
            width: 14,
            height: 14,
            decoration: pw.BoxDecoration(
              color: color,
              border: pw.Border.all(color: PdfColors.black, width: 0.5),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.black,
            ),
          ),
        ],
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          final hazardLevel = hazardLevelFromValue(hazardVal);
          final hazardValueForBar = hazardVal.clamp(0.0, 1.0);

          return pw.Stack(
            children: [
              pw.Positioned.fill(
                child: pw.Opacity(
                  opacity: 0.10,
                  child: pw.Image(bgImage, fit: pw.BoxFit.contain),
                ),
              ),
              pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 20, vertical: 5),
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
                            pw.Text('Socio-climatic Risk of',
                                style: pw.TextStyle(
                                    fontSize: 32,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.white)),
                            pw.Text('Smallholder Dairy Farmer',
                                style: pw.TextStyle(
                                    fontSize: 24,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.yellow)),
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
                              pw.Text('Name of the dairy farmer: ',
                                  style: pw.TextStyle(
                                      fontSize: 20,
                                      fontWeight: pw.FontWeight.normal)),
                              pw.Text(name,
                                  style: const pw.TextStyle(
                                      fontSize: 18,
                                      color: PdfColors.blueAccent))
                            ]),
                            pw.SizedBox(height: 10),
                            pw.Row(children: [
                              pw.Text('State: ',
                                  style: pw.TextStyle(
                                      fontSize: 20,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.brown400)),
                              pw.Text(stateName,
                                  style: const pw.TextStyle(
                                      fontSize: 18,
                                      color: PdfColors.blueAccent)),
                              pw.Spacer(),
                              pw.Text('Block: ',
                                  style: pw.TextStyle(
                                      fontSize: 20,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.brown400)),
                              pw.Text(block,
                                  style: const pw.TextStyle(
                                      fontSize: 18,
                                      color: PdfColors.blueAccent)),
                            ]),
                            pw.SizedBox(height: 5),
                            pw.Row(children: [
                              pw.Text('District: ',
                                  style: pw.TextStyle(
                                      fontSize: 20,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.brown400)),
                              pw.Text(district,
                                  style: const pw.TextStyle(
                                      fontSize: 18,
                                      color: PdfColors.blueAccent)),
                              pw.Spacer(),
                              pw.Text('Village: ',
                                  style: pw.TextStyle(
                                      fontSize: 20,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.brown400)),
                              pw.Text(village,
                                  style: const pw.TextStyle(
                                      fontSize: 18,
                                      color: PdfColors.blueAccent)),
                            ]),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      imageScoreBarWithArrow(
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
                      imageScoreBarWithArrow(
                        label: '2. Exposure score',
                        score: exposureScore,
                        value: double.tryParse(exposureScore) ?? 0.0,
                        barImage: barImage,
                        pointerImage: pointerArrowImage,
                        level: hazardLevelFromValue(
                            double.tryParse(exposureScore) ?? 0.0),
                        levelColor: riskColor(hazardLevelFromValue(
                            double.tryParse(exposureScore) ?? 0.0)),
                      ),
                      pw.SizedBox(height: 10),
                      imageScoreBarWithArrow(
                        label: '3. Hazard score',
                        score: hazardScore,
                        value: hazardValueForBar,
                        barImage: barImage,
                        pointerImage: pointerArrowImage,
                        level: hazardLevel,
                        levelColor: riskColor(hazardLevel),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Container(
                        height: 110,
                        width: 300,
                        margin: const pw.EdgeInsets.only(left: 20),
                        child: pw.Stack(
                          children: [
                            pw.Image(gaugeImage, width: 300, height: 110),
                            /*    pw.Positioned(
                          left: 100 + (riskScoreVal.clamp(0, 1) * 285),
                          top: 28,
                          child: pw.Container(
                            width: 21,
                            height: 21,
                            decoration: pw.BoxDecoration(
                              color: PdfColors.red,
                              shape: pw.BoxShape.circle,
                              border: pw.Border.all(color: PdfColors.white, width: 2),
                            ),
                          ),
                        ),*/
                            pw.Positioned(
                              left: 55,
                              top: 60,
                              child: pw.Text(
                                riskScore,
                                style: pw.TextStyle(
                                  fontSize: 33,
                                  color: PdfColors.blue,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Your socio-climatic risk is calculated to be',
                        style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        riskLevel,
                        style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: riskColor(riskLevel)),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(children: [
                        pw.Text('Remarks:',
                            style: pw.TextStyle(
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.brown)),
                      ]),
                      pw.SizedBox(height: 8),
                      if (riskLevel.toString() == 'High' ||
                          riskLevel.toString() == 'Very High')
                        pw.Text(
                          '$riskLevel You are advised to contact your nearest KVK/ State Animal Husbandry personnel for customised adaptation plan of your dairy farm to minimise risk towards climate change.',
                          style: pw.TextStyle(
                              fontSize: 18, fontWeight: pw.FontWeight.bold),
                        ),
                      pw.SizedBox(height: 25),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        width: 120,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                              color: PdfColors.black, width: 1),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            buildLegendRow(PdfColors.blue900, 'Very low'),
                            pw.SizedBox(height: 4),
                            buildLegendRow(PdfColors.green, 'Low'),
                            pw.SizedBox(height: 4),
                            buildLegendRow(PdfColors.yellow, 'Moderate'),
                            pw.SizedBox(height: 4),
                            buildLegendRow(PdfColors.orange, 'High'),
                            pw.SizedBox(height: 4),
                            buildLegendRow(PdfColors.red, 'Very high'),
                          ],
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
                              text:
                              'Above socio-climatic risk score is calculated based on information provided by the farmer.',
                              style: pw.TextStyle(
                                color: PdfColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )),
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

    final fileName = 'report_${DateTime
        .now()
        .millisecondsSinceEpoch}.pdf';
    final outFile = File('${downloadsDir.path}/$fileName');
    await outFile.writeAsBytes(await pdf.save());

    const androidDetails = AndroidNotificationDetails(
      'reports',
      'Reports',
      channelDescription: 'Your report is ready to open',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _localNotifications.show(
      0,
      'Report saved',
      'Tap to open your PDF',
      const NotificationDetails(android: androidDetails),
      payload: outFile.path,
    );
  }

  Future<pw.MemoryImage> _loadArrowImage() async {
    final bytes = await rootBundle.load('assets/images/score_arrow.png');
    return pw.MemoryImage(bytes.buffer.asUint8List());
  }

  Future<pw.Widget> scoreBarWithLevel({
    required String label,
    required String score,
    double barHeight = 16,
    double barWidth = 210,
  }) async {
    double value = double.tryParse(score) ?? 0.0;
    value = value.clamp(0.0, 1.0);
    String level = _riskLevelFromValue(value);

    final pointerImage = await _loadArrowImage();
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SizedBox(
            width: 180,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Container(
            width: barWidth,
            height: barHeight + 18,
            child: pw.Stack(
              children: [
                pw.Positioned(
                  left: 0,
                  top: 18,
                  child: pw.Container(
                    width: barWidth,
                    height: barHeight,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.blue900, width: 1),
                      borderRadius: pw.BorderRadius.circular(barHeight / 2),
                      gradient: const pw.LinearGradient(
                        colors: [
                          PdfColors.green,
                          PdfColors.yellow,
                          PdfColors.red
                        ],
                      ),
                    ),
                  ),
                ),
                pw.Positioned(
                  left: (barWidth - 22) * value,
                  top: 0,
                  child: pw.Image(pointerImage, width: 22, height: 18),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Container(
            width: 44,
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(
              score,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(width: 5),
          pw.Container(
            width: 54,
            child: pw.Text(
              level,
              style: pw.TextStyle(
                fontSize: 16,
                color: _riskColor(level),
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _riskLevelFromValue(double v) {
    if (v < 0.2) return 'Very Low';
    if (v < 0.4) return 'Low';
    if (v < 0.6) return 'Moderate';
    if (v < 0.8) return 'High';
    return 'Very High';
  }

  PdfColor _riskColor(String level) {
    switch (level.toLowerCase()) {
      case 'very low':
        return PdfColors.green;
      case 'low':
        return PdfColors.lightGreen;
      case 'moderate':
        return PdfColors.orange;
      case 'high':
        return PdfColors.red;
      case 'very high':
        return PdfColors.red900;
      default:
        return PdfColors.grey;
    }
  }

  String riskLevelFromScore(String score) {
    double val = double.tryParse(score) ?? 0.0;
    if (val >= 0.8) return 'Very High';
    if (val >= 0.6) return 'High';
    if (val >= 0.4) return 'Moderate';
    if (val >= 0.2) return 'Low';
    return 'Very Low';
  }

  Future<void> _loadLocalAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('risk_answers');
    if (jsonString != null) {
      final data = json.decode(jsonString);
      final storedState = data['stateName'];
      final storedDistrict = data['district'];
      while (loc.states.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 40));
      }
      if (storedState != null) {
        await loc.districts(storedState);
      }

      _initializingFields = true;
      setState(() {
        _localAnswers = data;
        nameCtrl.text = data['name'] ?? '';
        blockCtrl.text = data['block'] ?? '';
        villageCtrl.text = data['village'] ?? '';
        selectedState = storedState;
        selectedDistrict = storedDistrict;
        _selectedGender = data['gender'] ?? data['1'];
        _loadingBasicInfo = false;
      });

      _initializingFields = false;
    } else {
      setState(() {
        _loadingBasicInfo = false;
      });
    }
  }

  Future<void> _saveFieldAnswers() async {
    _localAnswers['name'] = nameCtrl.text.trim();
    _localAnswers['block'] = blockCtrl.text.trim();
    _localAnswers['village'] = villageCtrl.text.trim();
    _localAnswers['stateName'] = selectedState;
    _localAnswers['district'] = selectedDistrict;
    _localAnswers['gender'] = _selectedGender;
    _localAnswers['1'] = _selectedGender;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('risk_answers', json.encode(_localAnswers));
  }

  Future<void> _saveAnswer(String variable, dynamic value) async {
    print('SAVING: $variable = $value');
    _localAnswers[variable.toString()] = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('risk_answers', json.encode(_localAnswers));
  }

  String? _getSavedAnswer(String variable) =>
      _localAnswers[variable]?.toString();

  Future<void> _clearAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('risk_answers');
    setState(() => _localAnswers = {});
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    blockCtrl.dispose();
    villageCtrl.dispose();
    _agPageCtrl.dispose();
    _climateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(
          child: Stack(
            children: [
              Image.asset(
                switch (step) {
                  1 => Assets.bgHumanCapital,
                  2 => Assets.bgAgriculture,
                  3 => Assets.bgLivelihood,
                  4 => Assets.bgSocial,
                  5 => Assets.bgInfrastructure,
                  6 => Assets.bgSocioClimatic,
                  _ => Assets.bgBasicInfo,
                },
                fit: BoxFit.cover,
                height: MediaQuery
                    .of(context)
                    .size
                    .height,
              ),
              Container(
                height: MediaQuery
                    .of(context)
                    .size
                    .height,
                color: Colors.white.withOpacity(0.75),
              ),
            ],
          ),
        ),
        Container(color: Colors.black.withOpacity(.25)),
        SafeArea(
          child: BlocBuilder<RiskAssessmentBloc, RiskAssessmentState>(
            builder: (_, st) {
              switch (step) {
                case 0:
                  return _basicInfo();
                case 1:
                  return _humanCapital(st);
                case 2:
                  return _agriDairy(st);
                case 3:
                  return _livelihood(st);
                case 4:
                  return _social(st);
                case 5:
                  return _infrastructure(st);
                case 6:
                  return _socioClimatic(st);
                default:
                  return _thanks();
              }
            },
          ),
        ),
      ]),
    );
  }

  Widget _basicInfo() {
    if (_loadingBasicInfo) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 10.h),
          _bar(AppString.basicInformationOfFarmers, AppColors.blueColor),
          SizedBox(height: 22.h),
          _bar(AppString.nameOfRespondent, AppColors.greenColor),
          _outlined(nameCtrl, AppString.enterFullName),
          SizedBox(height: 18.h),
          _bar(AppString.state, AppColors.yellowColor, textColor: Colors.black),
          DropdownSearch<String>(
            items: loc.states,
            selectedItem: selectedState,
            onChanged: (v) async {
              setState(() {
                selectedState = v;
                selectedDistrict = null;
                _loadingDists = true;
              });
              await loc.districts(v!);
              setState(() => _loadingDists = false);
              _saveFieldAnswers();
            },
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                hintText: "Select State",
                hintStyle: const TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            dropdownBuilder: (context, value) {
              if (value == null || value.isEmpty) {
                return const Text(
                  "Select State",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }
              return Text(
                value,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                ),
              );
            },
            popupProps: PopupProps.bottomSheet(
              showSearchBox: true,
              showSelectedItems: true,
              bottomSheetProps: const BottomSheetProps(enableDrag: true),
              searchDelay: const Duration(seconds: 0),
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: 'Type to search State...',
                  hintStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  prefixIcon:
                  const Icon(Icons.search, color: Color(0xFF58B19F)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              title: const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Select State',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF222f3e),
                    ),
                  ),
                ),
              ),
              constraints: const BoxConstraints(maxHeight: 420),
              itemBuilder: (context, state, isSelected) =>
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF58B19F).withOpacity(0.13)
                          : Colors.white.withOpacity(0.97),
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(
                          color: const Color(0xFF58B19F), width: 2.1)
                          : Border.all(color: Colors.transparent),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: const Color(0xFF58B19F).withOpacity(0.16),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        )
                      ]
                          : [],
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.location_city_rounded,
                          color: Color(0xFF58B19F)),
                      title: Text(
                        state,
                        style: TextStyle(
                          fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                          color:
                          isSelected ? const Color(0xFF58B19F) : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
            ),
          ),
          SizedBox(height: 18.h),
          _bar(AppString.district, AppColors.greenColor),
          if (selectedState == null)
            _disabled('Select district')
          else
            if (_loadingDists)
              const Center(child: CircularProgressIndicator())
            else
              DropdownSearch<String>(
                items: loc.cachedDistricts(selectedState!) ?? [],
                selectedItem: selectedDistrict,
                onChanged: (v) {
                  setState(() {
                    selectedDistrict = v;
                  });
                  _saveFieldAnswers();
                },
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    hintText: "Select District",
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Colors.black),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Colors.black),
                    ),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                dropdownBuilder: (context, value) {
                  if (value == null || value.isEmpty) {
                    return const Text(
                      "Select District",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }
                  return Text(
                    value,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                    ),
                  );
                },
                popupProps: PopupProps.bottomSheet(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      hintText: 'Type to search District...',
                      hintStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      prefixIcon: const Icon(
                          Icons.search, color: Colors.orange),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  title: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Select District',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF222f3e),
                        ),
                      ),
                    ),
                  ),
                  constraints: const BoxConstraints(maxHeight: 420),
                  itemBuilder: (context, district, isSelected) =>
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.orange.withOpacity(0.14)
                              : Colors.white.withOpacity(0.97),
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: Colors.orange, width: 2.1)
                              : Border.all(color: Colors.transparent),
                          boxShadow: isSelected
                              ? [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.12),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            )
                          ]
                              : [],
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.pin_drop_rounded,
                            color:
                            isSelected ? Colors.orange : const Color(
                                0xFFb26221),
                          ),
                          title: Text(
                            district,
                            style: TextStyle(
                              fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? Colors.orange : Colors
                                  .black87,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                ),
              ),
          SizedBox(height: 18.h),
          _bar(AppString.block, AppColors.yellowColor, textColor: Colors.black),
          _outlined(
            blockCtrl,
            AppString.enterBlock,
          ),
          SizedBox(height: 18.h),
          _bar(AppString.village, AppColors.greenColor),
          _outlined(villageCtrl, AppString.enterVillage),
          SizedBox(height: 28.h),
          Center(
            child: GestureDetector(
              onTap: _validBasic()
                  ? () {
                context.read<RiskAssessmentBloc>().add(
                  SaveBasicInfoEvent(
                    name: nameCtrl.text.trim(),
                    gender: '',
                    stateName: selectedState!,
                    district: selectedDistrict!,
                    block: blockCtrl.text.trim(),
                    village: villageCtrl.text.trim(),
                  ),
                );
                _saveFieldAnswers();
                setState(() => step = 1);
              }
                  : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: Colors.amber, size: 24),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            "Please fill all the required fields to continue.",
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF4E4376),
                    behavior: SnackBarBehavior.floating,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 26, vertical: 22),
                    action: SnackBarAction(
                      label: 'Dismiss',
                      textColor: Colors.amber.withOpacity(0.7),
                      onPressed: () {},
                    ),
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 160,
                height: 48,
                decoration: BoxDecoration(
                  color: _validBasic()
                      ? Colors.white
                      : Colors.brown.shade50.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _validBasic()
                        ? Colors.brown.shade700
                        : Colors.brown.shade100.withOpacity(0.8),
                    width: 2,
                  ),
                  boxShadow: [
                    if (_validBasic())
                      BoxShadow(
                        color: Colors.brown.shade200,
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    if (!_validBasic())
                      BoxShadow(
                        color: Colors.brown.shade100.withOpacity(0.6),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Next',
                      style: TextStyle(
                        color: _validBasic()
                            ? Colors.brown.shade700
                            : Colors.brown.shade200,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _humanCapital(RiskAssessmentState st) {
    final qs = st.questions
        .where((q) => humanVars.contains(q.variableNumber))
        .toList();

    final allHumanAnswers =
    qs.map((q) => _getSavedAnswer(q.variableNumber)).toList();

    bool isAllAnswered = allHumanAnswers.isNotEmpty &&
        allHumanAnswers
            .every((ans) =>
        ans != null && ans
            .toString()
            .trim()
            .isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 16.h, left: 16.w, right: 16.w),
          child: _bar('A. HUMAN CAPITAL', AppColors.headerBlueColor,
              textColor: AppColors.yellowColor),
        ),
        SizedBox(height: 14.h),
        Expanded(
          child: qs.isEmpty
              ? const Center(
              child: Text("No questions found.",
                  style: TextStyle(fontSize: 16)))
              : ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: qs.length,
            itemBuilder: (context, idx) =>
                AnimatedEntrance(
                  delay: Duration(milliseconds: 100 * idx),
                  child: _HumanCard(
                    question: qs[idx],
                    savedAnswer: _getSavedAnswer(qs[idx].variableNumber),
                    onGenderSelected: (val) {
                      setState(() => _selectedGender = val);
                      _saveFieldAnswers();
                    },
                    onSave: (variable, value) =>
                        _saveAnswer(variable.toString(), value),
                  ),
                ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 18.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => setState(() => step = 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 144,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.brown.shade400,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.brown.shade100.withOpacity(0.7),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back_rounded,
                          color: Colors.brown.shade500, size: 22),
                      const SizedBox(width: 9),
                      Text(
                        'Previous',
                        style: TextStyle(
                          color: Colors.brown.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 15.5,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: isAllAnswered
                    ? () => setState(() => step = 2)
                    : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: Colors.amber, size: 24),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              "Please answer all Human Capital questions to continue.",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF4E4376),
                      behavior: SnackBarBehavior.floating,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 26, vertical: 22),
                      action: SnackBarAction(
                        label: 'Dismiss',
                        textColor: Colors.amber.withOpacity(0.7),
                        onPressed: () {},
                      ),
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 144,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isAllAnswered
                        ? Colors.white
                        : Colors.brown.shade50.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isAllAnswered
                          ? Colors.brown.shade700
                          : Colors.brown.shade100.withOpacity(0.8),
                      width: 2,
                    ),
                    boxShadow: [
                      if (isAllAnswered)
                        BoxShadow(
                          color: Colors.brown.shade200,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      if (!isAllAnswered)
                        BoxShadow(
                          color: Colors.brown.shade100.withOpacity(0.6),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 9),
                      Text(
                        'Next',
                        style: TextStyle(
                          color: isAllAnswered
                              ? Colors.brown.shade700
                              : Colors.brown.shade200,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Icon(Icons.arrow_forward_rounded,
                          color: isAllAnswered ? Colors.brown.shade500 : Colors
                              .brown.shade200, size: 22),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _agriDairy(RiskAssessmentState st) {
    final qs = st.questions
        .where((q) => agVars.contains(q.variableNumber))
        .toList();

    final List<Map<String, int>> pageRanges = [
      {'start': 0, 'end': 10},
      {'start': 10, 'end': 23},
      {'start': 23, 'end': 31},
      {'start': 31, 'end': 39},
    ];

    final Set<String> agHeadings = {'13', '18'};

    return Padding(
      padding: EdgeInsets.only(top: 16.h, left: 16.w, right: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _bar(
            'B. AGRICULTURE AND DAIRYING SCENARIO',
            AppColors.headerBlueColor,
            textColor: AppColors.yellowColor,
          ),
          Expanded(
            child: PageView.builder(
              controller: _agPageCtrl,
              itemCount: pageRanges.length,
              onPageChanged: (i) => setState(() => agPageIdx = i),
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (_, i) {
                final start = pageRanges[i]['start']!;
                final end = pageRanges[i]['end']!.clamp(0, qs.length);
                if (start >= end) return Container();
                final pageSlice = qs.sublist(start, end);

                final List<QuestionModel> pageQuestions = pageSlice.where((q) {
                  final varNum = q.variableNumber.toString();
                  return varNum
                      .trim()
                      .isNotEmpty &&
                      !agHeadings.contains(varNum);
                }).toList();


                final List<String> pageVars = pageQuestions
                    .map((q) => q.variableNumber.toString())
                    .toList();

                final List<String?> pageAnswers =
                pageVars.map((v) => _getSavedAnswer(v)).toList();

                final int answeredCount = pageAnswers
                    .where((ans) =>
                ans != null && ans
                    .toString()
                    .trim()
                    .isNotEmpty)
                    .length;
                final int totalQuestions = pageVars.length;

                bool isPageAnswered =
                    totalQuestions > 0 && answeredCount == totalQuestions;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (i == 2)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.greenColor,
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: const AppText(
                          text: 'C. Buffaloes',
                          color: Colors.white,
                          textSize: 14,
                          textAlign: TextAlign.start,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          for (int j = 0; j < pageSlice.length; j++)
                            AnimatedEntrance(
                              delay: Duration(milliseconds: 120 * j),
                              child: _AgCard(
                                question: pageSlice[j],
                                savedAnswer: _getSavedAnswer(
                                    pageSlice[j].variableNumber.toString()),
                                onSave: (variable, value) =>
                                    _saveAnswer(variable.toString(), value),
                              ),

                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                      EdgeInsets.symmetric(vertical: 14.h, horizontal: 4.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (i == 0) {
                                setState(() => step = 1);
                              } else {
                                setState(() => agPageIdx = i - 1);
                                _agPageCtrl.animateToPage(
                                  i - 1,
                                  duration: const Duration(milliseconds: 320),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 170),
                              width: 144,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.brown.shade400,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                    Colors.brown.shade100.withOpacity(0.7),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_back_rounded,
                                      color: Colors.brown.shade500, size: 22),
                                  const SizedBox(width: 9),
                                  Text(
                                    'Previous',
                                    style: TextStyle(
                                      color: Colors.brown.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15.5,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          GestureDetector(
                            onTap: isPageAnswered
                                ? () {
                              if (i < pageRanges.length - 1) {
                                setState(() => agPageIdx = i + 1);
                                _agPageCtrl.animateToPage(
                                  i + 1,
                                  duration:
                                  const Duration(milliseconds: 320),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                setState(() => step = 3);
                              }
                            }
                                : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.info_outline_rounded,
                                          color: Colors.amber, size: 24),
                                      SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          "Please answer all questions on this page to continue.",
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontWeight:
                                              FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor:
                                  const Color(0xFF4E4376),
                                  behavior: SnackBarBehavior.floating,
                                  elevation: 8,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(16)),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 26, vertical: 22),
                                  action: SnackBarAction(
                                    label: 'Dismiss',
                                    textColor:
                                    Colors.amber.withOpacity(0.7),
                                    onPressed: () {},
                                  ),
                                ),
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: 144,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isPageAnswered
                                    ? Colors.white
                                    : Colors.brown.shade50.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: isPageAnswered
                                      ? Colors.brown.shade700
                                      : Colors.brown.shade100.withOpacity(0.8),
                                  width: 2,
                                ),
                                boxShadow: [
                                  if (isPageAnswered)
                                    BoxShadow(
                                      color: Colors.brown.shade200,
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  if (!isPageAnswered)
                                    BoxShadow(
                                      color: Colors.brown.shade100
                                          .withOpacity(0.6),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 9),
                                  Text(
                                    'Next',
                                    style: TextStyle(
                                      color: isPageAnswered
                                          ? Colors.brown.shade700
                                          : Colors.brown.shade200,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15.5,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  Icon(Icons.arrow_forward_rounded,
                                      color: isPageAnswered ? Colors.brown
                                          .shade500 : Colors.brown.shade200,
                                      size: 22),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _social(RiskAssessmentState st) {
    final Set<String> socialHeadings = {};

    final List<String> requiredSocialVars = [
      if (st.questions.any((q) => q.variableNumber == '34')) '34',
      if (st.questions.any((q) => q.variableNumber == '35')) '35',
      if (st.questions.any((q) => q.variableNumber == '36')) '36',
      if (st.questions.any((q) => q.variableNumber == '37')) '37',
      if (st.questions.any((q) => q.variableNumber == '38')) '38',
    ].where((v) => !socialHeadings.contains(v)).toList();

    final List<String?> requiredAnswers =
    requiredSocialVars.map((v) => _getSavedAnswer(v)).toList();

    final int answeredCount = requiredAnswers
        .where((ans) =>
    ans != null && ans
        .toString()
        .trim()
        .isNotEmpty)
        .length;
    final int totalRequired = requiredSocialVars.length;
    bool isPageAnswered = totalRequired > 0 && answeredCount == totalRequired;

    final multiOfficials = st.questions.firstWhere(
          (q) => q.variableNumber == '36',
      orElse: () =>
          QuestionModel(variableNumber: '36', questionText: 'Placeholder'),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _bar('D. SOCIAL EMBEDDEDNESS', AppColors.headerBlueColor,
              textColor: AppColors.yellowColor, height: 50.h),
          SizedBox(height: 14.h),
          if (st.questions.any((q) => q.variableNumber == '34'))
            _SocialCardYesNo(
              question:
              st.questions.firstWhere((q) => q.variableNumber == '34'),
              savedAnswer: _getSavedAnswer('34'),
              onSave: (variable, value) =>
                  _saveAnswer(variable.toString(), value),
            ),
          if (st.questions.any((q) => q.variableNumber == '35'))
            _SocialCardNum(
              question:
              st.questions.firstWhere((q) => q.variableNumber == '35'),
              yellow: true,
              savedAnswer: _getSavedAnswer('35'),
              onSave: (variable, value) =>
                  _saveAnswer(variable.toString(), value),
            ),
          if (st.questions.any((q) => q.variableNumber == '36'))
            _OfficialMulti(
              question:
              st.questions.firstWhere((q) => q.variableNumber == '36'),
              savedAnswer: _getSavedAnswer('36'),
              onSave: (num variable, dynamic value) =>
                  _saveAnswer(variable.toString(), value),
            ),
          if (!st.questions.any((q) => q.variableNumber == '36'))
            _OfficialMulti(
              question: multiOfficials,
              savedAnswer: _getSavedAnswer('36'),
              onSave: (num variable, dynamic value) =>
                  _saveAnswer(variable.toString(), value),
            ),
          if (st.questions.any((q) => q.variableNumber == '37'))
            _SocialCardNum(
              question:
              st.questions.firstWhere((q) => q.variableNumber == '37'),
              yellow: true,
              savedAnswer: _getSavedAnswer('37'),
              onSave: (variable, value) =>
                  _saveAnswer(variable.toString(), value),
            ),
          if (st.questions.any((q) => q.variableNumber == '38'))
            _SocialCardNum(
              question:
              st.questions.firstWhere((q) => q.variableNumber == '38'),
              yellow: false,
              savedAnswer: _getSavedAnswer('38'),
              onSave: (variable, value) =>
                  _saveAnswer(variable.toString(), value),
            ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => setState(() => step = 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 170),
                  width: 144,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.brown.shade400,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.brown.shade100.withOpacity(0.7),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back_rounded,
                          color: Colors.brown.shade500, size: 22),
                      const SizedBox(width: 9),
                      Text(
                        'Previous',
                        style: TextStyle(
                          color: Colors.brown.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 15.5,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: isPageAnswered
                    ? () => setState(() => step = 5)
                    : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: Colors.amber, size: 24),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              "Please answer all questions to continue.",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF4E4376),
                      behavior: SnackBarBehavior.floating,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 26, vertical: 22),
                      action: SnackBarAction(
                        label: 'Dismiss',
                        textColor: Colors.amber.withOpacity(0.7),
                        onPressed: () {},
                      ),
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 144,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isPageAnswered
                        ? Colors.white
                        : Colors.brown.shade50.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isPageAnswered
                          ? Colors.brown.shade700
                          : Colors.brown.shade100.withOpacity(0.8),
                      width: 2,
                    ),
                    boxShadow: [
                      if (isPageAnswered)
                        BoxShadow(
                          color: Colors.brown.shade200,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      if (!isPageAnswered)
                        BoxShadow(
                          color: Colors.brown.shade100.withOpacity(0.6),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 9),
                      Text(
                        'Next',
                        style: TextStyle(
                          color: isPageAnswered
                              ? Colors.brown.shade700
                              : Colors.brown.shade200,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Icon(Icons.arrow_forward_rounded,
                          color: isPageAnswered ? Colors.brown.shade500 : Colors
                              .brown.shade200, size: 22),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infrastructure(RiskAssessmentState st) {
    final qs = st.questions
        .where((q) => infraVars.contains(q.variableNumber))
        .toList();

    final Set<String> infraHeadings = {};

    final List<QuestionModel> inputQuestions = qs
        .where((q) => !infraHeadings.contains(q.variableNumber.toString()))
        .toList();

    final List<String> inputVars =
    inputQuestions.map((q) => q.variableNumber.toString()).toList();

    final List<String?> inputAnswers =
    inputVars.map((v) => _getSavedAnswer(v)).toList();

    final int answeredCount = inputAnswers
        .where((ans) =>
    ans != null && ans
        .toString()
        .trim()
        .isNotEmpty)
        .length;
    final int totalQuestions = inputVars.length;

    bool isPageAnswered = totalQuestions > 0 && answeredCount == totalQuestions;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _bar('E. INFRASTRUCTURAL ACCESSIBILITY', AppColors.headerBlueColor,
              textColor: AppColors.yellowColor, height: 50.h),
          SizedBox(height: 14.h),
          ...qs
              .asMap()
              .entries
              .map((e) =>
              AnimatedEntrance(
                delay: Duration(milliseconds: 110 * e.key),
                child: _InfraCard(
                  question: e.value,
                  savedAnswer: _getSavedAnswer(e.value.variableNumber),
                  onSave: _saveAnswer,
                ),
              )),
          SizedBox(height: 22.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => setState(() => step = 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 170),
                  width: 144,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.brown.shade400,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.brown.shade100.withOpacity(0.7),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back_rounded,
                          color: Colors.brown.shade500, size: 22),
                      const SizedBox(width: 9),
                      Text(
                        'Previous',
                        style: TextStyle(
                          color: Colors.brown.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 15.5,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: isPageAnswered
                    ? () => setState(() => step = 6)
                    : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: Colors.amber, size: 24),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              "Please answer all questions to continue.",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF4E4376),
                      behavior: SnackBarBehavior.floating,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 26, vertical: 22),
                      action: SnackBarAction(
                        label: 'Dismiss',
                        textColor: Colors.amber.withOpacity(0.7),
                        onPressed: () {},
                      ),
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 144,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isPageAnswered
                        ? Colors.white
                        : Colors.brown.shade50.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isPageAnswered
                          ? Colors.brown.shade700
                          : Colors.brown.shade100.withOpacity(0.8),
                      width: 2,
                    ),
                    boxShadow: [
                      if (isPageAnswered)
                        BoxShadow(
                          color: Colors.brown.shade200,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      if (!isPageAnswered)
                        BoxShadow(
                          color: Colors.brown.shade100.withOpacity(0.6),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 9),
                      Text(
                        'Next',
                        style: TextStyle(
                          color: isPageAnswered
                              ? Colors.brown.shade700
                              : Colors.brown.shade200,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Icon(Icons.arrow_forward_rounded,
                          color: isPageAnswered ? Colors.brown.shade500 : Colors
                              .brown.shade200, size: 22),
                    ],
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _socioClimatic(RiskAssessmentState st) {
    List<QuestionModel> slice(int idx) {
      if (idx == 0) {
        return st.questions
            .where((q) => percepVars.contains(q.variableNumber))
            .toList();
      } else if (idx == 1) {
        return st.questions
            .where((q) => awareVars.contains(q.variableNumber))
            .toList();
      } else {
        return st.questions
            .where((q) => prepVars.contains(q.variableNumber))
            .toList();
      }
    }

    final titles = [
      '45. Perception towards climate change',
      '46. Awareness towards climate change',
      '47. Preparedness towards climate change'
    ];

    final List<QuestionModel> pageQuestions = slice(climatePageIdx);

    final Set<String> climateHeadings = {};

    final List<String> pageVars = pageQuestions
        .where((q) => !climateHeadings.contains(q.variableNumber.toString()))
        .map((q) => q.variableNumber.toString())
        .toList();

    final List<String?> pageAnswers =
    pageVars.map((v) => _getSavedAnswer(v)).toList();

    final int answeredCount = pageAnswers
        .where((ans) =>
    ans != null && ans
        .toString()
        .trim()
        .isNotEmpty)
        .length;
    final int totalQuestions = pageVars.length;

    bool isPageAnswered = totalQuestions > 0 && answeredCount == totalQuestions;

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _bar('F. SOCIO‑CLIMATIC CAPITAL', AppColors.headerBlueColor,
            textColor: AppColors.yellowColor, height: 50.h),
        SizedBox(height: 10.h),
        Expanded(
          child: PageView.builder(
            controller: _climateCtrl,
            itemCount: 3,
            onPageChanged: (i) => setState(() => climatePageIdx = i),
            itemBuilder: (_, i) =>
                ListView(
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _bar(
                      titles[i],
                      Colors.brown.shade700,
                      textColor: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    if (i == 2)
                      _bar(
                        'Adaptation options for dairy animals against climate change are given below. If you are following it, please tick “Yes=1” and “No=0” if you are not.',
                        Colors.white,
                        textColor: Colors.red,
                        innerVPad: 0,
                        textSize: 12.sp,
                        borderTransparent: true,
                      )
                    else
                      _bar(
                        'Please give your opinion on the following based on your experience during last 30-40 years (4=strongly agree, 3=highly agree, 2=somewhat agree, 1=agree, 0=not agree)',
                        Colors.white,
                        textColor: Colors.red,
                        innerVPad: 0,
                        textSize: 12.sp,
                        borderTransparent: true,
                      ),
                    const SizedBox(height: 10),
                    ...slice(i)
                        .asMap()
                        .entries
                        .map(
                          (e) =>
                          AnimatedEntrance(
                            delay: Duration(milliseconds: 110 * e.key),
                            child: i == 2
                                ? _YesNoCircle(
                              question: e.value,
                              savedAnswer:
                              _getSavedAnswer(e.value.variableNumber),
                              onSave: _saveAnswer,
                            )
                                : _RatingCircle(
                              question: e.value,
                              savedAnswer:
                              _getSavedAnswer(e.value.variableNumber),
                              onSave: _saveAnswer,
                            ),
                          ),
                    ),
                    if (i == 2)
                      const AnimatedEntrance(
                        delay: Duration(milliseconds: 400),
                        child: _ExtraAdaptationCard(),
                      ),
                    SizedBox(height: 80.h),
                  ],
                ),
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () =>
              climatePageIdx == 0
                  ? setState(() => step = 5)
                  : _climateCtrl.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeIn),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 170),
                width: 144,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.brown.shade400,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.shade100.withOpacity(0.7),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back_rounded,
                        color: Colors.brown.shade500, size: 22),
                    const SizedBox(width: 9),
                    Text(
                      'Previous',
                      style: TextStyle(
                        color: Colors.brown.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 15.5,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            if (climatePageIdx < 2)
              GestureDetector(
                onTap: isPageAnswered
                    ? () =>
                    _climateCtrl.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn)
                    : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: Colors.amber, size: 24),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              "Please answer all questions to continue.",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF4E4376),
                      behavior: SnackBarBehavior.floating,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 26, vertical: 22),
                      action: SnackBarAction(
                        label: 'Dismiss',
                        textColor: Colors.amber.withOpacity(0.7),
                        onPressed: () {},
                      ),
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 144,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isPageAnswered
                        ? Colors.white
                        : Colors.brown.shade50.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isPageAnswered
                          ? Colors.brown.shade700
                          : Colors.brown.shade100.withOpacity(0.8),
                      width: 2,
                    ),
                    boxShadow: [
                      if (isPageAnswered)
                        BoxShadow(
                          color: Colors.brown.shade200,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      if (!isPageAnswered)
                        BoxShadow(
                          color: Colors.brown.shade100.withOpacity(0.6),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 9),
                      Text(
                        'Next',
                        style: TextStyle(
                          color: isPageAnswered
                              ? Colors.brown.shade700
                              : Colors.brown.shade200,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Icon(Icons.arrow_forward_rounded,
                          color: isPageAnswered ? Colors.brown.shade500 : Colors
                              .brown.shade200, size: 22),
                    ],
                  ),
                ),
              ),
            if (climatePageIdx == 2)
              GestureDetector(
                onTap: isPageAnswered
                    ? () async {
                  final Map<String, String> answerMap = {};
                  for (final q in st.questions) {
                    final ans = _getSavedAnswer(q.variableNumber);
                    if (ans != null && ans.isNotEmpty)
                      answerMap[q.variableNumber] = ans;
                  }
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PreviewAnswersScreen(
                            allAnswers: answerMap,
                            allQuestions: st.questions,
                            onEditFirstQuestion: () {
                              Navigator.pop(context);
                              setState(() {
                                step = 1;
                                climatePageIdx = 0;
                              });
                            },
                            onSubmit: () {
                              Navigator.pop(context);
                              context.read<RiskAssessmentBloc>().add(
                                  SubmitAnswersEvent());
                            },
                          ),
                    ),
                  );
                }
                    : () {
                  ScaffoldMessenger
                      .of(context)
                      .showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: Colors.amber, size: 24),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                "Please answer all questions to continue.",
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF4E4376),
                        behavior: SnackBarBehavior.floating,
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 26, vertical: 22),
                        action: SnackBarAction(
                          label: 'Dismiss',
                          textColor: Colors.amber.withOpacity(0.7),
                          onPressed: () {},
                        ),
                      ));
                  },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 144,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isPageAnswered
                        ? Colors.white
                        : Colors.brown.shade50.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isPageAnswered
                          ? Colors.brown.shade700
                          : Colors.brown.shade100.withOpacity(0.8),
                      width: 2,
                    ),
                    boxShadow: [
                      if (isPageAnswered)
                        BoxShadow(
                          color: Colors.brown.shade200,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      if (!isPageAnswered)
                        BoxShadow(
                          color: Colors.brown.shade100.withOpacity(0.6),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPageAnswered
                            ? Icons.visibility
                            : Icons.lock_outline_rounded,
                        color: isPageAnswered
                            ? Colors.brown.shade700
                            : Colors.brown.shade200,
                        size: 18,
                      ),
                      const SizedBox(width: 9),
                      Text(
                        'Preview',
                        style: TextStyle(
                          color: isPageAnswered
                              ? Colors.brown.shade700
                              : Colors.brown.shade200,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

          ],
        ),
        if (climatePageIdx == 2)
          SizedBox(height: 10.h,),
        if (climatePageIdx == 2)
          GestureDetector(
            onTap: isPageAnswered
                ? () async {
              context
                  .read<RiskAssessmentBloc>()
                  .add(SubmitAnswersEvent());
              await _showSubmitResultDialog(context);
            }
                : () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: Colors.amber, size: 24),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          "Please answer all questions to continue.",
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF4E4376),
                  behavior: SnackBarBehavior.floating,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 26, vertical: 22),
                  action: SnackBarAction(
                    label: 'Dismiss',
                    textColor: Colors.amber.withOpacity(0.7),
                    onPressed: () {},
                  ),
                ),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 144,
              height: 44,
              decoration: BoxDecoration(
                color: isPageAnswered
                    ? Colors.white
                    : Colors.brown.shade50.withOpacity(0.8),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isPageAnswered
                      ? Colors.brown.shade700
                      : Colors.brown.shade100.withOpacity(0.8),
                  width: 2,
                ),
                boxShadow: [
                  if (isPageAnswered)
                    BoxShadow(
                      color: Colors.brown.shade200,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  if (!isPageAnswered)
                    BoxShadow(
                      color: Colors.brown.shade100.withOpacity(0.6),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPageAnswered
                        ? Icons.check_rounded
                        : Icons.lock_outline_rounded,
                    color: isPageAnswered
                        ? Colors.brown.shade700
                        : Colors.brown.shade200,
                    size: 21,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'Submit',
                    style: TextStyle(
                      color: isPageAnswered
                          ? Colors.brown.shade700
                          : Colors.brown.shade200,
                      fontWeight: FontWeight.bold,
                      fontSize: 15.5,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ]),
    );
  }

  Widget _thanks() =>
      Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.headerBlueColor.withOpacity(0.11),
              Colors.white,
              AppColors.greenColor.withOpacity(0.07),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.9, end: 1.0),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.elasticOut,
                  builder: (context, scale, _) =>
                      Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 26.w, vertical: 22.h),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.greenColor.withOpacity(0.18),
                                blurRadius: 34,
                                spreadRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: AppColors.headerBlueColor.withOpacity(
                                  0.18),
                              width: 2.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.celebration_rounded,
                                      color: AppColors.yellowColor, size: 38),
                                  const SizedBox(width: 10),
                                  AppText(
                                    text: 'Thank You!',
                                    color: AppColors.greenColor,
                                    textSize: 27.sp,
                                    fontWeight: FontWeight.w900,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.celebration_rounded,
                                      color: AppColors.yellowColor, size: 38),
                                ],
                              ),
                              SizedBox(height: 6.h),
                              AppText(
                                text: 'for your response',
                                color: Colors.grey.shade800,
                                textSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8.h),
                              AppText(
                                text: 'You’ve helped us make a difference!',
                                color: AppColors.headerBlueColor.withOpacity(
                                    0.92),
                                textSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                ),
                SizedBox(height: 36.h),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Transform.rotate(
                    angle: 0.00,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: AppColors.headerBlueColor.withOpacity(0.33),
                            width: 4.0),
                        borderRadius: BorderRadius.circular(19),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amberAccent.withOpacity(0.14),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          Assets.imgThanks,
                          fit: BoxFit.contain,
                          height: 190,
                          width: 260,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1300),
                  curve: Curves.easeOutBack,
                  builder: (context, anim, child) =>
                      Opacity(
                        opacity: (anim.clamp(0.0, 1.0)),
                        child: Transform.scale(
                          scale: 0.98 + 0.02 * anim,
                          child: child,
                        ),
                      ),
                  child: ElevatedButton.icon(
                    onPressed: _generateReport,
                    icon: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1100),
                      builder: (context, value, child) =>
                          Transform.translate(
                            offset: Offset(0, -7 + 7 * value),
                            child: Icon(
                              Icons.download_rounded,
                              color: Colors.white,
                              size: 27 + 7 * value,
                            ),
                          ),
                    ),
                    label: const Text(
                      'Download Report',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A91F0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      elevation: 13,
                      shadowColor: Colors.blueAccent.withOpacity(0.25),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1100),
                  curve: Curves.easeOutExpo,
                  builder: (context, anim, child) =>
                      Opacity(
                        opacity: (anim.clamp(0.0, 1.0)),
                        child: Transform.scale(
                          scale: 0.98 + 0.02 * anim,
                          child: child,
                        ),
                      ),
                  child: ElevatedButton(
                    onPressed: () async {
                      await _clearAnswers();
                      context.go('/welcome');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.greenColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 42, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(38),
                      ),
                      elevation: 13,
                      shadowColor: Colors.greenAccent.withOpacity(0.25),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 300),
                          child: Icon(
                            Icons.check_circle_rounded,
                            key: ValueKey('done_icon'),
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        SizedBox(width: 14),
                        Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
              ],
            ),
          ),
        ),
      );

  Widget _livelihood(RiskAssessmentState st) {
    final qs =
    st.questions.where((q) => livVars.contains(q.variableNumber)).toList();

    final Set<String> livHeadings = {};

    final multi = st.questions.firstWhere((q) => q.variableNumber == '29');

    final List<QuestionModel> inputQuestions = qs
        .where((q) =>
    !livHeadings.contains(q.variableNumber.toString()) &&
        q.variableNumber.toString() != '29')
        .toList();

    final List<String> inputVars =
    inputQuestions.map((q) => q.variableNumber.toString()).toList();

    final List<String?> inputAnswers =
    inputVars.map((v) => _getSavedAnswer(v)).toList();

    final int answeredCount = inputAnswers
        .where((ans) =>
    ans != null && ans
        .toString()
        .trim()
        .isNotEmpty)
        .length;
    final int totalQuestions = inputVars.length;

    bool isPageAnswered = totalQuestions > 0 && answeredCount == totalQuestions;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _bar('C. LIVELIHOOD AND INCOME', AppColors.headerBlueColor,
            textColor: AppColors.yellowColor, height: 50.h),
        SizedBox(height: 14.h),
        _IncomeMulti(
          questionMulti: multi,
          savedAnswer: _getSavedAnswer('29'),
          onSave: (num variable, dynamic value) =>
              _saveAnswer(variable.toString(), value),
        ),
        ...inputQuestions.map((q) =>
            _LivCard(
              question: q,
              savedAnswer: _getSavedAnswer(q.variableNumber),
              onSave: (variable, value) =>
                  _saveAnswer(variable.toString(), value),
            )),
        SizedBox(height: 22.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => setState(() => step = 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 170),
                width: 144,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.brown.shade400,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.shade100.withOpacity(0.7),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back_rounded,
                        color: Colors.brown.shade500, size: 22),
                    const SizedBox(width: 9),
                    Text(
                      'Previous',
                      style: TextStyle(
                        color: Colors.brown.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 15.5,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            GestureDetector(
              onTap: isPageAnswered
                  ? () => setState(() => step = 4)
                  : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: Colors.amber, size: 24),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            "Please answer all questions to continue.",
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF4E4376),
                    behavior: SnackBarBehavior.floating,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 26, vertical: 22),
                    action: SnackBarAction(
                      label: 'Dismiss',
                      textColor: Colors.amber.withOpacity(0.7),
                      onPressed: () {},
                    ),
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 144,
                height: 44,
                decoration: BoxDecoration(
                  color: isPageAnswered
                      ? Colors.white
                      : Colors.brown.shade50.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isPageAnswered
                        ? Colors.brown.shade700
                        : Colors.brown.shade100.withOpacity(0.8),
                    width: 2,
                  ),
                  boxShadow: [
                    if (isPageAnswered)
                      BoxShadow(
                        color: Colors.brown.shade200,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    if (!isPageAnswered)
                      BoxShadow(
                        color: Colors.brown.shade100.withOpacity(0.6),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 9),
                    Text(
                      'Next',
                      style: TextStyle(
                        color: isPageAnswered
                            ? Colors.brown.shade700
                            : Colors.brown.shade200,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.5,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Icon(Icons.arrow_forward_rounded,
                        color: isPageAnswered ? Colors.brown.shade500 : Colors
                            .brown.shade200, size: 22),
                  ],
                ),
              ),
            ),
          ],
        )
      ]),
    );
  }

  bool _validBasic() =>
      nameCtrl.text
          .trim()
          .isNotEmpty &&
          blockCtrl.text
              .trim()
              .isNotEmpty &&
          villageCtrl.text
              .trim()
              .isNotEmpty &&
          selectedState != null &&
          selectedDistrict != null;

  InputDecoration _dec(String h) =>
      InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        hintText: h,
        hintStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6.r)),
        contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
      );

  Widget _outlined(TextEditingController c, String h) =>
      TextField(controller: c, decoration: _dec(h));

  Widget _disabled(String h) =>
      InputDecorator(
        decoration: _dec(h),
        child: SizedBox(
          height: 25.h,
          child: Align(
              alignment: Alignment.centerLeft,
              child: Text(h,
                  style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                      fontWeight: FontWeight.w600))),
        ),
      );

  Widget _bar(String t,
      Color c, {
        Color textColor = Colors.white,
        double? height,
        bool center = false,
        bool expanded = true,
        double innerHPad = 8,
        double innerVPad = 7,
        double outerHPad = 10,
        double? textSize,
        bool borderTransparent = false,
      }) {
    final barContent = Container(
      padding:
      EdgeInsets.symmetric(horizontal: innerHPad.w, vertical: innerVPad.h),
      decoration: BoxDecoration(
        color: c,
        border: Border.all(
          color: borderTransparent ? Colors.transparent : Colors.black,
          width: 1.8,
        ),
      ),
      child: Text(
        t,
        style: TextStyle(
          color: textColor,
          fontSize: (textSize ?? 18).sp,
          fontWeight: FontWeight.w500,
        ),
        textAlign: center ? TextAlign.center : TextAlign.left,
        maxLines: null,
      ),
    );
    if (expanded) {
      return SizedBox(width: double.infinity, child: barContent);
    } else {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: outerHPad.w),
        child: Align(
          alignment: center ? Alignment.center : Alignment.centerLeft,
          child: barContent,
        ),
      );
    }
  }
}

class _HumanCard extends StatefulWidget {
  final QuestionModel question;
  final String? savedAnswer;
  final void Function(String)? onGenderSelected;
  final Future<void> Function(String, dynamic)? onSave;

  const _HumanCard({
    required this.question,
    this.savedAnswer,
    this.onGenderSelected,
    this.onSave,
  });

  @override
  State<_HumanCard> createState() => _HumanCardState();
}

class _HumanCardState extends State<_HumanCard> {
  String? _gender, _edu, _household;
  late TextEditingController _ctrl;
  double? finalValue;

  @override
  void initState() {
    super.initState();
    final v = widget.question.variableNumber;
    if (v == '1') _gender = widget.savedAnswer;
    if (v == '3') _edu = widget.savedAnswer;
    if (v == '10') _household = widget.savedAnswer;
    _ctrl = TextEditingController(text: widget.savedAnswer ?? '');
    calculateFinalValue(_ctrl.text);
  }

  void calculateFinalValue(String input) {
    final v = widget.question.variableNumber;
    if (questionParams.containsKey(v)) {
      final params = questionParams[v]!;
      final double? inputVal = double.tryParse(input);
      if (inputVal != null) {
        final min = params['min'] as num;
        final max = params['max'] as num;
        final weight = params['weight'] as double;
        final isPositive = params['isPositive'] as bool;

        final normalized = max == min ? 0 : ((inputVal - min) / (max - min));
        final value = ((isPositive ? normalized : (1 - normalized)) * weight);
        setState(() => finalValue = value);
      } else {
        setState(() => finalValue = null);
      }
    } else {
      setState(() => finalValue = null);
    }
  }


  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.question.variableNumber;
    Color barCol = (v == '2' || v == '4' || v == '6' || v == '8' || v == '10')
        ? AppColors.yellowColor
        : AppColors.greenColor;

    Widget field;
    if (v == '1') {
      field = DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _gender,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          hint: const Text(
            "Select Gender", style: TextStyle(color: Colors.grey),),
          items: ['Male', 'Female', 'Other']
              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
              .toList(),
          onChanged: (val) {
            setState(() => _gender = val);
            widget.onGenderSelected?.call(val!);
            context.read<RiskAssessmentBloc>().add(SaveAnswerEvent(v, val!));
            widget.onSave?.call(v, val);
          },
        ),
      );
    } else if (v == '3') {
      field = DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _edu,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          hint: Text('Select Education', style: TextStyle(color: Colors.grey),),
          items: [
            'No formal schooling',
            'Primary',
            'Secondary',
            'Higher secondary',
            'Diploma/certificate course',
            'Graduate',
            'Post graduate and above',
          ].map((e) =>
              DropdownMenuItem(
                  value: e, child: Text(e, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (val) {
            setState(() => _edu = val);
            context.read<RiskAssessmentBloc>().add(SaveAnswerEvent(v, val!));
            widget.onSave?.call(v, val);
          },
        ),
      );
    } else if (v == '10') {
      field = DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _household,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          hint: Text(
            'Select Household Type', style: TextStyle(color: Colors.grey),),
          items: [
            'Permanent Pucca house',
            'Permanent Kaccha house',
            'Temporary house'
          ].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
          onChanged: (val) {
            setState(() => _household = val);
            context.read<RiskAssessmentBloc>().add(SaveAnswerEvent(v, val!));
            widget.onSave?.call(v, val);
          },
        ),
      );
    } else {
      field = TextField(
        controller: _ctrl,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: 'Type here',
          hintStyle: const TextStyle(color: Colors.grey),
          contentPadding: EdgeInsets.symmetric(vertical: 3.h),
        ),
        keyboardType: TextInputType.number,
        onChanged: (txt) {
          calculateFinalValue(txt);
          context.read<RiskAssessmentBloc>().add(SaveAnswerEvent(v, txt));
          widget.onSave?.call(v, txt);
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
          decoration: BoxDecoration(
              color: barCol,
              border: Border.all(color: Colors.black, width: 1.5)),
          child: AppText(
              text: '$v. ${widget.question.questionText}',
              color: barCol == AppColors.yellowColor ? Colors.black : Colors
                  .white,
              textSize: 14.sp,
              fontWeight: FontWeight.w600),
        ),
        Container(
          height: 38.h,
          margin: EdgeInsets.only(bottom: 6.h),
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.greenColor, width: 1.4)),
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          alignment: Alignment.centerLeft,
          child: field,
        ),
        if (finalValue != null)
          Padding(
            padding: EdgeInsets.only(bottom: 14.h, left: 8.w),
            child: Text(
              'Final Value: ${finalValue!.toStringAsFixed(3)}',
              style: TextStyle(
                color: Colors.teal.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 13.5.sp,
              ),
            ),
          ),
      ],
    );
  }
}


class AnimatedEntrance extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const AnimatedEntrance({super.key, required this.child, required this.delay});

  @override
  State<AnimatedEntrance> createState() => _AEState();
}

class _AEState extends State<AnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shineCtrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _shineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slide = Tween(begin: const Offset(0, .15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _shineCtrl, curve: Curves.easeOut));
    _fade = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _shineCtrl, curve: Curves.easeOut));
    Future.delayed(widget.delay, () {
      if (mounted) _shineCtrl.forward();
    });
  }

  @override
  void dispose() {
    _shineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SlideTransition(
          position: _slide,
          child: FadeTransition(opacity: _fade, child: widget.child));
}

class _AgCard extends StatefulWidget {
  final QuestionModel question;
  final String? savedAnswer;
  final Future<void> Function(String, dynamic)? onSave;

  const _AgCard({
    required this.question,
    this.savedAnswer,
    this.onSave,
  });

  @override
  State<_AgCard> createState() => _AgCardState();
}

class _AgCardState extends State<_AgCard> {
  late TextEditingController _ctrl;
  late Set<String> selP;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.savedAnswer ?? '');
    if (widget.savedAnswer != null && widget.savedAnswer!.isNotEmpty) {
      selP = widget.savedAnswer!.split(',').toSet();
    } else {
      selP = <String>{};
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.question.variableNumber;
    Color barCol;
    if (v == '12' ||
        v == '14' ||
        v == '16' ||
        v == '18' ||
        v == '19' ||
        v == '24' ||
        v == '26' ||
        v == '22') {
      barCol = AppColors.yellowColor;
    } else if (v == '27') {
      barCol = AppColors.greenColor;
    } else if (v == '28') {
      barCol = AppColors.hardGreen;
    } else if (v == '13.1' ||
        v == '13.2' ||
        v == '13.3' ||
        v == '18.1' ||
        v == '18.2' ||
        v == '18.3' ||
        v == '18.4' ||
        v == '18.5' ||
        v == '18.6' ||
        v == '18.7' ||
        v == '18.8' ||
        v == '18.9' ||
        v == '18.10' ||
        v == '18.11' ||
        v == '18.12' ||
        v == '18.13' ||
        v == '18.14' ||
        v == '18.15' ||
        v == '18.16' ||
        v == '18.17' ||
        v == '18.18') {
      barCol = AppColors.hardPink;
    } else {
      barCol = AppColors.greenColor;
    }

    final dprofile = [
      'Mastitis',
      'Milk Fever',
      'Anoestrous',
      'Prolapse',
      'FMD',
      'Repeat breeding',
      'Worms',
      'Ticks',
      'Brucellosis',
      'Hypothermia',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: (v == '13.1' ||
              v == '13.2' ||
              v == '13.3' ||
              v == '18.1' ||
              v == '18.2' ||
              v == '18.3' ||
              v == '18.4' ||
              v == '18.5' ||
              v == '18.6' ||
              v == '18.7' ||
              v == '18.8' ||
              v == '18.9' ||
              v == '18.10' ||
              v == '18.11' ||
              v == '18.12' ||
              v == '18.13' ||
              v == '18.14' ||
              v == '18.15' ||
              v == '18.16' ||
              v == '18.17' ||
              v == '18.18')
              ? const EdgeInsets.only(left: 25)
              : EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: barCol,
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: AppText(
            text:
            '${widget.question.variableNumber}. ${widget.question
                .questionText}',
            color: (barCol == AppColors.yellowColor ||
                barCol == AppColors.hardPink)
                ? Colors.black
                : Colors.white,
            textSize: 14,
            textAlign: v == '18' ? TextAlign.center : TextAlign.start,
            fontWeight: FontWeight.w700,
          ),
        ),
        v == '18' || v == '13' || v == '20'
            ? const SizedBox(
          height: 24,
        )
            : Container(
          height: 34,
          margin: (v == '13.1' ||
              v == '13.2' ||
              v == '13.3' ||
              v == '18.1' ||
              v == '18.2' ||
              v == '18.3' ||
              v == '18.4' ||
              v == '18.5' ||
              v == '18.6' ||
              v == '18.7' ||
              v == '18.8' ||
              v == '18.9' ||
              v == '18.10' ||
              v == '18.11' ||
              v == '18.12' ||
              v == '18.13' ||
              v == '18.14' ||
              v == '18.15' ||
              v == '18.16' ||
              v == '18.17' ||
              v == '18.18')
              ? const EdgeInsets.only(left: 25, bottom: 14)
              : const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.greenColor, width: 1.4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: TextField(
            controller: _ctrl,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: 'Type here',
              hintStyle: const TextStyle(color: Colors.grey),
              contentPadding: EdgeInsets.symmetric(vertical: 3.h),
            ),
            keyboardType: TextInputType.number,
            onChanged: (txt) {
              context.read<RiskAssessmentBloc>().add(
                  SaveAnswerEvent(widget.question.variableNumber, txt));
              widget.onSave?.call(widget.question.variableNumber, txt);
            },
          ),
        ),
        if (v == '18')
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
                color: AppColors.greenColor,
                border: Border.all(color: Colors.black, width: 1.5)),
            child: const AppText(
                text: 'A. Indigenous cattle',
                color: Colors.white,
                textSize: 14,
                textAlign: TextAlign.start,
                fontWeight: FontWeight.w700),
          ),
        if (v == '20')
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (selP.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10, top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Selected:",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: selP
                                .map((d) =>
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() => selP.remove(d));
                                      context
                                          .read<RiskAssessmentBloc>()
                                          .add(SaveAnswerEvent(
                                          '20', selP.join(',')));
                                      widget.onSave
                                          ?.call('20', selP.join(','));
                                    },
                                    child: Chip(
                                      backgroundColor:
                                      Colors.green.shade100,
                                      avatar: const Icon(Icons.check_circle,
                                          color: Colors.green, size: 18),
                                      label: Text(
                                        d,
                                        style: TextStyle(
                                          color: Colors.green.shade800,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      deleteIcon: Icon(Icons.close,
                                          size: 16,
                                          color: Colors.green.shade700),
                                      onDeleted: () {
                                        setState(() => selP.remove(d));
                                        context
                                            .read<RiskAssessmentBloc>()
                                            .add(SaveAnswerEvent(
                                            '20', selP.join(',')));
                                        widget.onSave
                                            ?.call('20', selP.join(','));
                                      },
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Colors.blueGrey, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${selP.length} / ${dprofile.length} selected',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: Colors.blueGrey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.9,
                  physics: const NeverScrollableScrollPhysics(),
                  children: dprofile.map((label) {
                    final bool selected = selP.contains(label);
                    return GestureDetector(
                      onTap: () {
                        setState(() =>
                        selected ? selP.remove(label) : selP.add(label));
                        context
                            .read<RiskAssessmentBloc>()
                            .add(SaveAnswerEvent('20', selP.join(',')));
                        widget.onSave?.call('20', selP.join(','));
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 230),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color:
                          selected ? Colors.green.shade100 : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                            selected ? Colors.green : Colors.grey.shade300,
                            width: selected ? 2 : 1.1,
                          ),
                          boxShadow: [
                            if (selected)
                              BoxShadow(
                                color: Colors.green.withOpacity(0.11),
                                blurRadius: 10,
                                offset: const Offset(0, 1),
                              ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedScale(
                              scale: selected ? 1.13 : 0.0,
                              duration: const Duration(milliseconds: 170),
                              child: const Icon(Icons.check_circle,
                                  color: Colors.green, size: 17),
                            ),
                            if (selected) const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  fontSize: 13,
                                  color: selected
                                      ? Colors.green.shade700
                                      : Colors.grey.shade900,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 2),
              ],
            ),
          ),
        if (v == '18.6')
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
                color: AppColors.yellowColor,
                border: Border.all(color: Colors.black, width: 1.5)),
            child: const AppText(
                text: 'B. Crossbred cattle',
                color: Colors.black,
                textSize: 14,
                textAlign: TextAlign.start,
                fontWeight: FontWeight.w700),
          ),

      ],
    );
  }
}

class _IncomeMulti extends StatefulWidget {
  final QuestionModel questionMulti;
  final String? savedAnswer;
  final Future<void> Function(num, dynamic)? onSave;

  const _IncomeMulti({
    required this.questionMulti,
    this.savedAnswer,
    this.onSave,
  });

  @override
  State<_IncomeMulti> createState() => _IncomeMultiState();
}

class _IncomeMultiState extends State<_IncomeMulti> {
  final opts = [
    'Agriculture',
    'Dairy',
    'Daily wages',
    'Shopkeeping',
    'Other jobs'
  ];

  late Set<String> sel;

  @override
  void initState() {
    super.initState();
    if (widget.savedAnswer != null && widget.savedAnswer!.isNotEmpty) {
      sel = widget.savedAnswer!.split(',').toSet();
    } else {
      sel = <String>{};
    }
  }

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
                color: AppColors.greenColor,
                border: Border.all(color: Colors.black, width: 1.5)),
            child: const AppText(
                text: '29. Number of sources of income',
                color: Colors.white,
                textSize: 14,
                fontWeight: FontWeight.w700)),
        Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (sel.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Selected Income Sources:",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: sel
                                .map((d) =>
                                Padding(
                                  padding: const EdgeInsets.only(right: 7),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() => sel.remove(d));
                                      context
                                          .read<RiskAssessmentBloc>()
                                          .add(SaveAnswerEvent(
                                          '30', sel.join(',')));
                                      widget.onSave
                                          ?.call(30, sel.join(','));
                                    },
                                    child: Chip(
                                      backgroundColor:
                                      Colors.green.shade100,
                                      avatar: const Icon(Icons.check_circle,
                                          color: Colors.green, size: 18),
                                      label: Text(
                                        d,
                                        style: TextStyle(
                                          color: Colors.green.shade800,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      deleteIcon: Icon(Icons.close,
                                          size: 16,
                                          color: Colors.green.shade700),
                                      onDeleted: () {
                                        setState(() => sel.remove(d));
                                        context
                                            .read<RiskAssessmentBloc>()
                                            .add(SaveAnswerEvent(
                                            '30', sel.join(',')));
                                        widget.onSave
                                            ?.call(30, sel.join(','));
                                      },
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Colors.blueGrey, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${sel.length} / ${opts.length} selected',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: Colors.blueGrey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 3.1,
                  physics: const NeverScrollableScrollPhysics(),
                  children: opts.map((label) {
                    final bool selected = sel.contains(label);
                    return GestureDetector(
                      onTap: () {
                        setState(() =>
                        selected ? sel.remove(label) : sel.add(label));
                        context
                            .read<RiskAssessmentBloc>()
                            .add(SaveAnswerEvent('29', sel.join(',')));
                        widget.onSave?.call(29, sel.join(','));
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color:
                          selected ? Colors.green.shade100 : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                            selected ? Colors.green : Colors.grey.shade300,
                            width: selected ? 2 : 1.1,
                          ),
                          boxShadow: [
                            if (selected)
                              BoxShadow(
                                color: Colors.green.withOpacity(0.13),
                                blurRadius: 10,
                                offset: const Offset(0, 1),
                              ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedScale(
                              scale: selected ? 1.12 : 0.0,
                              duration: const Duration(milliseconds: 170),
                              child: const Icon(Icons.check_circle,
                                  color: Colors.green, size: 17),
                            ),
                            if (selected) const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  fontSize: 13,
                                  color: selected
                                      ? Colors.green.shade700
                                      : Colors.grey.shade900,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 2),
              ],
            )),
      ]);
}

class _LivCard extends StatefulWidget {
  final QuestionModel question;
  final String? savedAnswer;
  final Future<void> Function(String, dynamic)? onSave;

  const _LivCard({
    required this.question,
    this.savedAnswer,
    this.onSave,
  });

  @override
  State<_LivCard> createState() => _LivCardState();
}

class _LivCardState extends State<_LivCard> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.savedAnswer ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.question.variableNumber;
    Color barCol = (v == '43' || v == '45' || v == '31' || v == '33')
        ? AppColors.greenColor
        : AppColors.yellowColor;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
            color: barCol, border: Border.all(color: Colors.black, width: 1.5)),
        child: AppText(
            text: '${v.toString()}. ${widget.question.questionText}',
            color:
            barCol == AppColors.yellowColor ? Colors.black : Colors.white,
            textSize: 14,
            fontWeight: FontWeight.w700),
      ),
      Container(
        height: 34,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.blueGrey, width: 1.4)),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: TextField(
          controller: _ctrl,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            hintText: 'Type here',
            hintStyle: const TextStyle(color: Colors.grey),
            contentPadding: EdgeInsets.symmetric(vertical: 3.h),
          ),
          keyboardType: TextInputType.number,
          onChanged: (txt) {
            context
                .read<RiskAssessmentBloc>()
                .add(SaveAnswerEvent(widget.question.variableNumber, txt));
            widget.onSave?.call(widget.question.variableNumber, txt);
          },
        ),
      ),
    ]);
  }
}

class _SocialCardYesNo extends StatefulWidget {
  final QuestionModel question;
  final String? savedAnswer;
  final Future<void> Function(String, dynamic)? onSave;

  const _SocialCardYesNo({
    required this.question,
    this.savedAnswer,
    this.onSave,
  });

  @override
  State<_SocialCardYesNo> createState() => _SCYesNoState();
}

class _SCYesNoState extends State<_SocialCardYesNo> {
  int? sel;

  @override
  void initState() {
    super.initState();
    if (widget.savedAnswer != null && widget.savedAnswer!.isNotEmpty) {
      sel = int.tryParse(widget.savedAnswer!);
    }
  }

  @override
  Widget build(BuildContext context) =>
      _line(
        widget.question.questionText,
        AppColors.greenColor,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: sel,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down),
            hint: Text(
              "Select Yes or No", style: TextStyle(color: Colors.grey),),
            items: const [
              DropdownMenuItem(value: 1, child: Text('Yes')),
              DropdownMenuItem(value: 0, child: Text('No')),
            ],
            onChanged: (v) {
              setState(() => sel = v);
              context.read<RiskAssessmentBloc>().add(SaveAnswerEvent(
                  widget.question.variableNumber, v.toString()));
              widget.onSave?.call(widget.question.variableNumber, v.toString());
            },
          ),
        ),
      );
}

class _SocialCardNum extends StatefulWidget {
  final QuestionModel question;
  final bool yellow;
  final String? savedAnswer;
  final Future<void> Function(String, dynamic)? onSave;

  const _SocialCardNum({
    required this.question,
    required this.yellow,
    this.savedAnswer,
    this.onSave,
  });

  @override
  State<_SocialCardNum> createState() => _SocialCardNumState();
}

class _SocialCardNumState extends State<_SocialCardNum> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.savedAnswer ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) =>
      _line(
        widget.question.questionText,
        widget.yellow ? AppColors.yellowColor : AppColors.greenColor,
        child: TextField(
          controller: _ctrl,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            hintText: 'Type here',
            hintStyle: const TextStyle(color: Colors.grey),
            contentPadding: EdgeInsets.symmetric(vertical: 3.h),
          ),
          keyboardType: TextInputType.number,
          onChanged: (v) {
            ctx
                .read<RiskAssessmentBloc>()
                .add(SaveAnswerEvent(widget.question.variableNumber, v));
            widget.onSave?.call(widget.question.variableNumber, v);
          },
        ),
      );
}

class _OfficialMulti extends StatefulWidget {
  final QuestionModel question;
  final String? savedAnswer;
  final Future<void> Function(num, dynamic)? onSave;

  const _OfficialMulti({
    required this.question,
    this.savedAnswer,
    this.onSave,
  });

  @override
  State<_OfficialMulti> createState() => _OfficialMultiState();
}

class _OfficialMultiState extends State<_OfficialMulti> {
  final opts = ['ADO', 'BDO', 'Input dealers', 'Researchers'];
  late Set<String> sel;

  @override
  void initState() {
    super.initState();
    if (widget.savedAnswer != null && widget.savedAnswer!.isNotEmpty) {
      sel = widget.savedAnswer!.split(',').toSet();
    } else {
      sel = <String>{};
    }
  }

  @override
  Widget build(BuildContext context) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _bar(
              '36. Tap on the types of officials to whom you visited during last one year',
              AppColors.greenColor,
              textColor: Colors.white),
          Container(
            decoration: const BoxDecoration(color: Colors.white),
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (sel.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, top: 2, left: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_rounded,
                            color: Colors.green, size: 17),
                        const SizedBox(width: 5),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: sel
                                  .map((d) =>
                                  Padding(
                                    padding:
                                    const EdgeInsets.only(right: 6),
                                    child: Chip(
                                      label: Text(
                                        d,
                                        style: TextStyle(
                                          color: Colors.green.shade800,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      backgroundColor: Colors.green.shade50,
                                      deleteIcon: Icon(Icons.close,
                                          size: 15,
                                          color: Colors.green.shade700),
                                      onDeleted: () {
                                        setState(() => sel.remove(d));
                                        context
                                            .read<RiskAssessmentBloc>()
                                            .add(SaveAnswerEvent(
                                            '37', sel.join(',')));
                                        widget.onSave
                                            ?.call(37, sel.join(','));
                                      },
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(9),
                                      ),
                                    ),
                                  ))
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 7, left: 3),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Colors.blueGrey, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${sel.length} / ${opts.length} selected',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: Colors.blueGrey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  mainAxisSpacing: 9,
                  crossAxisSpacing: 9,
                  childAspectRatio: 2.9,
                  physics: const NeverScrollableScrollPhysics(),
                  children: opts.map((label) {
                    final bool selected = sel.contains(label);
                    return GestureDetector(
                      onTap: () {
                        setState(() =>
                        selected ? sel.remove(label) : sel.add(label));
                        context
                            .read<RiskAssessmentBloc>()
                            .add(SaveAnswerEvent('37', sel.join(',')));
                        widget.onSave?.call(37, sel.join(','));
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 210),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color:
                          selected ? Colors.green.shade100 : Colors.white,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color:
                            selected ? Colors.green : Colors.grey.shade400,
                            width: selected ? 2 : 1.1,
                          ),
                          boxShadow: [
                            if (selected)
                              BoxShadow(
                                color: Colors.green.withOpacity(0.11),
                                blurRadius: 8,
                                offset: const Offset(0, 1),
                              ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedScale(
                              scale: selected ? 1.12 : 0.0,
                              duration: const Duration(milliseconds: 150),
                              child: const Icon(Icons.check_circle,
                                  color: Colors.green, size: 16),
                            ),
                            if (selected) const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  fontSize: 12,
                                  color: selected
                                      ? Colors.green.shade800
                                      : Colors.grey.shade900,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      );
}

class _InfraCard extends StatefulWidget {
  final QuestionModel question;
  final String? savedAnswer;
  final Future<void> Function(String, dynamic)? onSave;

  const _InfraCard({
    required this.question,
    this.savedAnswer,
    this.onSave,
  });

  @override
  State<_InfraCard> createState() => _InfraCardState();
}

class _InfraCardState extends State<_InfraCard> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.savedAnswer ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.question.variableNumber;
    Color barCol = (v == '37' || v == '39' || v == '41' || v == '43')
        ? AppColors.greenColor
        : AppColors.yellowColor;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
            color: barCol, border: Border.all(color: Colors.black, width: 1.5)),
        child: AppText(
            text: '${v.toString()}. ${widget.question.questionText}',
            color:
            barCol == AppColors.yellowColor ? Colors.black : Colors.white,
            textSize: 14,
            fontWeight: FontWeight.w700),
      ),
      Container(
        height: 34,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.blueGrey, width: 1.4)),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: TextField(
          controller: _ctrl,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            hintText: 'Type here',
            hintStyle: const TextStyle(color: Colors.grey),
            contentPadding: EdgeInsets.symmetric(vertical: 3.h),
          ),

          keyboardType: TextInputType.number,
          onChanged: (txt) {
            context
                .read<RiskAssessmentBloc>()
                .add(SaveAnswerEvent(widget.question.variableNumber, txt));
            widget.onSave?.call(widget.question.variableNumber, txt);
          },
        ),
      ),
    ]);
  }
}

class _YesNoCircle extends StatefulWidget {
  final QuestionModel question;
  final String? savedAnswer;
  final Future<void> Function(String, dynamic)? onSave;

  const _YesNoCircle({
    required this.question,
    this.savedAnswer,
    this.onSave,
  });

  @override
  State<_YesNoCircle> createState() => _YesNoCircleState();
}

class _YesNoCircleState extends State<_YesNoCircle> {
  bool? yes;

  @override
  void initState() {
    super.initState();
    if (widget.savedAnswer != null && widget.savedAnswer!.isNotEmpty) {
      yes = widget.savedAnswer == "1";
    }
  }

  @override
  Widget build(BuildContext context) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: {'10. Follow vaccination schedule'}
                  .contains(widget.question.questionText.toString())
                  ? AppColors.yellowColor
                  : {
                '46.1',
                '46.3',
                '46.5',
                '46.7',
                '46.9',
                '46.11',
                '46.13',
                '46.15',
                '46.17'
              }.contains(widget.question.variableNumber.toString())
                  ? AppColors.greenColor
                  : AppColors.yellowColor,
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Text(
              widget.question.questionText,
              style: TextStyle(
                color: {'10. Follow vaccination schedule'}
                    .contains(widget.question.questionText.toString())
                    ? AppColors.blackColor
                    : {
                  '46.1',
                  '46.3',
                  '46.5',
                  '46.7',
                  '46.9',
                  '46.11',
                  '46.13',
                  '46.15',
                  '46.17'
                }.contains(widget.question.variableNumber.toString())
                    ? Colors.white
                    : Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            height: 60,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.blueGrey, width: 1.4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _circle(1, label: 'Yes', yesColor: const Color(0xFF2e7d32)),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const _DashLine(),
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          yes == null ? "" : (yes! ? "Yes" : "No"),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: yes == null
                                ? Colors.grey
                                : (yes!
                                ? const Color(0xFF2e7d32)
                                : const Color(0xFFc62828)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _circle(0, label: 'No', yesColor: const Color(0xFFc62828)),
              ],
            ),
          ),
        ],
      );

  Widget _circle(int v, {required String label, required Color yesColor}) =>
      GestureDetector(
        onTap: () {
          setState(() => yes = v == 1);
          context.read<RiskAssessmentBloc>().add(
              SaveAnswerEvent(widget.question.variableNumber, v.toString()));
          widget.onSave?.call(widget.question.variableNumber, v.toString());
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: yes == null
                    ? AppColors.headerBlueColor
                    : (yes == (v == 1) ? yesColor : AppColors.headerBlueColor),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.6),
                boxShadow: [
                  if (yes != null && yes == (v == 1))
                    const BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                v.toString(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10)),
          ],
        ),
      );
}

class _RatingCircle extends StatefulWidget {
  final QuestionModel question;
  final String? savedAnswer;
  final Future<void> Function(String, dynamic)? onSave;

  const _RatingCircle({
    required this.question,
    this.savedAnswer,
    this.onSave,
  });

  @override
  State<_RatingCircle> createState() => _RatingCircleState();
}

class _RatingCircleState extends State<_RatingCircle>
    with SingleTickerProviderStateMixin {
  int? sel;
  late AnimationController _anim;

  final List<int> scale = [4, 3, 2, 1, 0];
  static const List<String> labels = [
    'Strongly\nAgree',
    'Highly\nAgree',
    'Some\nAgree',
    'Agree\n',
    'Not\nAgree'
  ];
  static const List<Color> colors = [
    Color(0xFF22c55e),
    Color(0xFFa3e635),
    Color(0xFFfbbf24),
    Color(0xFFf97316),
    Color(0xFFef4444),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.savedAnswer != null && widget.savedAnswer!.isNotEmpty) {
      sel = int.tryParse(widget.savedAnswer!);
    }
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      lowerBound: 0.97,
      upperBound: 1.13,
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _select(int value) {
    setState(() => sel = value);
    _anim.forward(from: 0.97);
    widget.onSave?.call(widget.question.variableNumber, value.toString());
    context
        .read<RiskAssessmentBloc>()
        .add(SaveAnswerEvent(widget.question.variableNumber, value.toString()));
  }

  Color _circleColor(int idx, bool selected) =>
      selected ? colors[idx] : colors[idx].withOpacity(0.25);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: {'10. Change in the season cycle during last 10-15 years'}
                .contains(widget.question.questionText.toString())
                ? AppColors.yellowColor
                : {
              '44.1',
              '44.3',
              '44.5',
              '44.7',
              '44.9',
              '44.11',
              '44.13',
              '44.15',
              '45.1',
              '45.3',
              '45.5',
              '45.7',
              '46.1',
              '46.3'
            }.contains(widget.question.variableNumber.toString())
                ? AppColors.greenColor
                : AppColors.yellowColor,
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: Text(
            widget.question.questionText,
            style: TextStyle(
              color: {'10. Change in the season cycle during last 10-15 years'}
                  .contains(widget.question.questionText.toString())
                  ? AppColors.blackColor
                  : {
                '44.1',
                '44.3',
                '44.5',
                '44.7',
                '44.9',
                '44.11',
                '44.13',
                '44.15',
                '45.1',
                '45.3',
                '45.5',
                '45.7'
              }.contains(widget.question.variableNumber.toString())
                  ? AppColors.whiteColor
                  : AppColors.blackColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          height: 90,
          margin: const EdgeInsets.only(bottom: 16, top: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.blueGrey, width: 1.4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(scale.length, (i) {
              final int val = scale[i];
              final bool isSelected = sel == val;
              return GestureDetector(
                onTap: () => _select(val),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _anim,
                      builder: (_, child) =>
                          Transform.scale(
                            scale: isSelected ? _anim.value : 1.0,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _circleColor(i, isSelected),
                                border: Border.all(
                                  color:
                                  isSelected ? colors[i] : Colors.grey.shade300,
                                  width: isSelected ? 3.0 : 1.3,
                                ),
                                boxShadow: isSelected
                                    ? [
                                  BoxShadow(
                                    color: colors[i].withOpacity(0.32),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                                    : [],
                              ),
                              alignment: Alignment.center,
                              child: isSelected
                                  ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    val.toString(),
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                  Positioned(
                                    right: 5,
                                    top: 4,
                                    child: Icon(Icons.check_circle_rounded,
                                        size: 13,
                                        color: colors[i].withOpacity(0.78)),
                                  ),
                                ],
                              )
                                  : Text(
                                val.toString(),
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 44,
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isSelected ? colors[i] : Colors.grey[700],
                          fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                          height: 1.13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _DashLine extends StatelessWidget {
  const _DashLine();

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (_, c) {
        const dashW = 4.0,
            dashS = 3.0;
        final count = (c.maxWidth / (dashW + dashS)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
                (_) =>
                Container(width: dashW, height: 1.6, color: Colors.blueGrey),
          ),
        );
      });
}

class _ExtraAdaptationCard extends StatefulWidget {
  const _ExtraAdaptationCard();

  @override
  State<_ExtraAdaptationCard> createState() => _ExtraAdaptationCardState();
}

class _ExtraAdaptationCardState extends State<_ExtraAdaptationCard> {
  final ctrl = TextEditingController();

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: const Color(0xFF00838f),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Text(
              '⚙️  Add any OTHER adaptation strategy (optional)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            height: 70.h,
            margin: EdgeInsets.only(bottom: 20.h),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.blueGrey, width: 1.4),
            ),
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            child: TextField(
              controller: ctrl,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: 'your adaptation here ....',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (txt) =>
                  context.read<RiskAssessmentBloc>().add(
                    SaveAnswerEvent('46.99', txt),
                  ),
            ),
          ),
        ],
      );
}

Widget _bar(String t, Color c, {Color textColor = Colors.white}) =>
    Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: c,
        border: Border.all(color: Colors.black, width: 1.8),
      ),
      child: Text(
        t,
        style: TextStyle(
          color: textColor,
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
        maxLines: null,
        overflow: TextOverflow.visible,
        softWrap: true,
      ),
    );

Widget _line(String q, Color barColor, {required Widget child}) =>
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
          decoration: BoxDecoration(
              color: barColor,
              border: Border.all(color: Colors.black, width: 1.5)),
          child: AppText(
              text: q,
              color: barColor == AppColors.yellowColor
                  ? Colors.black
                  : Colors.white,
              textSize: 14.sp,
              fontWeight: FontWeight.w700),
        ),
        Container(
          height: 34.h,
          margin: EdgeInsets.only(bottom: 14.h),
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.blueGrey, width: 1.4)),
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          alignment: Alignment.centerLeft,
          child: child,
        ),
      ],
    );
