import 'package:flutter/material.dart';

class AppColors {
  // Màu chủ đạo - Xanh lá cây năng động
  static const Color primaryGreen = Color(0xFF2DDA93);
  static const Color primaryDarkGreen = Color(0xFF23B077);

  // Màu phụ - Tông màu đất và trung tính
  static const Color earthyBrown = Color(0xFF8D6E63);
  static const Color accentOrange = Color(0xFFFF9800); // Dùng cho các nút quan trọng hoặc cảnh báo

  // Màu nền & bề mặt (Light Mode)
  static const Color backgroundLight = Color(0xFFF9FBF9);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceMutedLight = Color(0xFFF1F5F1);
  static const Color borderLight = Color(0xFFD9E4DB);

  // Màu nền & bề mặt (Dark Mode)
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceMutedDark = Color(0xFF252C28);
  static const Color borderDark = Color(0xFF34423C);

  // Trạng thái nhiệm vụ
  static const Color success = Color(0xFF4CAF50);
  static const Color pending = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);

  // Màu Text
  static const Color textPrimary = Color(0xFF2C3E50); // Chữ màu tối
  static const Color textSecondary = Color(0xFF7F8C8D); // Chữ phụ/mờ
  static const Color textOnPrimary = Colors.white;
  static const Color textOnDark = Color(0xFFF3F7F4);
}