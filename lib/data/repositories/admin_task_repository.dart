import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class AdminTaskRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Lấy toàn bộ danh sách nhiệm vụ
  Stream<List<TaskModel>> getAllTasks() {
    return _db
        .collection('tasks')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => TaskModel.fromDocument(doc)).toList(),
        );
  }

  // Thêm nhiệm vụ mới
  Future<void> addTask(TaskModel task) async {
    await _db.collection('tasks').add(task.toMap());
  }

  // Cập nhật toàn bộ thông tin nhiệm vụ
  Future<void> updateTask(TaskModel task) async {
    await _db.collection('tasks').doc(task.id).update(task.toMap());
  }

  // Cập nhật trạng thái Hiện/Ẩn
  Future<void> toggleTaskStatus(String taskId, bool currentStatus) async {
    await _db.collection('tasks').doc(taskId).update({
      'isActive': !currentStatus,
    });
  }

  // Xóa nhiệm vụ
  Future<void> deleteTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).delete();
  }
}
