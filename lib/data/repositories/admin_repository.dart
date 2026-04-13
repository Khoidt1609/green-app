import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/submission_model.dart'; // Đảm bảo bạn đã có model này

class AdminRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Lấy danh sách nhiệm vụ đang chờ duyệt
  Stream<List<SubmissionModel>> getSubmissions(String statusFilter) {
    Query query = _db.collection('submissions').orderBy('createdAt', descending: true);

    // Nếu status không phải là all thì thêm điều kiện lọc
    if (statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }
    return query
        .snapshots()
        .map(
          (snapshot){
          print("Số lượng doc lấy được: ${snapshot.docs.length}"); // In ra số lượng
          return snapshot.docs.map((doc) => SubmissionModel.fromDocument(doc)).toList();
        });
  }

  // Logic Duyệt bài và Cộng điểm transaction
  Future<void> approveTask(
    String submissionId,
    String userId,
    int points,
  ) async {
    final submissionRef = _db.collection('submissions').doc(submissionId);
    final userRef = _db.collection('users').doc(userId);

    await _db.runTransaction((transaction) async {
      DocumentSnapshot userSnap = await transaction.get(userRef);
      if (!userSnap.exists) throw Exception("User không tồn tại");

      // Lấy tất cả các loại điểm hiện tại
      final userData = userSnap.data() as Map<String, dynamic>? ?? {};
      int currentPoints = userData['currentPoints'] ?? 0;
      int currentTotal = userData['totalPoints'] ?? 0;
      int currentWeek = userData['weekPoints'] ?? 0;
      int currentMonth = userData['monthPoints'] ?? 0;

      transaction.update(submissionRef, {
        'status': 'approved',
      });
      transaction.update(userRef, {
        'currentPoints': currentPoints + points, // Tăng ví tiền
        'totalPoints': currentTotal + points, // Tăng tích lũy
        'weekPoints': currentWeek + points,
        'monthPoints': currentMonth  + points,
      });
    });
  }

  // Logic Từ chối bài
  Future<void> rejectTask(String submissionId, String reason) async {
    await _db.collection('submissions').doc(submissionId).update({
      'status': 'rejected',
      'adminNote': reason,
    });
  }
}
