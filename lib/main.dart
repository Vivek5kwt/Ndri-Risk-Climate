import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';

import 'config/router/go_router.dart';
import 'data/services/location_state.dart';
import 'firebase_options.dart';
import 'logic/risk_assessment/bloc/risk_assessment_bloc.dart';
import 'logic/risk_assessment/bloc/risk_assessment_event.dart';
import 'logic/splash/bloc/splash_bloc.dart';
import 'logic/splash/bloc/splash_event.dart';
import 'package:pdf/widgets.dart' as pw;

Future<void> main() async {
  print('pw.CustomPainter   ${pw.CustomPainter}');
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FlutterDownloader.initialize(
    debug: true,
    ignoreSsl: true,
  );

  await Permission.storage.request();

  final locCubit = LocationCubit();

  runApp(MyApp(locationCubit: locCubit));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.locationCubit});

  final LocationCubit locationCubit;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: locationCubit),
        BlocProvider(create: (_) => SplashBloc()..add(AppStarted())),
        BlocProvider(
            create: (_) => RiskAssessmentBloc()..add(LoadQuestionsEvent())),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) => MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
        ),
      ),
    );
  }
}
