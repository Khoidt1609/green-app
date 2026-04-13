import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

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

  Future<String?> login({required String email, required String password}) async {
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

  Future<String?> register({required String email, required String password}) async {
    state = const AsyncLoading();

    try {
      await _authService.signUp(email: email, password: password);
      state = const AsyncData(null);
      return null;
    } on AuthException catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return e.message;
    }
  }
}
