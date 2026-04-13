import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_providers.dart';

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách nhiệm vụ')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: authService.getCurrentUserTasks(limit: 50),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Không thể tải nhiệm vụ. Vui lòng thử lại.'),
            );
          }

          final tasks = snapshot.data ?? const <Map<String, dynamic>>[];
          if (tasks.isEmpty) {
            return const Center(
              child: Text('Chưa có nhiệm vụ nào được tạo.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final task = tasks[index];
              final done = (task['done'] as bool?) ?? false;
              final title =
                  (task['title'] as String?)?.trim().isNotEmpty == true
                  ? task['title'] as String
                  : 'Nhiệm vụ';
              final points = (task['points'] as num?)?.toInt() ?? 0;

              return Card(
                child: ListTile(
                  leading: Icon(
                    done ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: done ? AppColors.success : AppColors.textSecondary,
                  ),
                  title: Text(title),
                  subtitle: Text('+$points điểm'),
                  trailing: done
                      ? const Chip(label: Text('Hoàn thành'))
                      : const Chip(label: Text('Đang chờ')),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
