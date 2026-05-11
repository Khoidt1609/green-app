// lib/viewmodels/admin_task_provider.dart
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_app/data/services/cloudinary_service.dart';

import '../../../data/models/task_model.dart';
import '../../../data/repositories/admin_task_repository.dart';
import '../providers/submission_provider.dart';
import '../providers/tasks_provider.dart';


// Thêm, Đổi trạng thái, Xóa
class AdminTaskActionViewModel extends StateNotifier<AsyncValue<void>> {
  final AdminTaskRepository _repo;
  final ImageUploadService _imageUploadService;

  AdminTaskActionViewModel(this._repo,  this._imageUploadService) : super(const AsyncValue.data(null));

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

  // Hàm Upload Ảnh lên cloudinary và lưu DB
  Future<void> saveTask(
      TaskModel task,
      File? imageFile,
      bool isEdit,
      ) async {
    state = const AsyncValue.loading();
    try {
      String finalImageUrl = task.imageUrl ?? '';

      // Xử lý Upload Ảnh trước (nếu có ảnh mới)
      if (imageFile != null) {
        final uploadedUrl = await _imageUploadService.uploadImage(
          imageFile,
          folder: 'greenstep/admin/tasks',
        );

        if (uploadedUrl == null) {
          throw Exception("Upload ảnh thất bại! Vui lòng thử lại.");
        }
        finalImageUrl = uploadedUrl;
      }

      // Cập nhật link ảnh mới vào Model
      final taskToSave = TaskModel(id: task.id,
          title: task.title, description: task.description, pointsReward: task.pointsReward, category: task.category, imageUrl: finalImageUrl);

      // THêm mới hoặc sửa
      if (isEdit) {
        await _repo.updateTask(taskToSave);
      } else {
        await _repo.addTask(taskToSave);
      }

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}


// Provider để UI gọi các hàm hành động
final adminTaskActionProvider = StateNotifierProvider<AdminTaskActionViewModel, AsyncValue<void>>((ref) {
  return AdminTaskActionViewModel(ref.read(adminTaskRepoProvider), ref.read(imageUploadServiceProvider));
});