import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/submission_history_provider.dart';
import '../widgets/submission_card.dart';

class SubmissionHistoryScreen extends ConsumerWidget {
  const SubmissionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(submissionHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Lịch sử nộp bài',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: historyAsync.when(
        //Đang tải
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),

        //lỗi
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(
                'Không thể tải lịch sử.\nVui lòng thử lại.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),

        //Có dữ liệu
        data: (submissions) {
          if (submissions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 64, color: Colors.grey[350]),
                  const SizedBox(height: 16),
                  Text(
                    'Bạn chưa nộp bài nào.',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hãy hoàn thành nhiệm vụ đầu tiên!',
                    style:
                    TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: submissions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                SubmissionCard(submission: submissions[index]),
          );
        },
      ),
    );
  }
}