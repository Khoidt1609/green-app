// lib/features/home/views/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_app/features/home/viewmodel/home_viewmodel.dart';

import '../../../core/constants/app_colors.dart';
import '../../../router/app_router.dart';
import '../viewmodel/home_viewmodel.dart';

// --- ĐÃ THÊM: Import Widget chiếc chuông thông báo ---
import '../../notifications/views/notification_bell.dart';
// --------------------------------------------------------

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);
    final vm = ref.read(homeViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: vm.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                _HomeHeader(
                  state: state,
                  onProfileTap: () async {
                    await Navigator.pushNamed(
                      context,
                      AppRouter.profile,
                    );

                    vm.refresh();
                  },
                ),

                const SizedBox(height: 18),

                // PROFILE CARD
                if (state.isLoadingProfile)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  _ProfileCard(state: state),

                const SizedBox(height: 14),

                // STATS
                _StatRow(state: state),

                const SizedBox(height: 18),

                // STORE BANNER
                _StoreBanner(
                  totalPoints: state.totalPoints,
                ),

                const SizedBox(height: 22),

                // TASK TITLE
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Nhiệm vụ gần đây',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRouter.tasks,
                        );
                      },
                      child: const Text('Xem tất cả'),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // TASKS
                if (state.isLoadingTasks)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (state.recentTasks.isEmpty)
                  _EmptyCard(
                    text:
                        'Bạn chưa có nhiệm vụ nào gần đây.',
                  )
                else
                  ...state.recentTasks.map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TaskCard(task: task),
                    ),
                  ),

                const SizedBox(height: 22),

                // ACHIEVEMENTS
                _AchievementSection(
                  achievements: state.recentAchievements,
                  cityRank: state.cityRank,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// HEADER

class _HomeHeader extends StatelessWidget {
  final HomeState state;
  final VoidCallback onProfileTap;

  const _HomeHeader({
    required this.state,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Good Morning 🌱',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                state.displayName.isEmpty
                    ? 'Người dùng'
                    : state.displayName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // --- ĐÃ THAY ĐỔI: Sử dụng chuông thông báo mới ---
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: const NotificationBell(iconColor: AppColors.textSecondary),
        ),
        // -------------------------------------------------

        const SizedBox(width: 8),
        GestureDetector(
          onTap: onProfileTap,
          child: CircleAvatar(
            radius: 22,
            backgroundColor:
                AppColors.primaryGreen,
            child: Text(
              state.avatarInitial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// PROFILE CARD

class _ProfileCard extends StatelessWidget {
  final HomeState state;

  const _ProfileCard({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.04,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    AppColors.primaryGreen,
                child: Text(
                  state.avatarInitial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.displayName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${state.totalPoints} điểm',
                      style: const TextStyle(
                        color: AppColors
                            .textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _PointRow(
            title: 'Điểm tuần',
            value: state.weekPoints,
          ),

          const SizedBox(height: 12),

          _PointRow(
            title: 'Điểm tháng',
            value: state.monthPoints,
          ),
        ],
      ),
    );
  }
}

class _PointRow extends StatelessWidget {
  final String title;
  final int value;

  const _PointRow({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          '$value',
          style: const TextStyle(
            color: AppColors.primaryGreen,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}

// STATS

class _StatRow extends StatelessWidget {
  final HomeState state;

  const _StatRow({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Hoàn thành',
            value:
                '${state.tasksDoneCount}',
            icon: Icons.check_circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            title: 'Xếp hạng',
            value: state.cityRank == null
                ? '--'
                : '#${state.cityRank}',
            icon: Icons.leaderboard,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primaryGreen,
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// STORE BANNER

class _StoreBanner extends StatelessWidget {
  final int totalPoints;

  const _StoreBanner({
    required this.totalPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryDarkGreen,
          ],
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.card_giftcard,
            color: Colors.white,
            size: 34,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cửa hàng đổi thưởng',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bạn đang có $totalPoints điểm',
                  style: const TextStyle(
                    color: Colors.white70,
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

// TASK CARD

class _TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;

  const _TaskCard({
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final title =
        task['title'] ?? 'Nhiệm vụ';
    final category =
        task['category'] ?? '';
    final points =
        task['points'] ?? 0;
    final done =
        task['done'] ?? false;
    final dueLabel =
        task['dueLabel'] ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen
                  .withOpacity(0.12),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.task_alt,
              color:
                  AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$category • $dueLabel',
                  style: const TextStyle(
                    color: AppColors
                        .textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            done ? '✓' : '+$points',
            style: const TextStyle(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

// ACHIEVEMENT

class _AchievementSection
    extends StatelessWidget {
  final List<Map<String, dynamic>>
      achievements;
  final int? cityRank;

  const _AchievementSection({
    required this.achievements,
    required this.cityRank,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'THÀNH TÍCH',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color:
                  AppColors.primaryGreen,
            ),
          ),

          const SizedBox(height: 12),

          if (cityRank != null)
            Text(
              'Bạn đang đứng hạng #$cityRank 🌟',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),

          const SizedBox(height: 14),

          if (achievements.isEmpty)
            const Text(
              'Chưa có thành tích nào.',
            )
          else
            Column(
              children: achievements
                  .map(
                    (a) => Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 10,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            color: AppColors
                                .primaryGreen,
                          ),
                          const SizedBox(
                              width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  a['title'] ??
                                      '',
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .w700,
                                  ),
                                ),
                                Text(
                                  a['subtitle'] ??
                                      '',
                                  style:
                                      const TextStyle(
                                    fontSize: 12,
                                    color: AppColors
                                        .textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

// EMPTY

class _EmptyCard extends StatelessWidget {
  final String text;

  const _EmptyCard({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}