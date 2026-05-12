import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/models/task_model.dart';
import '../providers/submission_history_provider.dart';
import 'task_detail_dialog.dart';
import 'task_submission_sheet.dart';

class TaskCard extends ConsumerWidget {
  final TaskModel task;
  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!task.isActive) return const SizedBox.shrink();

    final latestSubmission =
    ref.watch(taskSubmissionStatusProvider(task.id));

    // đang chờ duyệt → vàng, còn lại → cho nộp bình thường
    final btnConfig = latestSubmission?.status == 'pending'
        ? _ButtonConfig.pending()
        : _ButtonConfig.canSubmit();

    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => TaskDetailDialog(task: task),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //Ảnh + Tag Category
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Image.network(
                      task.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        task.category,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryDarkGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Nội dung bên dưới
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: AppTextStyles.heading2.copyWith(
                          color: AppColors.textPrimary, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.eco_rounded,
                            color: AppColors.primaryGreen, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${task.pointsReward} điểm',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Nút động theo trạng thái
                    _SubmitButton(config: btnConfig, task: task),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//Widget nút submit

class _SubmitButton extends StatelessWidget {
  final _ButtonConfig config;
  final TaskModel task;

  const _SubmitButton({required this.config, required this.task});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _handlePress(context, config.action),
      style: ElevatedButton.styleFrom(
        backgroundColor: config.backgroundColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 34),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(
        config.label,
        style:
        const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Future<void> _handlePress(
      BuildContext context, _ButtonAction action) async {
    switch (action) {

      case _ButtonAction.openSheet:
        final bool? result = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => TaskSubmissionSheet(task: task),
        );
        if (result == true && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
              Text('Nộp bài thành công! Đang chờ quản trị viên duyệt.'),
              backgroundColor: AppColors.primaryGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

      case _ButtonAction.showPending:
        _showInfoDialog(
          context,
          icon: Icons.hourglass_top_rounded,
          iconColor: const Color(0xFFF59E0B),
          title: 'Đang chờ duyệt',
          message:
          'Bài nộp của bạn đang chờ quản trị viên xem xét.\nVui lòng thử lại sau.',
        );


    }
  }

  void _showInfoDialog(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required String title,
        required String message,
      }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 52),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Đã hiểu',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//Config nút theo từng trạng thái
enum _ButtonAction { openSheet, showPending }

class _ButtonConfig {
  final String label;
  final Color backgroundColor;
  final _ButtonAction action;

  const _ButtonConfig({
    required this.label,
    required this.backgroundColor,
    required this.action,
  });

  factory _ButtonConfig.canSubmit() => const _ButtonConfig(
    label: 'Nộp bài',
    backgroundColor: AppColors.primaryGreen,
    action: _ButtonAction.openSheet,
  );

  factory _ButtonConfig.pending() => const _ButtonConfig(
    label: 'Chờ duyệt',
    backgroundColor: Color(0xFFF59E0B),
    action: _ButtonAction.showPending,
  );
}