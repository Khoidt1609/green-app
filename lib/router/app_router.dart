// lib/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:green_app/features/reward/views/reward_wallet_screen.dart';

// === Auth ===
import '../features/auth/views/login_screen.dart';
import '../features/auth/views/onboarding_screen.dart';
import '../features/auth/views/register_screen.dart';

// === Main Features ===
import '../features/home/views/home_screen.dart';
import '../features/profile/views/profile_screen.dart';
import '../features/tasks/views/task_list_screen.dart';
import '../features/leaderboard/views/leaderboard_screen.dart';     // ← Mới thêm
import '../features/green_map/views/green_map_screen.dart';               // ← Mới thêm (bạn kiểm tra lại tên file)

class AppRouter {
  // ==================== ROUTE NAMES ====================
  static const String onboarding = '/onboarding';
  static const String login       = '/login';
  static const String register    = '/register';
  static const String home        = '/home';
  static const String profile     = '/profile';
  static const String tasks       = '/tasks';
  static const String leaderboard = '/leaderboard';
  static const String map         = '/map';
  static const String store = '/store';

  

  // ==================== ON GENERATE ROUTE ====================
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth routes
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      // Main app routes
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case tasks:
        return MaterialPageRoute(builder: (_) => const TaskListScreen());

      case leaderboard:
        return MaterialPageRoute(builder: (_) => const LeaderboardScreen());

      case map:
        return MaterialPageRoute(builder: (_) => const GreenMapScreen()); 
        
      case store:
        return MaterialPageRoute(builder: (_) => const RewardWalletScreen());  

      // Default route
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}