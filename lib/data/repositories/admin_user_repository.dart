import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/submission_model.dart';
import '../models/transaction_model.dart';

class AdminUserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // Cập nhật vai trò (Role) của người dùng
  Future<void> updateUserRole(String uid, String newRole) async {
    await _db.collection('users').doc(uid).update({
      'role': newRole,
    });
  }
  // lib/data/repositories/admin_user_repository.dart

  // Lấy lịch sử nộp bài của 1 user cụ thể (Sắp xếp mới nhất lên đầu)
  Stream<List<SubmissionModel>> getUserSubmissions(String userId) {
    return _db
        .collection('submissions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => SubmissionModel.fromDocument(doc)).toList());
  }

  // Lấy lịch sử giao dịch của 1 user cụ thể
  Stream<List<TransactionModel>> getUserTransactions(String userId) {
    return _db
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => TransactionModel.fromDocument(doc)).toList());
  }

  // Lấy toàn bộ danh sách người dùng (Realtime)
  Stream<List<UserModel>> getAllUsers() {
    return _db
        .collection('users')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList());
  }

  // Cập nhật trạng thái Hoạt động/Bị khóa của người dùng
  Future<void> toggleUserStatus(String uid, bool currentStatus) async {
    await _db.collection('users').doc(uid).update({
      'isActive': !currentStatus,
    });
  }
}