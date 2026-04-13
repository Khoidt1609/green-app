import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_app/features/admin/views/task_form_bottom_sheet.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/task_model.dart';
import '../providers/tasks_provider.dart';
import '../viewmodels/admin_task_viewmodel.dart'; // Chú ý: Đảm bảo import đúng đường dẫn provider của bạn

class AdminTasksTab extends ConsumerWidget {
  const AdminTasksTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(searchTasksProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            //  Thanh Tìm kiếm & Nút Thêm mới
            _buildTopBar(context, ref),

            // Danh sách Task dạng Card
            Expanded(
              child: tasksAsync.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return const Center(child: Text("Chưa có nhiệm vụ nào."));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _buildTaskCard(context, ref, task);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text("Lỗi: $err")),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Thanh Search
          Expanded(
            child: TextField(
              onChanged: (value) {
                ref.read(taskSearchQueryProvider.notifier).state = value;
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm nhiệm vụ...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryGreen),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Nút Thêm Mới (Vuông bo góc, màu xanh)
          InkWell(
            onTap: () {
              _showTaskForm(context);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Card tasks
  Widget _buildTaskCard(BuildContext context, WidgetRef ref, TaskModel task) {
    final bool isDisabled = !task.isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: isDisabled ? 0 : 2,
      color: isDisabled ? Colors.grey.shade100 : Colors.white,
      child: Opacity(
        opacity: isDisabled ? 0.6 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Ảnh, Tên, Phân loại & Điểm số
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //  Ảnh minh họa
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      task.imageUrl.isNotEmpty
                          ? task.imageUrl
                          : 'https://via.placeholder.com/150',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 30,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  //  Tên, Category và Điểm
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hàng chứa Tên (bên trái) và Điểm (góc phải)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tên nhiệm vụ (Dùng Expanded để không bị tràn màn hình nếu tên dài)
                            Expanded(
                              child: Text(
                                task.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Điểm thưởng (Góc trên cùng bên phải)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "+${task.pointsReward} điểm",
                                style: const TextStyle(
                                  color: AppColors.primaryDarkGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Phân loại
                        Text(
                          task.category,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              const Divider(height: 1),

              //  Công tắc, Nút Sửa & Nút Xóa
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Bên trái dưới cùng: Công tắc Switch
                  Row(
                    children: [
                      SizedBox(
                        height: 40,
                        child: Switch(
                          value: task.isActive,
                          activeColor: AppColors.primaryGreen,
                          onChanged: (value) {
                            ref
                                .read(adminTaskActionProvider.notifier)
                                .toggleStatus(task.id, task.isActive);
                          },
                        ),
                      ),
                      Text(
                        task.isActive ? "Đang hiện" : "Đã ẩn",
                        style: TextStyle(
                          fontSize: 13,
                          color: task.isActive
                              ? AppColors.primaryGreen
                              : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Bên phải dưới cùng: Nút Sửa và Nút Xóa
                  Row(
                    children: [
                      // Nút Sửa
                      ElevatedButton.icon(
                        label: Text('Sửa'),

                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.primaryDarkGreen,
                        ),
                        onPressed: isDisabled
                            ? null
                            : () {
                                _showTaskForm(context, task: task);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightGreenAccent.withOpacity(
                            0.2,
                          ),
                          foregroundColor: AppColors.primaryDarkGreen,
                          elevation: 0,
                          side: BorderSide(
                            color: Colors.lightGreenAccent.withOpacity(0.5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Nút Xóa
                      ElevatedButton.icon(
                        onPressed: isDisabled
                            ? null
                            : () {
                                _showDeleteConfirmDialog(context, ref, task.id);
                              },
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ), // Icon đỏ
                        label: const Text('Xóa'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          foregroundColor: Colors.red.shade900,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide(color: Colors.red.withOpacity(0.2)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hàm hiển thị Bottom Sheet
  void _showTaskForm(BuildContext context, {TaskModel? task}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Để bàn phím không che mất form
      backgroundColor: Colors.transparent, // Để lộ góc bo tròn của form
      builder: (context) => TaskFormBottomSheet(taskToEdit: task),
    );
  }

  // Hàm hiển thị Popup hỏi chắc chắn muốn xóa không
  void _showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    String taskId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text(
          "Bạn có chắc chắn muốn xóa nhiệm vụ này không? Dữ liệu sẽ không thể khôi phục.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // Gọi hàm xóa từ Provider
              ref.read(adminTaskActionProvider.notifier).delete(taskId);
              Navigator.pop(ctx);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
