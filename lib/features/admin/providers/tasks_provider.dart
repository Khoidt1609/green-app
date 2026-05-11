

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_app/features/admin/providers/submission_provider.dart';

import '../../../data/models/task_model.dart';
import '../../../data/repositories/admin_task_repository.dart';

final adminTaskRepoProvider = Provider((ref) => AdminTaskRepository());

final taskSearchQueryProvider = StateProvider<String>((ref) => "");


final adminTasksStreamProvider = StreamProvider<List<TaskModel>>((ref) {
  return ref.watch(adminTaskRepoProvider).getAllTasks();
});


final searchTasksProvider = Provider<AsyncValue<List<TaskModel>>>((ref) {
  final tasksAsync  = ref.watch(adminTasksStreamProvider);
  final query = ref.watch(taskSearchQueryProvider).toLowerCase();

  return tasksAsync.whenData((list) {
    if (query.isEmpty) return list; // Nếu không gõ gì thì trả về toàn bộ

    // Lọc
    return list.where((task) {
      final title = (task.title ?? '').toLowerCase();
      final category = (task.category ?? '').toLowerCase();

      return title.contains(query) || category.contains(query);
    }).toList();
  });
});