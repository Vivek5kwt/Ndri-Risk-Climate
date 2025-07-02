import 'package:go_router/go_router.dart';

import '../../admin/models/survey_submission.dart';
import '../../admin/screens/view_submission.dart';
import '../../presentation/screens/disclaimer_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/welcome_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/welcome',
      name: 'welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/disclaimer',
      name: 'disclaimer',
      builder: (context, state) => const DisclaimerScreen(),
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
