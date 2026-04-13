// lib/features/admin/views/admin_submissions_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/submission_model.dart';
import '../providers/submission_provider.dart';
import '../viewmodels/admin_viewmodel.dart';

class AdminSubmissionsTab extends ConsumerWidget {
  const AdminSubmissionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lắng nghe provider da loc
    final submissionsAsync = ref.watch(filteredSubmissionsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // Giao diện Tìm kiếm và Lọc
          _buildSearchAndFilterBar(context, ref),

          Expanded(
            child: submissionsAsync.when(
              data: (list) => ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                itemBuilder: (context, index) =>
                    _buildSubmissionCard(context, ref, list[index]),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text("Lỗi: $e")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar(BuildContext context, WidgetRef ref) {
    // Lấy trạng thái filter hiện tại để hiển thị
    final currentStatus = ref.watch(statusFilterProvider);

    // Danh sách các bộ lọc để dễ dàng map ra giao diện
    final List<Map<String, String>> filterOptions = [
      {'value': 'all', 'label': 'Tất cả'},
      {'value': 'pending', 'label': 'Đang chờ'},
      {'value': 'approved', 'label': 'Đã duyệt'},
      {'value': 'rejected', 'label': 'Từ chối'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ô Tìm kiếm
          TextField(
            onChanged: (value) {
              ref.read(searchQueryProvider.notifier).state = value;
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              hintText: "Tìm theo tên user, nhiệm vụ...",
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Dải Nút Lọc cuộn ngang
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filterOptions.map((option) {
                final isSelected = currentStatus == option['value'];

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      option['label']!,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    selected: isSelected,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide.none,
                    ),
                    // Đổi màu nền khi được chọn
                    selectedColor: AppColors.primaryGreen,
                    backgroundColor: Colors.grey[200],
                    onSelected: (bool selected) {
                      if (selected) {
                        // Cập nhật trạng thái vào Provider
                        ref.read(statusFilterProvider.notifier).state =
                            option['value']!;
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Widget Thẻ bài nộp (Submission Card)
  Widget _buildSubmissionCard(
    BuildContext context,
    WidgetRef ref,
    SubmissionModel sub,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //  Thông tin User & Task
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
              child: Text(sub.userName[0].toUpperCase()),
            ),
            title: Text(
              sub.taskTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Bởi: ${sub.userName}\n${DateFormat('dd/MM/yyyy HH:mm').format(sub.createdAt)}",
            ),
            trailing: Chip(
              label: Text(
                "+${sub.pointsReward}đ",
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
              backgroundColor: AppColors.primaryGreen,
            ),
          ),

          //  Danh sách ảnh minh chứng
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: sub.proofUrls.length,
                itemBuilder: (ctx, i) =>
                    _buildImageThumbnail(context, sub.proofUrls[i]),
              ),
            ),
          ),

          // Nút bấm duyệt/xóa
          _buildActionArea(context, ref, sub),
        ],
      ),
    );
  }

  Widget _buildActionArea(BuildContext context, WidgetRef ref, SubmissionModel sub) {
    // Đang chờ duyệt
    if (sub.status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showRejectDialog(context, ref, sub.id),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Từ chối"),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => ref.read(adminActionProvider.notifier).approve(sub.id, sub.userId, 50),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Duyệt bài"),
            ),
          ),
        ],
      );
    }

    // Đã duyệt
    if (sub.status == 'approved') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 20),
            SizedBox(width: 8),
            Text("ĐÃ DUYỆT THÀNH CÔNG",
                style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    // Bị từ chối
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),

          ),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel, color: AppColors.error, size: 20),
                  SizedBox(width: 8),
                  Text("BÀI NỘP BỊ TỪ CHỐI",
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                ],
              ),
              if (sub.adminNote != null && sub.adminNote!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text("Lý do: ${sub.adminNote}",
                      style: const TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic, fontSize: 13)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: InteractiveViewer(
          // Cho phép zoom ảnh bằng 2 ngón tay
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  // Thumbnail ảnh có khả năng click xem to
  Widget _buildImageThumbnail(BuildContext context, String url) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(context, url),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
        ),
      ),
    );
  }

  // Dialog nhập lý do từ chối
  void _showRejectDialog(
    BuildContext context,
    WidgetRef ref,
    String submissionId,
  ) {
    // Controller để lấy text từ ô nhập liệu
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error),
              SizedBox(width: 8),
              Text(
                "Từ chối bài nộp",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Vui lòng nhập lý do từ chối để người dùng rút kinh nghiệm:",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3, // Cho phép nhập nhiều dòng
                decoration: InputDecoration(
                  hintText: "Ví dụ: Ảnh quá mờ, không đúng yêu cầu nhiệm vụ...",
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              onPressed: () {
                final reason = reasonController.text.trim();

                // Validate: Bắt buộc phải nhập lý do
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text("Vui lòng nhập lý do từ chối!"),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                // Gọi Riverpod để update Firebase
                ref
                    .read(adminActionProvider.notifier)
                    .reject(submissionId, reason);

                // Đóng Dialog sau khi thao tác
                Navigator.pop(ctx);

                // Báo thành công
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Đã từ chối bài nộp!"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text(
                "Xác nhận",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
