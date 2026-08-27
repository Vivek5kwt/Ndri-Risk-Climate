import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'admin/models/survey_submission.dart';
import 'admin/screens/admin_dashboard.dart';
import 'admin/screens/login_screen.dart';
import 'admin/screens/view_submission.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AdminApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final signedIn = FirebaseAuth.instance.currentUser != null;
    final isLoginRoute = state.matchedLocation == '/';
    if (!signedIn && !isLoginRoute) return '/';
    if (signedIn && isLoginRoute) return '/adminDashboard';
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => AdminLoginPage(),
    ),
    GoRoute(
      path: '/adminDashboard',
      builder: (context, state) => AdminDashboard(),
    ),
    GoRoute(
      path: '/viewSubmission',
      builder: (context, state) {
        final sub = state.extra as SurveySubmission;
        return ViewSubmissionPage(submission: sub);
      },
    ),
  ],
);

class AdminApp extends StatelessWidget {
  const AdminApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Climate Risk Calculator Result',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routerConfig: _router,
    );
  }
}
