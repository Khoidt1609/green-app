// lib/features/home/views/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_app/features/home/viewmodel/home_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../router/app_router.dart';
import '../../notifications/views/notification_bell.dart';
import '../../tasks/widgets/approved_submissions_list.dart';
import '../../leaderboard/viewmodels/leaderboard_viewmodel.dart';



class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    
    final vm = ref.read(homeViewModelProvider.notifier);
    final leaderboardState = ref.watch(leaderboardViewModelProvider);
    
    final homeState = ref.watch(homeViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F2),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: vm.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gradient Header
                _HomeHeader(
                  state: homeState,
                  onProfileTap: () async {
                    await Navigator.pushNamed(context, AppRouter.profile);
                    vm.refresh();
                  },
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Card
                      if (homeState.isLoadingProfile)
                        const _LoadingCard(height: 172)
                      else
                        _ProfileCard(state: homeState),

                      const SizedBox(height: 12),

                      // Stats
                      _StatBadgeRow(state: homeState),
                      const SizedBox(height: 12),

                      // Store Banner
                      _StoreBanner(totalPoints: homeState.totalPoints),
                      const SizedBox(height: 24),

                      // Tasks Section - Approved Submissions
                      const Text(
                        'Nhiệm vụ đã làm',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const ApprovedSubmissionsList(),

                      const SizedBox(height: 28),

                      // Achievements
                      const Text(
                        'Thành tích gần đây',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AchievementSection(
  achievements: homeState.recentAchievements,
  // 1. Lấy hạng từ currentUserEntry (đã có trong LeaderboardState của bạn)
  cityRank: leaderboardState.currentUserEntry?.rank ?? homeState.cityRank,
  
  // 2. Tên khu vực: Lấy từ nhãn có sẵn trong State (scopeLabel) hoặc bộ lọc đang chọn
  regionName: leaderboardState.selectedFilter ?? leaderboardState.scopeLabel,
  
  // 3. Phạm vi: Dùng biến scope có sẵn trong leaderboardState
  scope: leaderboardState.scope, 
),
                    ],
                  ),
                ),
              ],
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFCEECDA), Color(0xFFE4F4EB), Color(0xFFF0F7F2)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Text(
                      'Chào buổi sáng ',
                      style: TextStyle(
                        color: Color(0xFF3A7A56),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                    Text('🌿', style: TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  state.displayName.isEmpty ? 'Người dùng' : state.displayName,
                  style: const TextStyle(
                    color: Color(0xFF1A3D2A),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Notification bell
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: const Color(0xFFB2D9C2), width: 1.5),
            ),
            child: const NotificationBell(iconColor: Color(0xFF2E7D52)),
          ),

          const SizedBox(width: 8),

          // Avatar
          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Center(
                child: Text(
                  state.avatarInitial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0F0E8), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Center(
              child: Text(
                state.avatarInitial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.displayName.isEmpty ? 'Người dùng' : state.displayName,
                  style: const TextStyle(
                    color: Color(0xFF1A3D2A),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'THÀNH VIÊN GREENSTEP',
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF22996B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Text(
                  'TOTAL PTS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${state.totalPoints}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
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

// ── Stat Badge Row ──────────────────────────────────────────────────────────
class _StatBadgeRow extends ConsumerWidget {
  const _StatBadgeRow({required this.state});
  final HomeState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FBF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0F0E8), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Color(0xFF2CC185),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tuần này',
                            style: TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${state.weekPoints} pts',
                            style: const TextStyle(
                              color: Color(0xFF1A3D2A),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.date_range,
                      size: 16,
                      color: Color(0xFF2CC185),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tháng này',
                            style: TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${state.monthPoints} pts',
                            style: const TextStyle(
                              color: Color(0xFF1A3D2A),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ApprovedSubmissionsCountCard(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  icon: Icons.emoji_events,
                  iconColor: const Color(0xFFFF9800),
                  value: '${state.cityRank ?? '-'}',
                  label: 'Xếp hạng',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department,
                  iconColor: const Color(0xFFFF6B35),
                  value: '${state.streakDays}',
                  label: 'Chuỗi',
                ),
              ),
            ],
          ),
        ],
      ),
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
      loading: () => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0F0E8), width: 1),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
              ),
            ),
          ],
        ),
      ),
      error: (err, stack) => _StatCard(
        icon: Icons.check_circle,
        iconColor: const Color(0xFF2CC185),
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0F0E8), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1A3D2A),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 9,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2CC185), Color(0xFF22996B)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_bag, size: 32, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cửa Hàng Xanh',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bạn có $totalPoints điểm để đổi',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
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
// ── Achievement Section ─────────────────────────────────────────────────────
// ── Achievement Section ─────────────────────────────────────────────────────
class _AchievementSection extends StatelessWidget {
  final List<Map<String, dynamic>> achievements;
  final int? cityRank;
  final String regionName;
  final dynamic scope; // Nhận LeaderboardScope từ viewmodel

  const _AchievementSection({
    super.key,
    required this.achievements,
    this.cityRank,
    required this.regionName,
    required this.scope,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];

    // --- LOGIC 1: THẺ XẾP HẠNG KHU VỰC ---
    if (cityRank != null) {
      // Kiểm tra xem đang ở cấp độ Quận hay Thành phố dựa trên string value
      final bool isDistrict = scope.toString().contains('district');
      
      children.add(
        _buildAchievementCard(
          title: isDistrict ? 'Xếp hạng Quận/Huyện' : 'Xếp hạng Thành phố',
          description: 'Bạn đang đứng thứ #$cityRank tại $regionName',
          icon: isDistrict ? Icons.location_city_rounded : Icons.map_rounded,
          iconColor: isDistrict ? const Color(0xFF2196F3) : const Color(0xFFFF9800),
          backgroundColor: isDistrict 
              ? const Color(0xFFE3F2FD) // Xanh nhạt cho Quận
              : const Color(0xFFFFF9C4), // Vàng nhạt cho Thành phố
        ),
      );
    }

    // --- LOGIC 2: TRẠNG THÁI TRỐNG ---
    if (cityRank == null && achievements.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Text(
            'Chưa có thành tích nào gần đây',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    // --- LOGIC 3: DANH SÁCH THÀNH TÍCH KHÁC ---
    // Lấy tối đa 2 thành tích gần nhất để UI không bị quá dài
    children.addAll(
      achievements.take(2).map((achievement) {
        return _buildAchievementCard(
          title: achievement['title'] ?? 'Thành tích mới',
          description: achievement['description'] ?? 'Chúc mừng bạn đã đạt cột mốc mới',
          icon: Icons.emoji_events_rounded,
          iconColor: const Color(0xFFFFB300),
        );
      }),
    );

    return Column(children: children);
  }

  // --- UI COMPONENT: THẺ THÀNH TÍCH CHUẨN ---
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
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16), // Bo góc tròn theo ảnh mẫu
        border: Border.all(
          color: backgroundColor != null 
              ? iconColor.withOpacity(0.2) 
              : const Color(0xFFF0F0F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon nằm trong vòng tròn trắng để nổi bật
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          
          // Nội dung text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1A3D2A),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          
          // Mũi tên điều hướng
          const Icon(
            Icons.arrow_forward_ios_rounded, 
            size: 12, 
            color: Color(0xFFCCCCCC)
          ),
        ],
      ),
    );
  }
}