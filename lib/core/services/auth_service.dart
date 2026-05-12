import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _googleSignIn =
           googleSignIn ??
           GoogleSignIn(
             scopes: ['email'],
           );

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final GoogleSignIn _googleSignIn;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // =========================================================
  // SIGN UP
  // =========================================================

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    required String username,
    String city = '',
    String district = '',
  }) async {
    User? createdUser;

    try {
      final normalizedEmail = email.trim().toLowerCase();
      final normalizedUsername = username.trim().toLowerCase();

      // Check username exists
      final usernameQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: normalizedUsername)
          .limit(1)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        throw AuthException('Tên người dùng đã tồn tại.');
      }

      final credential = await _auth
          .createUserWithEmailAndPassword(
            email: normalizedEmail,
            password: password,
          )
          .timeout(const Duration(seconds: 30));

      createdUser = credential.user;

      if (createdUser == null) {
        throw AuthException('Không thể tạo tài khoản.');
      }

      await createdUser.updateDisplayName(displayName.trim());

      final signUpPayload = {
        'uid': createdUser.uid,
        'displayName': displayName.trim(),
        'username': normalizedUsername,
        'email': normalizedEmail,
        'avatarUrl': '',
        'provider': 'email_password',

        // Address
        'address': {
          'city': city.trim(),
          'district': district.trim(),
        },

        // Points
        'totalPoints': 0,
        'currentPoints': 0,
        'weekPoints': 0,
        'monthPoints': 0,

        // Role
        'role': 'user',

        // Bank info
        'bankInfo': null,

        // Timestamps
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      print('AUTH_SERVICE signUp uid=${createdUser.uid} payload=$signUpPayload');

      await _firestore.collection('users').doc(createdUser.uid).set(signUpPayload);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } on TimeoutException {
      throw AuthException('Kết nối quá lâu. Vui lòng thử lại.');
    } on FirebaseException {
      // rollback
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {}
      }

      throw AuthException('Tạo tài khoản thành công nhưng lưu dữ liệu thất bại.');
    }
  }

  // =========================================================
  // SIGN IN
  // =========================================================

  Future<void> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      final resolvedEmail = await _resolveLoginEmail(emailOrUsername);

      await _auth
          .signInWithEmailAndPassword(
            email: resolvedEmail,
            password: password,
          )
          .timeout(const Duration(seconds: 30));
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } on TimeoutException {
      throw AuthException('Đăng nhập quá lâu. Kiểm tra Internet.');
    }
  }

  // =========================================================
  // GOOGLE SIGN IN
  // =========================================================

  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();

        final credential = await _auth
            .signInWithPopup(provider)
            .timeout(const Duration(seconds: 30));

        final user = credential.user;

        if (user == null) {
          throw AuthException('Không thể đăng nhập Google.');
        }

        await _ensureGoogleUserData(user);

        return;
      }

      final googleUser = await _googleSignIn.signIn().timeout(
        const Duration(seconds: 30),
      );

      if (googleUser == null) {
        throw AuthException('Bạn đã hủy đăng nhập Google.');
      }

      final googleAuth = await googleUser.authentication;

      final authCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final credential = await _auth.signInWithCredential(authCredential);

      final user = credential.user;

      if (user == null) {
        throw AuthException('Không thể đăng nhập Google.');
      }

      await _ensureGoogleUserData(user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } on PlatformException catch (e) {
      if (e.code == '10' || e.code == 'sign_in_failed') {
        throw AuthException(
          'Google Sign-In chưa cấu hình đúng SHA-1/SHA-256.',
        );
      }

      throw AuthException('Google Sign-In thất bại.');
    } on TimeoutException {
      throw AuthException('Google Sign-In quá lâu.');
    }
  }

  // =========================================================
  // RESET PASSWORD
  // =========================================================

  Future<void> sendPasswordResetEmail(String emailOrUsername) async {
    try {
      final resolvedEmail = await _resolveLoginEmail(emailOrUsername);

      await _auth.sendPasswordResetEmail(email: resolvedEmail);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapPasswordResetError(e));
    }
  }

  // =========================================================
  // SIGN OUT
  // =========================================================

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    await _auth.signOut();
  }

  // =========================================================
  // DELETE ACCOUNT
  // =========================================================

  Future<void> deleteAccount() async {
    final user = currentUser;

    if (user == null) {
      throw AuthException('Bạn chưa đăng nhập.');
    }

    try {
      // delete avatar
      final profile = await getCurrentUserProfile();

      final avatarUrl = profile?['avatarUrl'];

      if (avatarUrl != null && avatarUrl.toString().isNotEmpty) {
        try {
          await _storage.refFromURL(avatarUrl).delete();
        } catch (_) {}
      }

      // delete firestore profile
      await _firestore.collection('users').doc(user.uid).delete();

      // delete auth
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthException(
          'Vui lòng đăng nhập lại trước khi xóa tài khoản.',
        );
      }

      throw AuthException(_mapFirebaseAuthError(e));
    }
  }

  // =========================================================
  // USER PROFILE
  // =========================================================

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = currentUser;

    if (user == null) {
      return null;
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    return snapshot.data();
  }

  Future<void> updateProfile({
    required String displayName,
    required String username,
    required String city,
    required String district,
    String? avatarUrl,
  }) async {
    final user = currentUser;

    if (user == null) {
      throw AuthException('Bạn chưa đăng nhập.');
    }

    final normalizedUsername = username.trim().toLowerCase();

    final existingUsername = await _firestore
        .collection('users')
        .where('username', isEqualTo: normalizedUsername)
        .limit(1)
        .get();

    final isTaken =
        existingUsername.docs.isNotEmpty &&
        existingUsername.docs.first.id != user.uid;

    if (isTaken) {
      throw AuthException('Tên người dùng đã tồn tại.');
    }

    await user.updateDisplayName(displayName.trim());

    final updatePayload = {
      'displayName': displayName.trim(),
      'username': normalizedUsername,
      'avatarUrl': avatarUrl ?? '',
      'address': {
        'city': city.trim(),
        'district': district.trim(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    };

    print('AUTH_SERVICE updateProfile uid=${user.uid} payload=$updatePayload');

    await _firestore.collection('users').doc(user.uid).set(
      updatePayload,
      SetOptions(merge: true),
    );
  }

  // =========================================================
  // AVATAR
  // =========================================================

  Future<String> uploadCurrentUserAvatar(String imagePath) async {
    final user = currentUser;

    if (user == null) {
      throw AuthException('Bạn chưa đăng nhập.');
    }

    final file = File(imagePath);

    if (!file.existsSync()) {
      throw AuthException('Không tìm thấy ảnh.');
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
      throw AuthException('Upload ảnh thất bại.');
    }
  }

  // =========================================================
  // PRIVATE METHODS
  // =========================================================

  Future<String> _resolveLoginEmail(String input) async {
    final value = input.trim();

    if (value.contains('@')) {
      return value;
    }

    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: value.toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return value;
    }

    return query.docs.first.data()['email'] ?? value;
  }

  Future<void> _ensureGoogleUserData(User user) async {
    final ref = _firestore.collection('users').doc(user.uid);

    final snapshot = await ref.get();

    if (snapshot.exists) {
      await ref.set({
        'updatedAt': FieldValue.serverTimestamp(),
        'avatarUrl': user.photoURL ?? '',
      }, SetOptions(merge: true));

      return;
    }

    await ref.set({
      'uid': user.uid,
      'displayName': user.displayName ?? 'Người dùng',
      'username':
          _buildUsernameFromEmail(user.email) ??
          user.uid.substring(0, 8),

      'email': user.email ?? '',
      'avatarUrl': user.photoURL ?? '',
      'provider': 'google',

      'address': {
        'city': '',
        'district': '',
      },

      'totalPoints': 0,
      'currentPoints': 0,
      'weekPoints': 0,
      'monthPoints': 0,

      'role': 'user',

      'bankInfo': null,

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  String? _buildUsernameFromEmail(String? email) {
    final normalized = email?.trim();

    if (normalized == null ||
        normalized.isEmpty ||
        !normalized.contains('@')) {
      return null;
    }

    final localPart = normalized.split('@').first;

    final username = localPart
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '')
        .toLowerCase();

    if (username.isEmpty) {
      return null;
    }

    return username;
  }

  // =========================================================
  // ERROR HANDLING
  // =========================================================

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email đã được sử dụng.';

      case 'invalid-email':
        return 'Email không hợp lệ.';

      case 'weak-password':
        return 'Mật khẩu quá yếu.';

      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng.';

      case 'user-disabled':
        return 'Tài khoản đã bị khóa.';

      case 'too-many-requests':
        return 'Bạn thao tác quá nhiều lần.';

      case 'network-request-failed':
        return 'Lỗi mạng. Kiểm tra Internet.';

      default:
        return 'Đã xảy ra lỗi xác thực.';
    }
  }

  String _mapPasswordResetError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email không hợp lệ.';

      case 'user-not-found':
        return 'Email chưa được đăng ký.';

      case 'too-many-requests':
        return 'Bạn thao tác quá nhiều lần.';

      case 'network-request-failed':
        return 'Lỗi mạng.';

      default:
        return 'Không thể gửi email khôi phục.';
    }
  }
}