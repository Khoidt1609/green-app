// lib/viewmodels/admin_task_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/task_model.dart';
import '../../../data/repositories/admin_task_repository.dart';
import '../providers/submission_provider.dart';
import '../providers/tasks_provider.dart';


// Thêm, Đổi trạng thái, Xóa
class AdminTaskActionViewModel extends StateNotifier<AsyncValue<void>> {
  final AdminTaskRepository _repo;

  AdminTaskActionViewModel(this._repo) : super(const AsyncValue.data(null));

  Future<void> toggleStatus(String taskId, bool currentStatus) async {
    try {
      await _repo.toggleTaskStatus(taskId, currentStatus);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Hàm thêm mới
  Future<void> add(TaskModel task) async {
    state = const AsyncValue.loading(); // Bật trạng thái Loading
    try {
      await _repo.addTask(task);
      state = const AsyncValue.data(null); // Tắt Loading, báo thành công
    } catch (e, stack) {
      state = AsyncValue.error(e, stack); // Tắt Loading, báo lỗi
    }
  }

  // Hàm cập nhật
  Future<void> update(TaskModel task) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateTask(task);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }


  Future<void> delete(String taskId) async {
    try {
      await _repo.deleteTask(taskId);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Provider để UI gọi các hàm hành động
final adminTaskActionProvider = StateNotifierProvider<AdminTaskActionViewModel, AsyncValue<void>>((ref) {
  return AdminTaskActionViewModel(ref.read(adminTaskRepoProvider));
});