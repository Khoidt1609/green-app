import 'package:flutter/material.dart';
import 'package:green_app/features/admin/views/admin_main_screen.dart';

import '../features/auth/views/login_screen.dart';
import '../features/auth/views/onboarding_screen.dart';
import '../features/auth/views/register_screen.dart';
import '../features/home/views/home_screen.dart';
import '../features/profile/views/profile_screen.dart';
import '../features/tasks/views/task_list_screen.dart';

class AppRouter {
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String tasks = '/tasks';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return MaterialPageRoute<void>(
          builder: (_) => const OnboardingScreen(),
        );
      case register:
        return MaterialPageRoute<void>(builder: (_) => const RegisterScreen());
      case home:
        return MaterialPageRoute<void>(builder: (_) => const HomeScreen());
      case profile:
        return MaterialPageRoute<void>(builder: (_) => const ProfileScreen());
      case tasks:
        return MaterialPageRoute<void>(builder: (_) => const TaskListScreen());
      case login:
      default:
        return MaterialPageRoute<void>(builder: (_) => const LoginScreen());
    }
  }
}
