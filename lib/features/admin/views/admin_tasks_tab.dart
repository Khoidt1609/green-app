import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_app/features/admin/views/task_form_bottom_sheet.dart';
import 'package:green_app/features/admin/widgets/search_add_bar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/task_model.dart';
import '../providers/tasks_provider.dart';
import '../viewmodels/admin_task_viewmodel.dart';
import '../widgets/stat_card.dart'; // Chú ý: Đảm bảo import đúng đường dẫn provider của bạn

class AdminTasksTab extends ConsumerWidget {
  const AdminTasksTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(searchTasksProvider);
    final allTasksAsync = ref.watch(adminTasksStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            CustomSearchAddBar(hintText: 'Tìm kiêm nhiệm vụ', onSearchChanged: (value) {
              ref.read(taskSearchQueryProvider.notifier).state = value;
            }, onAddPressed: () => _showTaskForm(context),),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    allTasksAsync.when(
                      data: (tasks) => _buildTaskStats(tasks),
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: LinearProgressIndicator(color: AppColors.primaryGreen)),
                      ),
                      error: (err, stack) => Text("Lỗi thống kê: $err"),
                    ),

                    const SizedBox(height: 8),

                    tasksAsync.when(
                      data: (tasks) {
                        if (tasks.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Center(child: Text("Không tìm thấy nhiệm vụ nào.")),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return _buildTaskCard(context, ref, task);
                          },
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (err, stack) => Center(child: Text("Lỗi: $err")),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskStats(List<TaskModel> tasks) {
    //đếm số lượng từ danh sách đã tải về
    final total = tasks.length;
    final active = tasks.where((t) => t.isActive).length;
    final inactive = total - active;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              icon: Icons.eco, // Icon tổng quan
              color: AppColors.primaryDarkGreen,
              value: total.toString(),
              label: 'Tổng số',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              icon: Icons.play_circle_outline,
              color: AppColors.primaryGreen,
              value: active.toString(),
              label: 'Đang hiện',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              icon: Icons.pause_circle_outline,
              color: Colors.grey,
              value: inactive.toString(),
              label: 'Đã ẩn',
            ),
          ),
        ],
      ),
    );
  }

  // Card tasks
  Widget _buildTaskCard(BuildContext context, WidgetRef ref, TaskModel task) {
    final bool isActive = task.isActive ?? true; // Nếu Firebase không có, mặc định là true
    final bool isDisabled = !isActive;

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
                                task.title ?? "Không có tiêu đề",
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
                          task.category ?? "Chưa phân loại",
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
              const SizedBox(height: 4),


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
                          value: isActive,
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nút Sửa
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.lightGreenAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.lightGreenAccent.withOpacity(0.5)),
                        ),
                        child: IconButton(
                          tooltip: "Sửa nhiệm vụ", // Nhấn giữ hiện chữ
                          icon: const Icon(Icons.edit_outlined, color: AppColors.primaryDarkGreen, size: 20),
                          onPressed: isDisabled ? null : () => _showTaskForm(context, task: task),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(), // Thu gọn kích thước thừa
                        ),
                      ),

                      const SizedBox(width: 10), // Khoảng cách giữa 2 nút

                      // Nút Xóa
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.2)),
                        ),
                        child: IconButton(
                          tooltip: "Xóa nhiệm vụ", // Nhấn giữ hiện chữ
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: isDisabled ? null : () => _showDeleteConfirmDialog(context, ref, task.id),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
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
