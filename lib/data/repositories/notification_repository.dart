// lib/data/repositories/notification_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. DÀNH CHO ADMIN: Hàm gửi thông báo
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
  }) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 2. DÀNH CHO USER: Lấy danh sách thông báo theo thời gian thực
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _db.collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => NotificationModel.fromDocument(doc)).toList());
  }

  // 3. Đánh dấu 1 thông báo là "Đã đọc"
  Future<void> markAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  // 4. Đánh dấu "Đã đọc tất cả"
  Future<void> markAllAsRead(String userId) async {
    final batch = _db.batch();
    final unreadDocs = await _db.collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in unreadDocs.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // 5. Xóa tất cả thông báo "Đã đọc"
  Future<void> deleteReadNotifications(String userId) async {
    final batch = _db.batch();
    final readDocs = await _db.collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: true)
        .get();

    for (var doc in readDocs.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // 6. Xóa một thông báo cụ thể theo ID
  Future<void> deleteNotification(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).delete();
  }
}