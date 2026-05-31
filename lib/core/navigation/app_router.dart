import 'package:go_router/go_router.dart';
import '../services/auth_notifier.dart';
import 'bottom_nav.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/home/presentation/dashboard_screen.dart';
import '../../features/mood_journal/presentation/mood_list_screen.dart';
import '../../features/mood_journal/presentation/mood_add_screen.dart';
import '../../features/mood_journal/presentation/mood_edit_screen.dart';
import '../../features/mood_journal/domain/mood_model.dart';
import '../../features/workout/presentation/workout_list_screen.dart';
import '../../features/workout/presentation/workout_add_screen.dart';
import '../../features/daily_goals/presentation/goals_list_screen.dart';
import '../../features/daily_goals/presentation/goal_add_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  refreshListenable: authNotifier,
  redirect: (context, state) {
    final isLoggedIn = authNotifier.isLoggedIn;
    final isAuthRoute =
        state.matchedLocation.startsWith('/login') ||
        state.matchedLocation.startsWith('/register') ||
        state.matchedLocation.startsWith('/forgot-password');

    if (!isLoggedIn && !isAuthRoute) return '/login';
    if (isLoggedIn && isAuthRoute) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),

    ShellRoute(
      builder: (context, state, child) => AppBottomNav(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/mood',
          builder: (context, state) => const MoodListScreen(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const MoodAddScreen(),
            ),
            GoRoute(
              path: 'edit',
              builder: (context, state) => MoodEditScreen(
                entry: state.extra as MoodModel,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/workout',
          builder: (context, state) => const WorkoutListScreen(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const WorkoutAddScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/goals',
          builder: (context, state) => const GoalsListScreen(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const GoalAddScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);
