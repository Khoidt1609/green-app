// //CODE TEST GIAO DIEN DANG NHAP
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'features/auth/views/onboarding_screen.dart';
import 'router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: GreenStepApp()));
}

class GreenStepApp extends StatelessWidget {
  const GreenStepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GreenStep',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi'),
        Locale('en'),
      ],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: const OnboardingScreen(),
    );
  }
}

//CODE TEST GIAO DIEN NHIEM VU
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'core/constants/app_colors.dart';
// import 'features/tasks/views/task_list_screen.dart';
//
// void main() async {
//   // Đảm bảo các ràng buộc của Flutter đã được khởi tạo
//   WidgetsFlutterBinding.ensureInitialized();
//   // Khởi tạo Firebase trước khi chạy App
//   await Firebase.initializeApp();
//   runApp(
//     // Bọc toàn bộ ứng dụng trong ProviderScope để Riverpod hoạt động
//     const ProviderScope(
//       child: GreenstepApp(),
//     ),
//   );
// }
// class GreenstepApp extends StatelessWidget {
//   const GreenstepApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Greenstep',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         useMaterial3: true,
//         brightness: Brightness.light,
//         scaffoldBackgroundColor: AppColors.backgroundLight,
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: AppColors.primaryGreen,
//           background: AppColors.backgroundLight,
//           surface: AppColors.surfaceLight,
//         ),
//
//         fontFamily: 'Roboto',
//       ),
//       home: const TaskListScreen(),
//     );
//   }
// }