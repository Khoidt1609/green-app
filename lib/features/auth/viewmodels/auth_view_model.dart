import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      await _authService.signIn(email: email, password: password);
      state = const AsyncData(null);
      return null;
    } on AuthException catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return e.message;
    }
  }

  Future<String?> loginWithGoogle() async {
    state = const AsyncLoading();

    try {
      await _authService.signInWithGoogle();
      state = const AsyncData(null);
      return null;
    } on AuthException catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return e.message;
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
