import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy danh sách nhiệm vụ đang hoạt động
  Stream<List<TaskModel>> getActiveTasks() {
    return _firestore
        .collection('tasks')
        .where('isActive', isEqualTo: true) // Chỉ lấy các nhiệm vụ đang bật
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TaskModel.fromDocument(doc)).toList();
    });
  }
}