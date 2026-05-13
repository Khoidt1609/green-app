import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/submission_model.dart';
import '../providers/submission_history_provider.dart';

class ApprovedSubmissionsList extends ConsumerStatefulWidget {
  final bool isHorizontal;
  final int? maxItems;

  const ApprovedSubmissionsList({
    super.key,
    this.isHorizontal = true,
    this.maxItems,
  });

  @override
  ConsumerState<ApprovedSubmissionsList> createState() =>
      _ApprovedSubmissionsListState();
}

class _ApprovedSubmissionsListState
    extends ConsumerState<ApprovedSubmissionsList> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.82);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submissionsAsync = ref.watch(approvedSubmissionsProvider);

    return submissionsAsync.when(
      loading: () => SizedBox(
        height: widget.isHorizontal ? 200 : 100,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      ),
      error: (e, _) => Center(
        child: Text(
          'Lỗi tải dữ liệu',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
      data: (submissions) {
        if (submissions.isEmpty) {
          return _EmptySubmissions();
        }

        final displaySubmissions = widget.maxItems != null
            ? submissions.take(widget.maxItems!).toList()
            : submissions;

        if (widget.isHorizontal) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 200,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemCount: displaySubmissions.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _SubmissionCard(
                        submission: displaySubmissions[index],
                      ),
                    );
                  },
                ),
              ),
              if (displaySubmissions.length > 1) ...[
                const SizedBox(height: 10),
                _SmartDots(
                  total: displaySubmissions.length,
                  current: _currentPage,
                  onTap: (index) => _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                ),
              ],
            ],
          );
        } else {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: displaySubmissions.asMap().entries.map((entry) {
              final i = entry.key;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: i < displaySubmissions.length - 1 ? 12 : 0,
                ),
                child: _SubmissionCardHorizontal(
                  submission: entry.value,
                ),
              );
            }).toList(),
          );
        }
      },
    );
  }
}

// ── Smart dots indicator (tối đa 5 chấm) ─────────────────────────────────────
class _SmartDots extends StatelessWidget {
  final int total;
  final int current;
  final void Function(int) onTap;

  const _SmartDots({
    required this.total,
    required this.current,
    required this.onTap,
  });

  static const int _maxVisible = 5;

  @override
  Widget build(BuildContext context) {
    // Tính window 5 chấm xoay quanh current
    int start;
    if (total <= _maxVisible) {
      start = 0;
    } else {
      // giữ current ở giữa càng nhiều càng tốt
      start = (current - _maxVisible ~/ 2).clamp(0, total - _maxVisible);
    }

    final end = (start + _maxVisible).clamp(0, total);
    final visibleIndices = List.generate(end - start, (i) => start + i);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Chấm mờ bên trái nếu có trang ẩn phía trước
        if (start > 0)
          _buildDot(start - 1, scale: 0.6, faded: true),

        ...visibleIndices.map((index) => GestureDetector(
              onTap: () => onTap(index),
              child: _buildDot(index),
            )),

        // Chấm mờ bên phải nếu có trang ẩn phía sau
        if (end < total)
          _buildDot(end, scale: 0.6, faded: true),
      ],
    );
  }

  Widget _buildDot(int index, {double scale = 1.0, bool faded = false}) {
    final isActive = index == current;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      height: 6 * scale,
      width: (isActive ? 18 : 6) * scale,
      decoration: BoxDecoration(
        color: faded
            ? Colors.grey[300]
            : isActive
                ? AppColors.primaryGreen
                : Colors.grey[300],
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptySubmissions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5EF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC8E6D4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline,
              color: Colors.grey[400], size: 36),
          const SizedBox(height: 10),
          const Text(
            'Chưa có nhiệm vụ nào được duyệt',
            style: TextStyle(color: Color(0xFF5A8A6E), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Vertical card (dùng trong PageView ngang) ─────────────────────────────────
class _SubmissionCard extends StatelessWidget {
  final SubmissionModel submission;

  const _SubmissionCard({required this.submission});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0EADE), width: 0.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ảnh tỉ lệ 4:3
            Expanded(
              flex: 3,
              child: _ProofImage(
                url: submission.proofUrls.isNotEmpty
                    ? submission.proofUrls.first
                    : null,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
            ),

            // Nội dung phía dưới
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      submission.taskTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF0B1C30),
                        height: 1.3,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt_rounded,
                                  size: 12, color: AppColors.primaryGreen),
                              const SizedBox(width: 2),
                              Text(
                                '+${submission.pointsReward} pts',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF006C47),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.check_circle_rounded,
                            size: 14, color: Color(0xFF2E7D52)),
                      ],
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

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(submission: submission),
    );
  }
}

// ── Horizontal card (dùng trong list dọc) ─────────────────────────────────────
class _SubmissionCardHorizontal extends StatelessWidget {
  final SubmissionModel submission;

  const _SubmissionCardHorizontal({required this.submission});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0EADE), width: 0.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Row(
        children: [
          // Ảnh vuông bên trái
          SizedBox(
            width: 88,
            height: 88,
            child: _ProofImage(
              url: submission.proofUrls.isNotEmpty
                  ? submission.proofUrls.first
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Nội dung
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    submission.taskTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF1A3D2A),
                      height: 1.35,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.bolt_rounded,
                          size: 13, color: Colors.orange),
                      const SizedBox(width: 3),
                      Text(
                        '+${submission.pointsReward} XP',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2E7D52),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Badge
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Đã duyệt',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable image widget ─────────────────────────────────────────────────────
class _ProofImage extends StatelessWidget {
  final String? url;
  final BorderRadius? borderRadius;

  const _ProofImage({this.url, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (url != null && url!.isNotEmpty) {
      child = Image.network(
        url!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _placeholder(hasError: true),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return _placeholder(hasError: false);
        },
      );
    } else {
      child = _placeholder(hasError: false);
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }

  Widget _placeholder({required bool hasError}) {
    return Container(
      color: const Color(0xFFF0F7F2),
      child: Center(
        child: Icon(
          hasError ? Icons.broken_image_outlined : Icons.image_outlined,
          color: const Color(0xFFB2D9C2),
          size: 28,
        ),
      ),
    );
  }
}

// ── Detail bottom sheet ───────────────────────────────────────────────────────
class _DetailSheet extends StatelessWidget {
  final SubmissionModel submission;

  const _DetailSheet({required this.submission});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Title
            Text(
              submission.taskTitle,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF1A3D2A),
              ),
            ),
            const SizedBox(height: 12),

            // Points + badge
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF5EF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded,
                          size: 14, color: Color(0xFF2E7D52)),
                      const SizedBox(width: 4),
                      Text(
                        '+${submission.pointsReward} XP',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1E6B44),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF5EF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 14, color: Color(0xFF2E7D52)),
                      SizedBox(width: 4),
                      Text(
                        'Đã duyệt',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1E6B44),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Thông tin chi tiết submission
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F9F7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0F0E8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ngày tạo
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: Color(0xFF5A8A6E),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Ngày nộp:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5A8A6E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(submission.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1A3D2A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Trạng thái
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.info_rounded,
                        size: 16,
                        color: Color(0xFF5A8A6E),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Trạng thái:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5A8A6E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(submission.status),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _statusLabel(submission.status),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Bằng chứng hoàn thành',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF1A3D2A),
              ),
            ),
            const SizedBox(height: 12),

            // Grid ảnh tỉ lệ 1:1
            if (submission.proofUrls.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemCount: submission.proofUrls.length,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _ProofImage(url: submission.proofUrls[index]),
                  );
                },
              )
            else
              _ProofImage(
                url: null,
                borderRadius: BorderRadius.circular(12),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF2E7D52);
      case 'rejected':
        return const Color(0xFFD32F2F);
      case 'pending':
        return const Color(0xFFF57C00);
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Đã duyệt';
      case 'rejected':
        return 'Từ chối';
      case 'pending':
        return 'Đang chờ';
      default:
        return status;
    }
  }
}