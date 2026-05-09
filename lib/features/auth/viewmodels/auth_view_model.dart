import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_providers.dart';
import '../../../core/services/auth_service.dart';

final authViewModelProvider =
    NotifierProvider<AuthViewModel, AsyncValue<void>>(
      AuthViewModel.new,
    );

class AuthViewModel extends Notifier<AsyncValue<void>> {
  late final AuthService _authService;

  @override
  AsyncValue<void> build() {
    _authService = ref.read(authServiceProvider);
    return const AsyncData(null);
  }

  // =========================================================
  // LOGIN
  // =========================================================

  Future<String?> login({
    required String emailOrUsername,
    required String password,
  }) async {
    if (state.isLoading) return 'Đang xử lý, vui lòng chờ.';

    state = const AsyncLoading();

    try {
      await _authService.signIn(
        emailOrUsername: emailOrUsername.trim(),
        password: password.trim(),
      );

      state = const AsyncData(null);

      return null;
    } on AuthException catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return e.message;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return 'Đăng nhập thất bại.';
    }
  }

  // =========================================================
  // GOOGLE LOGIN
  // =========================================================

  Future<String?> loginWithGoogle() async {
    if (state.isLoading) return 'Đang xử lý, vui lòng chờ.';

    state = const AsyncLoading();

    try {
      await _authService.signInWithGoogle();

      state = const AsyncData(null);

      return null;
    } on AuthException catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return e.message;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return 'Google Sign-In thất bại.';
    }
  }

  // =========================================================
  // REGISTER
  // =========================================================

  Future<String?> register({
    required String email,
    required String password,
    required String displayName,
    required String username,
    String city = '',
    String district = '',
  }) async {
    if (state.isLoading) return 'Đang xử lý, vui lòng chờ.';

    state = const AsyncLoading();

    try {
      await _authService.signUp(
        email: email.trim(),
        password: password.trim(),
        displayName: displayName.trim(),
        username: username.trim(),
        city: city.trim(),
        district: district.trim(),
      );

      state = const AsyncData(null);

      return null;
    } on AuthException catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return e.message;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return 'Đăng ký thất bại.';
    }
  }

  // =========================================================
  // FORGOT PASSWORD
  // =========================================================

  Future<String?> forgotPassword({
    required String emailOrUsername,
  }) async {
    if (state.isLoading) return 'Đang xử lý, vui lòng chờ.';

    state = const AsyncLoading();

    try {
      await _authService.sendPasswordResetEmail(
        emailOrUsername.trim(),
      );

      state = const AsyncData(null);

      return null;
    } on AuthException catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return e.message;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return 'Không thể gửi email khôi phục.';
    }
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<String?> logout() async {
    if (state.isLoading) return 'Đang xử lý, vui lòng chờ.';

    state = const AsyncLoading();

    try {
      await _authService.signOut();

      state = const AsyncData(null);

      return null;
    } on AuthException catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return e.message;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return 'Đăng xuất thất bại.';
    }
  }

  // =========================================================
  // DELETE ACCOUNT
  // =========================================================

  Future<String?> deleteAccount() async {
    if (state.isLoading) return 'Đang xử lý, vui lòng chờ.';

    state = const AsyncLoading();

    try {
      await _authService.deleteAccount();

      state = const AsyncData(null);

      return null;
    } on AuthException catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return e.message;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return 'Xóa tài khoản thất bại.';
    }
  }

  // =========================================================
  // RESET STATE
  // =========================================================

  void resetState() {
    state = const AsyncData(null);
  }

  // =========================================================
  // GETTERS
  // =========================================================

  bool get isLoading => state.isLoading;

  bool get hasError => state.hasError;

  String? get errorMessage {
    final error = state.error;

    if (error is AuthException) {
      return error.message;
    }

    return null;
  }
}