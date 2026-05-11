import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/submission_model.dart'; // Đảm bảo bạn đã có model này

class AdminRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<SubmissionModel>> getSubmissions(String statusFilter) {
    // final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    Query query =_db.collection('submissions')
        // .where('createdAt', isGreaterThan: thirtyDaysAgo)
        .orderBy('createdAt', descending: true);

    if (statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }
    return query
        .snapshots()
        .map(
          (snapshot){
          print("Số lượng doc lấy được: ${snapshot.docs.length}");
          return snapshot.docs.map((doc) => SubmissionModel.fromDocument(doc)).toList();
        });
  }

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

      final userData = userSnap.data() as Map<String, dynamic>? ?? {};
      int currentPoints = userData['currentPoints'] ?? 0;
      int currentTotal = userData['totalPoints'] ?? 0;
      int currentWeek = userData['weekPoints'] ?? 0;
      int currentMonth = userData['monthPoints'] ?? 0;

      transaction.update(submissionRef, {
        'status': 'approved',
      });
      transaction.update(userRef, {
        'currentPoints': currentPoints + points,
        'totalPoints': currentTotal + points,
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
