// lib/features/admin/views/admin_submissions_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/submission_model.dart';
import '../providers/submission_provider.dart';
import '../viewmodels/admin_viewmodel.dart';
import '../widgets/stat_card.dart';
import 'submisson_detail_bottom_sheet.dart';

class AdminSubmissionsTab extends ConsumerWidget {
  const AdminSubmissionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredSubmissionsAsync = ref.watch(filteredSubmissionsProvider);
    final allSubmissionsAsync = ref.watch(allSubmissionsStreamProvider);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchAndFilterBar(context, ref),
            Expanded(
              child: filteredSubmissionsAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const Center(child: Text("Không có bài nộp nào."));
                  }

                  return ListView.builder(
                    itemCount: list.length + 1,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return allSubmissionsAsync.when(
                          data: (allList) => _buildSubmissionStats(allList),
                          loading: () => const SizedBox(
                            height: 100,
                            child: Center(child: LinearProgressIndicator()),
                          ),
                          error: (e, _) => Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text("Lỗi thống kê: $e"),
                          ),
                        );
                      }

                      final submission = list[index - 1];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: _buildSubmissionCard(context, ref, submission),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("Lỗi: $e")),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar(BuildContext context, WidgetRef ref) {
    final currentStatus = ref.watch(statusFilterProvider);

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
                        fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    selected: isSelected,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide.none,
                    ),
                    selectedColor: AppColors.primaryGreen,
                    backgroundColor: Colors.grey[200],
                    onSelected: (bool selected) {
                      if (selected) {
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

  Widget _buildSubmissionCard(
      BuildContext context,
      WidgetRef ref,
      SubmissionModel sub,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) =>
                SubmissionDetailBottomSheet(submission: sub),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: Avatar + Tên + Ngày + Status chip ──
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryGreen,
                  backgroundImage:
                  (sub.userAvatar != null && sub.userAvatar!.isNotEmpty)
                      ? NetworkImage(sub.userAvatar!)
                      : null,
                  child:
                  (sub.userAvatar == null || sub.userAvatar!.isEmpty)
                      ? Text(
                    sub.userName.isNotEmpty
                        ? sub.userName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(sub.createdAt),
                        style:
                        const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(sub.status),
              ],
            ),

            const SizedBox(height: 12),

            // ── Tên nhiệm vụ ──
            Text(
              sub.taskTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 6),

            // ── Điểm thưởng ──
            Row(
              children: [
                const Icon(Icons.stars, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                Text("+${sub.pointsReward} điểm"),
              ],
            ),

            // ── MỚI: Badge AI Verdict ──
            if (sub.aiVerdict != null) ...[
              const SizedBox(height: 10),
              _buildAiBadge(sub),
            ],

            const SizedBox(height: 12),

            // ── Ảnh bằng chứng ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
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

            const SizedBox(height: 12),

            // ── Nút duyệt / từ chối ──
            _buildActionArea(context, ref, sub),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  BADGE AI VERDICT — widget mới thêm vào
  // ─────────────────────────────────────────────
  Widget _buildAiBadge(SubmissionModel sub) {
    final verdict = sub.aiVerdict ?? 'uncertain';
    final confidence = sub.aiConfidence ?? 0.0;
    final explanation = sub.aiExplanation ?? '';

    // Màu sắc theo verdict
    final color = switch (verdict) {
      'approved' => const Color(0xFF2E7D32),
      'rejected' => const Color(0xFFC62828),
      _ => const Color(0xFFF57F17),
    };
    final bgColor = switch (verdict) {
      'approved' => const Color(0xFFE8F5E9),
      'rejected' => const Color(0xFFFFEBEE),
      _ => const Color(0xFFFFF8E1),
    };
    final icon = switch (verdict) {
      'approved' => Icons.check_circle_rounded,
      'rejected' => Icons.cancel_rounded,
      _ => Icons.help_rounded,
    };
    final label = switch (verdict) {
      'approved' => 'AI: Hợp lệ',
      'rejected' => 'AI: Không hợp lệ',
      _ => 'AI: Chưa chắc chắn',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dòng 1: icon AI + label + % tin cậy
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 13, color: Colors.purple),
              const SizedBox(width: 4),
              const Text(
                'Phân tích AI  •  ',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.purple,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Badge % tin cậy
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(confidence * 100).round()}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          // Dòng 2: giải thích (nếu có)
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              explanation,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.85),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmissionStats(List<SubmissionModel> list) {
    final pending = list.where((s) => s.status == 'pending').length;
    final approved = list.where((s) => s.status == 'approved').length;
    final rejected = list.where((s) => s.status == 'rejected').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              icon: Icons.hourglass_empty,
              color: Colors.orange,
              value: pending.toString(),
              label: 'Chờ duyệt',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatCard(
              icon: Icons.check_circle_outline,
              color: Colors.green,
              value: approved.toString(),
              label: 'Đã duyệt',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatCard(
              icon: Icons.highlight_off,
              color: Colors.red,
              value: rejected.toString(),
              label: 'Từ chối',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionArea(
      BuildContext context,
      WidgetRef ref,
      SubmissionModel sub,
      ) {
    if (sub.status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () =>
                  _showRejectDialog(context, ref, sub.id, sub.userId),
              icon: const Icon(Icons.close),
              label: const Text("Từ chối"),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => ref
                  .read(adminActionProvider.notifier)
                  .approve(sub.id, sub.userId, sub.pointsReward),
              icon: const Icon(Icons.check),
              label: const Text("Duyệt"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
            ),
          ),
        ],
      );
    }

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
            Text(
              "ĐÃ DUYỆT THÀNH CÔNG",
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel, color: AppColors.error, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "BÀI NỘP BỊ TỪ CHỐI",
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (sub.adminNote != null && sub.adminNote!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    "Lý do: ${sub.adminNote}",
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
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

  Widget _buildImageThumbnail(BuildContext context, String url) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(context, url),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
              image: NetworkImage(url), fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case 'approved':
        color = Colors.green;
        text = "Đã duyệt";
        break;
      case 'rejected':
        color = Colors.red;
        text = "Từ chối";
        break;
      default:
        color = Colors.orange;
        text = "Chờ duyệt";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showRejectDialog(
      BuildContext context,
      WidgetRef ref,
      String submissionId,
      String userId,
      ) {
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
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                  "Ví dụ: Ảnh quá mờ, không đúng yêu cầu nhiệm vụ...",
                  hintStyle:
                  const TextStyle(color: Colors.grey, fontSize: 13),
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
              child:
              const Text("Hủy", style: TextStyle(color: Colors.grey)),
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
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text("Vui lòng nhập lý do từ chối!"),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                ref
                    .read(adminActionProvider.notifier)
                    .reject(submissionId, userId, reason);

                Navigator.pop(ctx);

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