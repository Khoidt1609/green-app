// lib/features/home/views/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../router/app_router.dart';
import '../viewmodel/home_viewmodel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);
    final vm = ref.read(homeViewModelProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: RefreshIndicator(
              color: AppColors.primaryGreen,
              onRefresh: vm.refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ────────────────────────────────
                      _HomeHeader(
                        state: state,
                        onProfileTap: () async {
                          await Navigator.of(context)
                              .pushNamed(AppRouter.profile);
                          ref
                              .read(homeViewModelProvider.notifier)
                              .refresh();
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Profile card ──────────────────────────
                      if (state.isLoadingProfile)
                        const _LoadingCard(height: 160)
                      else
                        _ProfileCard(state: state),
                      const SizedBox(height: 10),

                      // ── Stat badges ───────────────────────────
                      _StatBadgeRow(state: state),
                      const SizedBox(height: 12),

                      // ── Quick actions ─────────────────────────
                     
                      const SizedBox(height: 14),

                      // ── Store banner ──────────────────────────
                      _StoreBanner(totalPoints: state.totalPoints),
                      const SizedBox(height: 18),

                      // ── Recent tasks ──────────────────────────
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Nhiệm vụ gần đây',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                Navigator.of(context).pushNamed(AppRouter.tasks),
                            child: Row(
                              children: [
                                
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (state.isLoadingTasks)
                        const _LoadingCard(height: 80)
                      else if (state.recentTasks.isEmpty)
                        _EmptyState(
                          message: 'Chưa có nhiệm vụ nào. Bắt đầu hành động xanh ngay!',
                          onTap: () =>
                              Navigator.of(context).pushNamed(AppRouter.tasks),
                        )
                      else
                        ...state.recentTasks.asMap().entries.map((entry) {
                          final i = entry.key;
                          final task = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: i < state.recentTasks.length - 1 ? 10 : 0,
                            ),
                            child: _TaskCard(task: task, index: i),
                          );
                        }),

                      const SizedBox(height: 18),

                      // ── Achievements ──────────────────────────
                      _AchievementSection(
                        achievements: state.recentAchievements,
                        cityRank: state.cityRank,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.state,
    required this.onProfileTap,
  });

  final HomeState state;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Good Morning ☘',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                state.displayName.isEmpty ? 'Người dùng' : state.displayName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _TopIconButton(
          icon: Icons.notifications_none_rounded,
          onTap: () {},
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onProfileTap,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primaryGreen,
                width: 1.4,
              ),
            ),
            child: Center(
              child: CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.primaryGreen,
                child: Text(
                  state.avatarInitial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Profile Card ───────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryGreen.withValues(alpha: 0.22),
                  ),
                ),
                child: Center(
                  child: Text(
                    state.avatarInitial,
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Name (Đã xóa dòng Level ở dưới)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.displayName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _MiniStatBadge(
                title: 'Total Pts',
                value: '${state.totalPoints}',
                accent: AppColors.primaryDarkGreen,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ScoreLine(
            label: 'Điểm tuần',
            resetLabel: '',
            valueText: '${state.weekPoints}',
            accent: AppColors.primaryGreen,
          ),
          const SizedBox(height: 14),
          _ScoreLine(
            label: 'Điểm tháng',
            resetLabel: '',
            valueText: '${state.monthPoints}',
            accent: AppColors.earthyBrown,
          ),
        ],
      ),
    );
  }
}

// ─── Stat Badges ───────────────────────────────────────────────────────────────

class _StatBadgeRow extends StatelessWidget {
  const _StatBadgeRow({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        
        const SizedBox(width: 8),
        Expanded(
          child: _HeaderStatCard(
            icon: Icons.check_circle_outline,
            iconColor: AppColors.primaryGreen,
            value: '${state.tasksDoneCount}',
            label: 'Hoàn thành',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _HeaderStatCard(
            icon: Icons.star_border,
            iconColor: AppColors.earthyBrown,
            value: state.cityRank != null ? '#${state.cityRank}' : '--',
            label: 'Xếp hạng',
          ),
        ),
      ],
    );
  }
}

// ─── Store Banner ───────────────────────────────────────────────────────────────

class _StoreBanner extends StatelessWidget {
  const _StoreBanner({required this.totalPoints});

  final int totalPoints;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        color: AppColors.surfaceLight,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cửa Hàng Xanh',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bạn có $totalPoints điểm để đổi quà.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
        ],
      ),
    );
  }
}

// ─── Recent Task Card ───────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.index});

  final Map<String, dynamic> task;
  final int index;

  static const _icons = [
    Icons.recycling_outlined,
    Icons.pedal_bike_outlined,
    Icons.lightbulb_outline,
  ];

  static const _iconColors = [
    AppColors.primaryGreen,
    AppColors.primaryDarkGreen,
    AppColors.accentOrange,
  ];

  @override
  Widget build(BuildContext context) {
    final title = (task['title'] as String?) ?? 'Nhiệm vụ';
    final category = (task['category'] as String?) ?? 'General';
    final points = (task['points'] as int?) ?? 0;
    final dueLabel = (task['dueLabel'] as String?) ?? 'Hôm nay';
    final done = (task['done'] as bool?) ?? false;

    final iconColor = _iconColors[index % _iconColors.length];
    final icon = _icons[index % _icons.length];
    final accent = index == 1
        ? AppColors.surfaceMutedLight
        : AppColors.surfaceLight;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.schedule_outlined,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      dueLabel,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                done ? '✓' : '+$points',
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'pts',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Achievement Section ────────────────────────────────────────────────────────

class _AchievementSection extends StatelessWidget {
  const _AchievementSection({required this.achievements, this.cityRank});

  final List<Map<String, dynamic>> achievements;
  final int? cityRank;

  static const _tints = [
    AppColors.primaryGreen,
    AppColors.primaryDarkGreen,
    AppColors.earthyBrown,
  ];

  static const _icons = [
    Icons.recycling_outlined,
    Icons.pedal_bike_outlined,
    Icons.local_fire_department,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THÀNH TÍCH GẦN ĐÂY',
            style: TextStyle(
              color: AppColors.primaryGreen,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          // Personalized rank message
          if (cityRank != null)
            _RankMessageBanner(rank: cityRank!),
          if (cityRank == null) const SizedBox(height: 0),
          const SizedBox(height: 12),
          if (achievements.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceMutedLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Text(
                'Hoàn thành nhiệm vụ để mở khóa thành tích! 🌱',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: achievements.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final tint = _tints[i % _tints.length];
                  final icon = _icons[i % _icons.length];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: i < achievements.length - 1 ? 10 : 0,
                    ),
                    child: _AchievementCard(
                      icon: icon,
                      title: (item['title'] as String?) ?? 'Achievement',
                      subtitle:
                          (item['subtitle'] as String?) ?? 'User milestone',
                      tint: tint,
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Shared small widgets ───────────────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, this.onTap});

  final String message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceMutedLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.primaryGreen,
              ),
          ],
        ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: AppColors.textSecondary),
      ),
    );
  }
}

class _HeaderStatCard extends StatelessWidget {
  const _HeaderStatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: iconColor,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatBadge extends StatelessWidget {
  const _MiniStatBadge({
    required this.title,
    required this.value,
    required this.accent,
  });

  final String title;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreLine extends StatelessWidget {
  const _ScoreLine({
    required this.label,
    required this.resetLabel,
    required this.valueText,
    required this.accent,
  });

  final String label;
  final String resetLabel;
  final String valueText;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row( // Thay Column bằng Row luôn cho gọn nếu chỉ có 1 dòng
      children: [
        const Icon(
          Icons.calendar_month_outlined,
          color: AppColors.textSecondary,
          size: 14,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          resetLabel,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
        const Spacer(),
        Text(
          valueText,
          style: TextStyle(
            color: accent,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 84,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tint.withValues(alpha: 0.24)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: tint, size: 21),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tint.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tint, size: 22),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: tint,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankMessageBanner extends StatelessWidget {
  const _RankMessageBanner({required this.rank});

  final int rank;

  String getRankMessage(int? rank) {
    if (rank == null || rank == 0) {
      return 'Hoàn thành nhiệm vụ để xuất hiện trên bảng xếp hạng nhé! 🌱';
    }

    if (rank == 1) {
      return 'Thật tuyệt vời! Bạn là Quán quân Xanh. Hãy giữ vững ngai vàng nhé! 👑';
    }

    if (rank <= 3) {
      return 'Xuất sắc! Bạn đang ở rất gần ngôi đầu. Chỉ một chút nữa thôi! 🏆';
    }

    if (rank <= 10) {
      return 'Chúc mừng! Bạn đã lọt vào nhóm 10 người dẫn đầu. Rất đáng nể! ⭐';
    }

    return 'Bạn đang đứng thứ #$rank. Hoàn thành thêm nhiệm vụ để bứt phá nhé! 💪';
  }

  @override
  Widget build(BuildContext context) {
    final msg = getRankMessage(rank);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_outlined, color: AppColors.primaryGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            '#$rank',
            style: const TextStyle(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}