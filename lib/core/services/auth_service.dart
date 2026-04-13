import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthException implements Exception {
  AuthException(this.message);

  final String message;
}

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _authOverride = auth,
        _firestoreOverride = firestore;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    User? createdUser;

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      createdUser = credential.user;
      if (createdUser == null) {
        throw AuthException('Không thể tạo tài khoản. Vui lòng thử lại.');
      }

      await _firestore.collection('users').doc(createdUser.uid).set({
        'uid': createdUser.uid,
        'email': createdUser.email,
        'createdAt': FieldValue.serverTimestamp(),
        'provider': 'email_password',
      });
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } on FirebaseException {
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {
          // Best effort rollback to keep auth/profile data consistent.
        }
      }
      throw AuthException('Tạo tài khoản thành công nhưng lưu hồ sơ thất bại.');
    }
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email đã được đăng ký.';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu quá yếu, hãy dùng ít nhất 6 ký tự.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng.';
      case 'network-request-failed':
        return 'Lỗi mạng. Vui lòng kiểm tra Internet.';
      default:
        return 'Đã xảy ra lỗi xác thực. Vui lòng thử lại.';
    }
  }
}
