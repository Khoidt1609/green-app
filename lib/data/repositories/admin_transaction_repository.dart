import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/transaction_model.dart';

class AdminTransactionRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Lấy danh sách lệnh rút tiền đang chờ
  Stream<List<TransactionModel>> getPendingWithdrawals() {

    return _db
        .collection('transactions')
        .where('type', isEqualTo: 'redeem') // Chỉ lấy loại đổi thưởng
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => TransactionModel.fromDocument(doc))
              .toList(),
        );
  }

  // Cập nhật trạng thái thành Đã hoàn thành
  Future<void> completeTransaction(String txId) async {
    await _db.collection('transactions').doc(txId).update({
      'status': 'completed',
    });
    // Sau khi cập nhật để tự động bắn Push Notification về máy User, làm sau.
  }

  // Hàm Từ chối và Hoàn điểm
  Future<void> rejectAndRefund(String txId, String userId, int pointsToRefund) async {
    final txRef = _db.collection('transactions').doc(txId);
    final userRef = _db.collection('users').doc(userId);

    await _db.runTransaction((transaction) async {
      // Đọc dữ liệu User để lấy số điểm hiện tại
      DocumentSnapshot userSnap = await transaction.get(userRef);
      if (!userSnap.exists) throw Exception("User không tồn tại");

      int currentPoints = userSnap.get('currentPoints') ?? 0;

      // Cập nhật trạng thái giao dịch
      transaction.update(txRef, {'status': 'rejected'});

      // Cộng lại điểm cho User
      transaction.update(userRef, {'currentPoints': currentPoints + pointsToRefund});
    });
  }
}
