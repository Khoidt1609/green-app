// //CODE TEST GIAO DIEN DANG NHAP
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';

import 'features/auth/views/login_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: GreenStepApp()));
}

class GreenStepApp extends StatelessWidget {
  const GreenStepApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.outfitTextTheme();

    return MaterialApp(
      title: 'GreenStep',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF1B5E20),
          secondary: const Color(0xFF66BB6A),
          surface: const Color(0xFFF4FBF4),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4FBF4),
        textTheme: textTheme,
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.4),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            padding: const EdgeInsets.symmetric(vertical: 15),
            textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            backgroundColor: const Color(0xFF1B5E20),
          ),
        ),
      ),
      home: const LoginScreen(),
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