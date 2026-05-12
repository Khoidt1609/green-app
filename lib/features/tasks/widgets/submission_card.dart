// lib/features/tasks/widgets/submission_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/submission_model.dart';
import 'submission_status_badge.dart';

class SubmissionCard extends StatelessWidget {
  final SubmissionModel submission;

  final VoidCallback? onTap;

  const SubmissionCard({
    super.key,
    required this.submission,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate =
    DateFormat('HH:mm  dd/MM/yyyy').format(submission.createdAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Icon danh mục ────────────────────────────────────────────────
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F9F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.eco_rounded,
                color: AppColors.primaryGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // ── Tiêu đề + thời gian ──────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    submission.taskTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 13, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // ── Badge trạng thái (widget tách riêng) ────────────────────────
            SubmissionStatusBadge(status: submission.status),
          ],
        ),
      ),
    );
  }
}