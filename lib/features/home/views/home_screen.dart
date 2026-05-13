// lib/features/home/views/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_app/features/home/viewmodel/home_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../router/app_router.dart';
import '../../notifications/views/notification_bell.dart';
import '../../tasks/widgets/approved_submissions_list.dart';
import '../../leaderboard/viewmodels/leaderboard_viewmodel.dart';
import '../../../data/repositories/leaderboard_repository.dart';
import '../../../data/models/leaderboard_model.dart';

// Provider lấy user address và ranks tuần/tháng
final _userRanksProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return {};
  
  try {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data() ?? {};
    
    final address = data['address'] as Map<String, dynamic>? ?? {};
    final district = (address['district'] as String?)?.trim();
    final city = (address['city'] as String?)?.trim();
    
    if (district == null || city == null) return {};
    
    final repo = LeaderboardRepository(FirebaseFirestore.instance);
    
    // Lấy rank tuần
    final weekEntries = await repo.getLeaderboard(
      period: LeaderboardPeriod.week,
      scope: LeaderboardScope.district,
      filterValue: district,
    );
    
    int? weekRank;
    for (final entry in weekEntries) {
      if (entry.uid == user.uid) {
        weekRank = entry.rank;
        break;
      }
    }
    
    // Lấy rank tháng
    final monthEntries = await repo.getLeaderboard(
      period: LeaderboardPeriod.month,
      scope: LeaderboardScope.district,
      filterValue: district,
    );
    
    int? monthRank;
    for (final entry in monthEntries) {
      if (entry.uid == user.uid) {
        monthRank = entry.rank;
        break;
      }
    }
    
    return {
      'weekRank': weekRank,
      'monthRank': monthRank,
      'district': district,
      'city': city,
    };
  } catch (e) {
    return {};
  }
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    
    final vm = ref.read(homeViewModelProvider.notifier);
    final leaderboardState = ref.watch(leaderboardViewModelProvider);
    
    final homeState = ref.watch(homeViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFC),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.2,
            colors: [Color(0xFFE6F7EF), Color(0xFFFCFDFC)],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primaryGreen,
            onRefresh: vm.refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HomeHeader(
                    state: homeState,
                    onProfileTap: () async {
                      await Navigator.pushNamed(context, AppRouter.profile);
                      vm.refresh();
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (homeState.isLoadingProfile)
                          const _LoadingCard(height: 210)
                        else
                          _ProfileCard(state: homeState),
                        const SizedBox(height: 16),
                        _StatBadgeRow(
                          state: homeState,
                          rank: leaderboardState.currentUserEntry?.rank,
                        ),
                        const SizedBox(height: 16),
                        _StoreBanner(totalPoints: homeState.totalPoints),
                        const SizedBox(height: 24),
                        _SectionHeader(
                          title: 'Nhiệm vụ đã làm',
                          
                        ),
                        const SizedBox(height: 12),
                        const ApprovedSubmissionsList(),
                        const SizedBox(height: 24),
                        const _SectionHeader(title: 'Thành tích gần đây'),
                        const SizedBox(height: 12),
                        const _AchievementSection(
                          achievements: [],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header with gradient background ────────────────────────────────────────
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.state, required this.onProfileTap});

  final HomeState state;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        border: const Border(bottom: BorderSide(color: Color(0xFFE8F0EA))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chào buổi sáng 🌿',
                  style: TextStyle(
                    color: Color(0xFF55705E),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.displayName.isEmpty ? 'Người dùng' : state.displayName,
                  style: const TextStyle(
                    color: Color(0xFF10261E),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE0EDE4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const NotificationBell(iconColor: Color(0xFF2CC185)),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onProfileTap,
            child: _UserAvatar(
              avatarUrl: state.avatarUrl,
              displayName: state.displayName,
              size: 44,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile Card ────────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.state});
  final HomeState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE0EDE4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006C47).withOpacity(0.06),
            blurRadius: 36,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFF2CC185).withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _UserAvatar(
                    avatarUrl: state.avatarUrl,
                    displayName: state.displayName,
                    size: 56,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.displayName.isEmpty
                              ? 'Người dùng'
                              : state.displayName,
                          style: const TextStyle(
                            color: Color(0xFF10261E),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2CC185).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Thành viên GreenStep',
                            style: TextStyle(
                              color: Color(0xFF2CC185),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.9,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006C47),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF006C47).withOpacity(0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Total Pts',
                          style: TextStyle(
                            color: Color(0xFFB9F2D8),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${state.totalPoints}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _MiniSummaryTile(
                      icon: Icons.calendar_today,
                      label: 'Điểm tuần',
                      value: '${state.weekPoints}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniSummaryTile(
                      icon: Icons.event_note,
                      label: 'Điểm tháng',
                      value: '${state.monthPoints}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniSummaryTile extends StatelessWidget {
  const _MiniSummaryTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4EFE8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, size: 17, color: const Color(0xFF2CC185)),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF667A70),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            '$value pts',
            style: const TextStyle(
              color: Color(0xFF10261E),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
 class _UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;
  final double size;

  const _UserAvatar({
    required this.avatarUrl,
    required this.displayName,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final initial = displayName.isNotEmpty 
        ? displayName[0].toUpperCase() 
        : '?';

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(avatarUrl!),
        backgroundColor: AppColors.primaryGreen,
        onBackgroundImageError: (_, __) {
          // Fallback nếu load ảnh lỗi
        },
        child: null,
      );
    } else {
      // Fallback chữ cái
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          borderRadius: BorderRadius.circular(size),
        ),
        child: Center(
          child: Text(
            initial,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.45,
            ),
          ),
        ),
      );
    }
  }
}

// ── Stat Badge Row ──────────────────────────────────────────────────────────
class _StatBadgeRow extends ConsumerWidget {
  const _StatBadgeRow({required this.state, required this.rank});
  final HomeState state;
  final int? rank;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _ApprovedSubmissionsCountCard(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.emoji_events,
            iconColor: const Color(0xFFFF9800),
            value: '${rank ?? '-'}',
            label: 'Xếp hạng',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department,
            iconColor: const Color(0xFFFF6B35),
            value: '${state.streakDays}',
            label: 'Chuỗi',
          ),
        ),
      ],
    );
  }
}

// ── Approved Submissions Count Card ────────────────────────────────────────
class _ApprovedSubmissionsCountCard extends ConsumerWidget {
  const _ApprovedSubmissionsCountCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final countAsync = ref.watch(approvedSubmissionsCountProvider(uid));

    return countAsync.when(
      loading: () => const _StatCard(
        icon: Icons.check_circle,
        iconColor: Color(0xFF2CC185),
        value: '... ',
        label: 'Hoàn thành',
      ),
      error: (err, stack) => const _StatCard(
        icon: Icons.check_circle,
        iconColor: Color(0xFF2CC185),
        value: '0',
        label: 'Hoàn thành',
      ),
      data: (count) => _StatCard(
        icon: Icons.check_circle,
        iconColor: const Color(0xFF2CC185),
        value: '$count',
        label: 'Hoàn thành',
      ),
    );
  }
}

// ── Stat Card ───────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE0EDE4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF10261E),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF71867A),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Store Banner ────────────────────────────────────────────────────────────
class _StoreBanner extends StatelessWidget {
  final int totalPoints;

  const _StoreBanner({required this.totalPoints});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2CC185), Color(0xFF1F8D63)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2CC185).withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.shopping_basket, size: 30, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cửa Hàng Xanh',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bạn có $totalPoints điểm để đổi quà.',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Đi đến trang để đổi quà',
                  style: TextStyle(
                    color: Color(0xFFDDF8EE),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
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

// ── Challenge Card ──────────────────────────────────────────────────────────
class _ChallengeCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final int index;

  const _ChallengeCard({required this.task, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0F0E8), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  task['title'] ?? '',
                  style: const TextStyle(
                    color: Color(0xFF1A3D2A),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if ((task['done'] as bool?) ?? false)
                const Icon(
                  Icons.check_circle,
                  size: 18,
                  color: Color(0xFF2CC185),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task['description'] ?? '',
            style: const TextStyle(color: Color(0xFF999999), fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '+${task['points'] ?? 0} pts',
                style: const TextStyle(
                  color: Color(0xFF2CC185),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Loading Card ────────────────────────────────────────────────────────────
class _LoadingCard extends StatelessWidget {
  final double height;

  const _LoadingCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF5FBF8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}

// ── Empty State ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FBF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0F0E8), width: 1),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.sentiment_satisfied_alt,
              size: 48,
              color: Color(0xFFCCC),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF999999),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Achievement Section ─────────────────────────────────────────────────────
class _AchievementSection extends ConsumerWidget {
  final List<Map<String, dynamic>> achievements;

  const _AchievementSection({
    super.key,
    required this.achievements,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ranksAsync = ref.watch(_userRanksProvider);

    return ranksAsync.when(
      loading: () => _buildLoadingCard(),
      error: (err, st) => _buildEmptyCard(),
      data: (rankData) {
        final weekRank = rankData['weekRank'] as int?;
        final monthRank = rankData['monthRank'] as int?;
        final district = rankData['district'] as String?;
        final city = rankData['city'] as String?;

        final hasRankData = weekRank != null || monthRank != null;

        if (!hasRankData && achievements.isEmpty) {
          return _buildEmptyCard();
        }

        final rankCards = <Widget>[];
        if (weekRank != null && district != null && city != null) {
          rankCards.add(
            _buildRankCard(
              period: 'Tuần',
              rank: weekRank,
              district: district,
              city: city,
            ),
          );
        }
        if (monthRank != null && district != null && city != null) {
          rankCards.add(
            _buildRankCard(
              period: 'Tháng',
              rank: monthRank,
              district: district,
              city: city,
            ),
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFE0EDE4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF7FBF8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: Color(0xFF7A7A7A),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Địa phương',
                          style: TextStyle(
                            color: Color(0xFF10261E),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Xếp hạng tuần và tháng của bạn',
                          style: TextStyle(
                            color: Color(0xFF6E8077),
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...rankCards,
              if (achievements.isNotEmpty) ...[
                ...achievements.take(1).map((achievement) {
                  return _buildAchievementCard(
                    title: achievement['title'] ?? 'Thành tích mới',
                    description: achievement['description'] ?? 'Chúc mừng bạn đã đạt cột mốc mới',
                    icon: Icons.emoji_events_rounded,
                    iconColor: const Color(0xFFFFB300),
                  );
                }),
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE0EDE4)),
      ),
      child: const Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE0EDE4)),
      ),
      child: const Center(
        child: Text(
          'Chưa có thành tích nào gần đây',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildRankCard({
    required String period,
    required int rank,
    required String district,
    required String city,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8F0EA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Color(0xFFFF9800),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xếp hạng $period',
                  style: const TextStyle(
                    color: Color(0xFF10261E),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$city • $district: Hạng $rank',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6E8077),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFCCCCCC)),
        ],
      ),
    );
  }

  Widget _buildAchievementCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    Color? backgroundColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFFF8FBF9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: backgroundColor != null
              ? iconColor.withOpacity(0.18)
              : const Color(0xFFE8F0EA),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF10261E),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6E8077),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFCCCCCC)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF10261E),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(
              color: Color(0xFF2CC185),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}