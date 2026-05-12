import 'package:flutter/material.dart';
import 'package:green_app/features/admin/views/admin_main_screen.dart';

import '../features/auth/views/login_screen.dart';
import '../features/auth/views/onboarding_screen.dart';
import '../features/auth/views/register_screen.dart';
import '../features/app_shell/app_shell.dart';
import '../features/green_map/views/green_map_screen.dart';
import '../features/leaderboard/views/leaderboard_screen.dart';
import '../features/profile/views/profile_screen.dart';
import '../features/tasks/views/task_list_screen.dart';
import '../features/reward/views/reward_wallet_screen.dart'; // FIX: thêm import

class AppRouter {
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String app = '/app';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String tasks = '/tasks';
  static const String leaderboard = '/leaderboard';
  static const String greenMap = '/green-map';
  static const String admin = '/admin';
  static const String rewardWallet = '/reward-wallet';
  static const String admin = '/admin';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return MaterialPageRoute<void>(
          builder: (_) => const OnboardingScreen(),
        );
      case register:
        return MaterialPageRoute<void>(
          builder: (_) => const RegisterScreen(),
        );
      case app:
      case home:
        return MaterialPageRoute<void>(
          builder: (_) => const AppShell(),
        );
      case profile:
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileScreen(),
        );
      case tasks:
        return MaterialPageRoute<void>(
          builder: (_) => const TaskListScreen(),
        );
      case leaderboard:
        return MaterialPageRoute<void>(
          builder: (_) => const LeaderboardScreen(),
        );
      case greenMap:
        return MaterialPageRoute<void>(
          builder: (_) => const GreenMapScreen(),
        );
      case admin:
        return MaterialPageRoute<void>(
          builder: (_) => const AdminMainScreen(),
        );
      // FIX: trỏ về RewardWalletScreen thay vì AppShell
      case rewardWallet:
        return MaterialPageRoute<void>(
          builder: (_) => const RewardWalletScreen(),
        );
      case admin:
        return MaterialPageRoute(builder: (_) => const AdminMainScreen());
      case login:
      default:
        // return MaterialPageRoute<void>(builder: (_) => const AdminMainScreen());
        return MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(),
        );
    }
  }
}