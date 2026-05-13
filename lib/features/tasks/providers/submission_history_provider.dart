import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/submission_model.dart';

// lịch sử nộp bài
final submissionHistoryProvider =
StreamProvider.autoDispose<List<SubmissionModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('submissions')
      .where('userId', isEqualTo: uid)
      .snapshots()
      .map((snap) {
    final list = snap.docs
        .map((doc) => SubmissionModel.fromDocument(doc))
        .toList();

    // Sort phía client: mới nhất lên đầu
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  });
});

// Lấy các bài nộp đã được duyệt (approved) của user hiện tại
final approvedSubmissionsProvider =
StreamProvider.autoDispose<List<SubmissionModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('submissions')
      .where('userId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) {
    final list = snap.docs
        .map((doc) => SubmissionModel.fromDocument(doc))
        .toList();
    
    // Lọc chỉ những submission đã approved phía client
    return list.where((s) => s.status == 'approved').toList();
  });
});

//trạng thái bài nộp theo từng taskId
final taskSubmissionStatusProvider =
Provider.autoDispose.family<SubmissionModel?, String>((ref, taskId) {
  // Đọc từ submissionHistoryProvider
  final allSubmissions = ref.watch(submissionHistoryProvider).value;
  if (allSubmissions == null) return null;

  // Lọc theo taskId
  final forThisTask =
  allSubmissions.where((s) => s.taskId == taskId).toList();
  return forThisTask.isEmpty ? null : forThisTask.first;
});