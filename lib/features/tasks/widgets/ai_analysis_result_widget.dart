// lib/features/tasks/widgets/ai_analysis_result_widget.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../core/services/gemini_service.dart';
import '../providers/submission_provider.dart';

class AiAnalysisResultWidget extends StatelessWidget {
  final GeminiAnalysisResult result;

  const AiAnalysisResultWidget({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final color = switch (result.verdict) {
      'approved' => const Color(0xFF2E7D32),
      'rejected'  => const Color(0xFFC62828),
      _           => const Color(0xFFF57F17),
    };
    final bgColor = switch (result.verdict) {
      'approved' => const Color(0xFFE8F5E9),
      'rejected'  => const Color(0xFFFFEBEE),
      _           => const Color(0xFFFFF8E1),
    };
    final icon = switch (result.verdict) {
      'approved' => Icons.check_circle_rounded,
      'rejected'  => Icons.cancel_rounded,
      _           => Icons.help_rounded,
    };
    final label = switch (result.verdict) {
      'approved' => 'AI xác nhận hợp lệ',
      'rejected'  => 'AI phát hiện không hợp lệ',
      _           => 'AI chưa chắc chắn — Admin sẽ xem lại',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 13, color: Colors.purple),
              const SizedBox(width: 4),
              const Text(
                'Phân tích AI',
                style: TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(result.confidence * 100).round()}% tin cậy',
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 13)),
                    if (result.explanation.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(result.explanation, style: TextStyle(color: color.withOpacity(0.85), fontSize: 12.5, height: 1.4)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}