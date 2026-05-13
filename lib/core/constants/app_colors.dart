import 'package:flutter/material.dart';

class AppColors {
  // Màu chủ đạo - Xanh lá cây sáng vừa
  static const Color primaryGreen = Color(0xFF2CC185);
  static const Color primaryDarkGreen = Color(0xFF22996B);
  static const Color primaryContainer = Color(0xFF7FE2B9);
  static const Color primaryFixed = Color(0xFFB9F3D6);
  static const Color primaryFixedDim = Color(0xFF59D59A);

  // Màu phụ - Tông màu đất và trung tính
  static const Color earthyBrown = Color(0xFF8D6E63);
  static const Color accentOrange = Color(0xFFFF9800); // Dùng cho các nút quan trọng hoặc cảnh báo

  // Màu nền & bề mặt (Light Mode)
  static const Color backgroundLight = Color(0xFFF4FBF8);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceMutedLight = Color(0xFFEAF7F1);
  static const Color borderLight = Color(0xFFCDE8DB);

  // Màu nền & bề mặt (Dark Mode)
  static const Color backgroundDark = Color(0xFF101714);
  static const Color surfaceDark = Color(0xFF18211D);
  static const Color surfaceMutedDark = Color(0xFF202B26);
  static const Color borderDark = Color(0xFF2E473D);

  // Trạng thái nhiệm vụ
  static const Color success = Color(0xFF4CAF50);
  static const Color pending = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);

  // Màu Text
  static const Color textPrimary = Color(0xFF2C3E50); // Chữ màu tối
  static const Color textSecondary = Color(0xFF7F8C8D); // Chữ phụ/mờ
  static const Color textOnPrimary = Colors.white;
  static const Color textOnDark = Color(0xFFF3F7F4);

  static const Color textPrimaryLight = Color(0xFFFFFFFF);  // Chữ màu sang
  static const Color textSecondaryLight = Color(0xFFE0E0E0);  // Chữ phụ/mờ
}