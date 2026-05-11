import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';import 'package:cloud_firestore/cloud_firestore.dart'; // Import thêm thư viện này

import '../../../core/providers/auth_providers.dart';
import '../../../core/services/auth_service.dart';

final authViewModelProvider = NotifierProvider<AuthViewModel, AsyncValue<void>>(
  AuthViewModel.new,
);

class AuthViewModel extends Notifier<AsyncValue<void>> {
  late final AuthService _authService;

  @override
  AsyncValue<void> build() {
    _authService = ref.watch(authServiceProvider);
    return const AsyncData(null);
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    try {
      // 1. Cho phép AuthService đăng nhập Firebase Auth
      await _authService.signIn(email: email, password: password);

      // 2. --- TRẠM KIỂM SOÁT: KIỂM TRA TÀI KHOẢN CÓ BỊ KHÓA KHÔNG ---
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final role = doc.data()?['role'];
          if (role == 'blocked') {
            // Nếu bị khóa -> Ép đăng xuất ngay lập tức
            await FirebaseAuth.instance.signOut();
            state = const AsyncData(null);
            return 'Tài khoản của bạn đã bị khóa. Vui lòng liên hệ Admin!';
          }
        }
      }
      // -------------------------------------------------------------

      state = const AsyncData(null);
      return null;
    } on AuthException catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return e.message;
    } catch (e) {
      state = const AsyncData(null);
      return 'Lỗi đăng nhập hệ thống: $e';
    }
  }

  Future<String?> loginWithGoogle() async {
    state = const AsyncLoading();

    try {
      // 1. Cho phép AuthService đăng nhập Google
      await _authService.signInWithGoogle();

      // 2. --- TRẠM KIỂM SOÁT DÀNH CHO GOOGLE ---
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final role = doc.data()?['role'];
          if (role == 'blocked') {
            // Nếu bị khóa -> Ép đăng xuất ngay lập tức
            await FirebaseAuth.instance.signOut();
            state = const AsyncData(null);
            return 'Tài khoản Google này đã bị hệ thống khóa!';
          }
        }
      }
      // -----------------------------------------

      state = const AsyncData(null);
      return null;
    } on AuthException catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return e.message;
    } catch (e) {
      state = const AsyncData(null);
      return 'Lỗi đăng nhập Google: $e';
    }
  }

  Future<String?> forgotPassword({required String email}) async {
    state = const AsyncLoading();

    try {
      await _authService.sendPasswordResetEmail(email: email);
      state = const AsyncData(null);
      return null;
    } on AuthException catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return e.message;
    }
  }

  Future<String?> register({
    required String email,
    required String password,
    required String fullName,
    required String username,
    required String location,
  }) async {
    state = const AsyncLoading();

    try {
      await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        username: username,
        location: location,
      );
      state = const AsyncData(null);
      return null;
    } on AuthException catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return e.message;
    }
  }
}