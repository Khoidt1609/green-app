import 'package:flutter/material.dart';
class SubmissionStatusBadge extends StatelessWidget {
  final String status;

  const SubmissionStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _resolveConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.borderColor, width: 1.5),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }


  _StatusConfig _resolveConfig(String status) {
    switch (status) {
      case 'approved':
        return const _StatusConfig(
          label: 'đã duyệt',
          textColor: Color(0xFF1B8A4E),
          borderColor: Color(0xFF1B8A4E),
        );
      case 'rejected':
        return const _StatusConfig(
          label: 'từ chối',
          textColor: Color(0xFFD94040),
          borderColor: Color(0xFFD94040),
        );
      case 'pending':
      default:
        return const _StatusConfig(
          label: 'đang duyệt',
          textColor: Color(0xFF888888),
          borderColor: Color(0xFF888888),
        );
    }
  }
}

// ── Internal config ───────────────────────────────────────────────────────────

class _StatusConfig {
  final String label;
  final Color textColor;
  final Color borderColor;

  const _StatusConfig({
    required this.label,
    required this.textColor,
    required this.borderColor,
  });
}