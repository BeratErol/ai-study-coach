import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'global_navigator.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/shell_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/lessons_screen.dart';
import '../screens/gelisimim_screen.dart';
import '../screens/denemeler_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/lesson_detail_screen.dart';
import '../screens/task_create_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/study_session_screen.dart';
import '../models/study_task.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login',       builder: (ctx, s) => const LoginScreen()),
      GoRoute(path: '/register',    builder: (ctx, s) => const RegisterScreen()),
      GoRoute(path: '/onboarding',  builder: (ctx, s) => const OnboardingScreen()),
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(path: '/dashboard',  builder: (ctx, s) => const DashboardScreen()),
          GoRoute(path: '/gelisimim',  builder: (ctx, s) => const GelisimimScreen()),
          GoRoute(path: '/denemeler',  builder: (ctx, s) => const DenemeScreen()),
          GoRoute(path: '/profile',    builder: (ctx, s) => const ProfileScreen()),
          GoRoute(path: '/lessons',    builder: (ctx, s) => const LessonsScreen()),
          GoRoute(
            path: '/lessons/:id',
            builder: (ctx, state) {
              final lesson = state.extra as Map<String, dynamic>? ?? {};
              return LessonDetailScreen(lesson: lesson);
            },
          ),
          GoRoute(path: '/task/new', builder: (ctx, s) => const TaskCreateScreen()),
        ],
      ),
      GoRoute(
        path: '/study-session',
        builder: (ctx, state) {
          final task = state.extra as StudyTask?;
          if (task == null) return const DashboardScreen();
          return StudySessionScreen(task: task);
        },
      ),
    ],
  );
});
