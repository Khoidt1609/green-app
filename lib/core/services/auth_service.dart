import 'dart:io';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthException implements Exception {
  AuthException(this.message);

  final String message;
}

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    GoogleSignIn? googleSignIn,
  })
      : _authOverride = auth,
        _firestoreOverride = firestore,
        _storageOverride = storage,
        _googleSignInOverride = googleSignIn;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;
  final FirebaseStorage? _storageOverride;
  final GoogleSignIn? _googleSignInOverride;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  FirebaseStorage get _storage => _storageOverride ?? FirebaseStorage.instance;
  GoogleSignIn get _googleSignIn =>
      _googleSignInOverride ?? GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

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

  Future<void> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn
          .signIn()
          .timeout(const Duration(seconds: 30));
      if (googleUser == null) {
        throw AuthException('Đăng nhập Google đã bị hủy.');
      }

      final googleAuth = await googleUser.authentication.timeout(
        const Duration(seconds: 30),
      );
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 30));
      final user = userCredential.user;
      if (user == null) {
        throw AuthException('Không thể đăng nhập bằng Google.');
      }

      await _ensureGoogleProfile(user, googleUser);
    } on TimeoutException {
      throw AuthException(
        'Đăng nhập Google đang quá lâu. Hãy kiểm tra Internet, tài khoản Google trên máy ảo và thử lại.',
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } on PlatformException catch (e) {
      throw AuthException(_mapGoogleSignInError(e));
    } on Exception catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('Đăng nhập bằng Google thất bại. Vui lòng thử lại.');
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String username,
    required String location,
  }) async {
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
        'fullName': fullName.trim(),
        'username': username.trim(),
        'city': '',
        'district': location.trim(),
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

  Future<void> _ensureGoogleProfile(
    User user,
    GoogleSignInAccount googleUser,
  ) async {
    final profileRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await profileRef.get();

    if (snapshot.exists) {
      await profileRef.set({
        'uid': user.uid,
        'email': user.email,
        'fullName': user.displayName ?? googleUser.displayName ?? '',
        'username': _buildUsernameFromEmail(user.email) ?? '',
        'avatarUrl': user.photoURL ?? googleUser.photoUrl,
        'provider': 'google',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    await profileRef.set({
      'uid': user.uid,
      'email': user.email,
      'fullName': user.displayName ?? googleUser.displayName ?? '',
      'username': _buildUsernameFromEmail(user.email) ?? user.uid.substring(0, 8),
      'city': '',
      'district': '',
      'avatarUrl': user.photoURL ?? googleUser.photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'provider': 'google',
    });
  }

  String? _buildUsernameFromEmail(String? email) {
    final normalized = email?.trim();
    if (normalized == null || normalized.isEmpty || !normalized.contains('@')) {
      return null;
    }

    final localPart = normalized.split('@').first;
    return localPart.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '').toLowerCase();
  }

  Future<void> signOut() async {
    await _auth.signOut();

    // Ensure cached Google session is cleared on device/emulator.
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore plugin-specific sign out errors; Firebase signOut already ran.
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) {
      return null;
    }

    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    return snapshot.data();
  }

  Future<List<Map<String, dynamic>>> getCurrentUserTasks({
    int limit = 20,
  }) async {
    final user = currentUser;
    if (user == null) {
      return [];
    }

    QuerySnapshot<Map<String, dynamic>> snapshot;

    try {
      snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .orderBy('updatedAt', descending: true)
          .limit(limit)
          .get();
    } on FirebaseException {
      snapshot = await _firestore
          .collection('tasks')
          .where('uid', isEqualTo: user.uid)
          .limit(limit)
          .get();
    }

    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList(growable: false);
  }

  Future<void> saveCurrentUserProfile({
    required String fullName,
    required String username,
    required String city,
    required String district,
    String? avatarUrl,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw AuthException('Bạn chưa đăng nhập.');
    }

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'fullName': fullName.trim(),
      'username': username.trim(),
      'city': city.trim(),
      'district': district.trim(),
      if (avatarUrl != null && avatarUrl.trim().isNotEmpty)
        'avatarUrl': avatarUrl.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> uploadCurrentUserAvatar(String localImagePath) async {
    final user = currentUser;
    if (user == null) {
      throw AuthException('Bạn chưa đăng nhập.');
    }

    final file = File(localImagePath);
    if (!file.existsSync()) {
      throw AuthException('Không tìm thấy ảnh đã chọn.');
    }

    try {
      final ref = _storage.ref().child(
        'avatars/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return await ref.getDownloadURL();
    } on FirebaseException {
      throw AuthException('Tải ảnh đại diện thất bại. Vui lòng thử lại.');
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

  String _mapGoogleSignInError(PlatformException e) {
    switch (e.code) {
      case 'sign_in_failed':
      case 'ApiException: 10':
      case '10':
        return 'Google Sign-In chưa được cấu hình đúng trên Android. Hãy bật provider Google trong Firebase Auth, thêm SHA-1/SHA-256 cho app và tải lại google-services.json.';
      case 'network_error':
        return 'Lỗi mạng khi đăng nhập Google. Vui lòng kiểm tra Internet.';
      case 'sign_in_canceled':
        return 'Bạn đã hủy đăng nhập Google.';
      default:
        return 'Đăng nhập Google thất bại (${e.code}). Vui lòng thử lại.';
    }
  }
}
