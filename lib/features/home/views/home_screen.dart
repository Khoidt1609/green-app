import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../router/app_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentTab = 0;
  bool _isLoadingProfile = true;
  bool _isLoadingTasks = true;
  Map<String, dynamic>? _profileData;
  List<Map<String, dynamic>> _tasks = const <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    await Future.wait([_loadProfile(), _loadTasks()]);
  }

  Future<void> _loadProfile() async {
    final authService = ref.read(authServiceProvider);
    final data = await authService.getCurrentUserProfile();

    if (!mounted) {
      return;
    }

    setState(() {
      _profileData = data;
      _isLoadingProfile = false;
    });
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).pushNamed(AppRouter.profile);
    await _loadDashboardData();
  }

  Future<void> _loadTasks() async {
    final authService = ref.read(authServiceProvider);
    final taskData = await authService.getCurrentUserTasks(limit: 3);

    if (!mounted) {
      return;
    }

    setState(() {
      _tasks = taskData;
      _isLoadingTasks = false;
    });
  }

  void _onTapBottomNav(int index) {
    setState(() {
      _currentTab = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        break;
      case 2:
        Navigator.of(context).pushNamed(AppRouter.tasks);
        break;
      case 3:
        break;
      case 4:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authService = ref.watch(authServiceProvider);
    
    final fullName = (_profileData?['fullName'] as String?)?.trim();
    final username = (_profileData?['username'] as String?)?.trim();
    final emailPrefix = authService.currentUser?.email?.split('@').first.trim();
    final displayName = (fullName != null && fullName.isNotEmpty)
      ? fullName
      : (username != null && username.isNotEmpty
            ? username
            : (emailPrefix != null && emailPrefix.isNotEmpty
                  ? emailPrefix
                  : 'user'));
    final avatarInitial = (username != null && username.isNotEmpty)
      ? username[0].toUpperCase()
      : ((emailPrefix != null && emailPrefix.isNotEmpty)
          ? emailPrefix[0].toUpperCase()
          : 'U');

    final totalPoints = (_profileData?['totalPoints'] as num?)?.toInt() ?? 0;
    final weeklyPoints = (_profileData?['weeklyPoints'] as num?)?.toInt() ?? 0;
    final monthlyPoints =
      (_profileData?['monthlyPoints'] as num?)?.toInt() ?? 0;
    final streakDays = (_profileData?['streakDays'] as num?)?.toInt() ?? 0;
    final cityRank = (_profileData?['cityRank'] as num?)?.toInt();
    final tasksDone = _tasks.where((task) => (task['done'] as bool?) ?? false).length;
    final achievementItems =
      (_profileData?['recentAchievements'] as List<dynamic>?) ??
      const <dynamic>[];

    final level = (totalPoints ~/ 1000) + 1;
    final levelProgress = ((totalPoints % 1000) / 1000).clamp(0, 1).toDouble();
    final weeklyProgress = (weeklyPoints / 600).clamp(0, 1).toDouble();
    final monthlyProgress = (monthlyPoints / 2000).clamp(0, 1).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1F14),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A160F), Color(0xFF102518), Color(0xFF0D1F14)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Good Morning ☘',
                                            style: TextStyle(
                                              color: Color(0xAA86C89B),
                                              fontSize: 12,
                                              height: 1.1,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            displayName,
                                            style: const TextStyle(
                                              color: Colors.white,
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
                                      onTap: _openProfile,
                                      child: Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: AppColors.primaryGreen,
                                            width: 1.4,
                                          ),
                                        ),
                                        child: Center(
                                          child: CircleAvatar(
                                            radius: 15,
                                            backgroundColor:
                                                AppColors.primaryGreen,
                                            child: Text(
                                              avatarInitial,
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
                                ),
                                const SizedBox(height: 16),
                                if (_isLoadingProfile)
                                  const SizedBox(
                                    height: 140,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF102517),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFF23412D),
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x1F000000),
                                          blurRadius: 18,
                                          offset: Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 54,
                                              height: 54,
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryGreen
                                                    .withValues(alpha: 0.16),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: AppColors.primaryGreen
                                                      .withValues(alpha: 0.22),
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  avatarInitial,
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.primaryGreen,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    displayName,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 16,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  const Text(
                                                    'Forest Guardian',
                                                    style: TextStyle(
                                                      color: Color(0xAA86C89B),
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            _MiniStatBadge(
                                              title: 'Total Pts',
                                              value: '$totalPoints',
                                              accent: const Color(0xFFF6C945),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        _ScoreLine(
                                          label: 'Điểm tuần',
                                          resetLabel: 'Reset Chủ nhật',
                                          valueText: '$weeklyPoints',
                                          totalText: '/600',
                                          progress: weeklyProgress,
                                          accent: AppColors.primaryGreen,
                                          percentText:
                                              '${(weeklyProgress * 100).round()}%',
                                        ),
                                        const SizedBox(height: 14),
                                        _ScoreLine(
                                          label: 'Điểm tháng',
                                          resetLabel: 'Reset cuối tháng',
                                          valueText: '$monthlyPoints',
                                          totalText: '/2,000',
                                          progress: monthlyProgress,
                                          accent: const Color(0xFF58B8FF),
                                          percentText:
                                              '${(monthlyProgress * 100).round()}%',
                                        ),
                                        const SizedBox(height: 14),
                                        Row(
                                          children: [
                                            const Expanded(
                                              child: Text(
                                                'Lv',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '$level / ${(level * 1000)}',
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withValues(alpha: 0.76),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          child: LinearProgressIndicator(
                                            value: levelProgress,
                                            minHeight: 7,
                                            backgroundColor: Colors.white
                                                .withValues(alpha: 0.14),
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _HeaderStatCard(
                                        icon: Icons.local_fire_department_outlined,
                                        iconColor: const Color(0xFFFF7F50),
                                        value: '${streakDays}d',
                                        label: 'Streak',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _HeaderStatCard(
                                        icon: Icons.check_circle_outline,
                                        iconColor: AppColors.primaryGreen,
                                        value: '$tasksDone',
                                        label: 'Tasks Done',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _HeaderStatCard(
                                        icon: Icons.star_border,
                                        iconColor: const Color(0xFFF6C945),
                                        value: cityRank != null ? '#$cityRank' : '--',
                                        label: 'City Rank',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: const [
                                    Expanded(
                                      child: _QuickActionTile(
                                        icon: Icons.camera_alt_outlined,
                                        label: 'Camera',
                                        tint: Color(0xFF16C46B),
                                        background: Color(0xFF113725),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: _QuickActionTile(
                                        icon: Icons.card_giftcard_outlined,
                                        label: 'Store',
                                        tint: Color(0xFFE2C12A),
                                        background: Color(0xFF2E2814),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: _QuickActionTile(
                                        icon: Icons.location_on_outlined,
                                        label: 'Map',
                                        tint: Color(0xFF44A8FF),
                                        background: Color(0xFF123043),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: const Color(0xFF7E6A17),
                                    ),
                                    color: const Color(0xFF2A270D),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFD74C),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.card_giftcard_rounded,
                                          color: Color(0xFF8A5A00),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Cửa Hàng Xanh',
                                              style: TextStyle(
                                                color: Color(0xFFF6C945),
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Bạn có $totalPoints điểm để đổi quà.',
                                              style: TextStyle(
                                                color: Color(0xFF9BC5A2),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: Color(0xFFF6C945),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Nhiệm vụ hôm nay',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Xem tất cả',
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (_isLoadingTasks)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                  )
                                else if (_tasks.isEmpty)
                                  const _EmptyDashboardState(
                                    message: 'Chưa có nhiệm vụ từ dữ liệu thật.',
                                  )
                                else
                                  ..._tasks.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final task = entry.value;
                                    final title =
                                        (task['title'] as String?)?.trim();
                                    final category =
                                        (task['category'] as String?)?.trim();
                                    final points =
                                        (task['points'] as num?)?.toInt() ?? 0;
                                    final dueLabel =
                                        (task['dueLabel'] as String?)?.trim();
                                    final done = (task['done'] as bool?) ?? false;

                                    final accent = index == 0
                                        ? const Color(0xFF1A5133)
                                        : index == 1
                                        ? const Color(0xFF183042)
                                        : const Color(0xFF3A3012);

                                    final iconColor = index == 0
                                        ? const Color(0xFF40D890)
                                        : index == 1
                                        ? const Color(0xFF5FC4FF)
                                        : const Color(0xFFFFD56A);

                                    final icon = index == 0
                                        ? Icons.recycling_outlined
                                        : index == 1
                                        ? Icons.pedal_bike_outlined
                                        : Icons.lightbulb_outline;

                                    final card = _TaskCard(
                                      icon: icon,
                                      iconColor: iconColor,
                                      title: title != null && title.isNotEmpty
                                          ? title
                                          : 'Nhiệm vụ',
                                      subtitle: category != null &&
                                              category.isNotEmpty
                                          ? category
                                          : 'General',
                                      timeLabel: dueLabel != null &&
                                              dueLabel.isNotEmpty
                                          ? dueLabel
                                          : (done ? 'Done' : 'Today'),
                                      points: done ? '✓' : '+$points',
                                      accent: accent,
                                    );

                                    if (index == _tasks.length - 1) {
                                      return card;
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: card,
                                    );
                                  }),
                                const SizedBox(height: 18),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF102517),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: const Color(0xFF23412D),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      const SizedBox(height: 12),
                                      if (achievementItems.isEmpty)
                                        const _EmptyDashboardState(
                                          message:
                                              'Chưa có thành tích từ dữ liệu thật.',
                                        )
                                      else
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: achievementItems
                                                .asMap()
                                                .entries
                                                .map((entry) {
                                                  final index = entry.key;
                                                  final raw = entry.value;
                                                  final map = raw is Map
                                                      ? raw
                                                      : <String, dynamic>{};
                                                  final title =
                                                      (map['title'] as String?)
                                                              ?.trim() ??
                                                          'Achievement';
                                                  final subtitle = (map[
                                                                  'subtitle']
                                                              as String?)
                                                          ?.trim() ??
                                                      'User milestone';

                                                  final tint = index % 3 == 0
                                                      ? const Color(0xFF38D98C)
                                                      : index % 3 == 1
                                                      ? const Color(0xFF5FC4FF)
                                                      : const Color(0xFFFFA24A);

                                                  return Padding(
                                                    padding: EdgeInsets.only(
                                                      right: index ==
                                                              achievementItems
                                                                      .length -
                                                                  1
                                                          ? 0
                                                          : 10,
                                                    ),
                                                    child: _AchievementCard(
                                                      icon: index % 3 == 0
                                                          ? Icons
                                                                .recycling_outlined
                                                          : index % 3 == 1
                                                          ? Icons
                                                                .pedal_bike_outlined
                                                          : Icons
                                                                .local_fire_department,
                                                      title: title,
                                                      subtitle: subtitle,
                                                      tint: tint,
                                                    ),
                                                  );
                                                })
                                                .toList(growable: false),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),
                              ],
                            ),
                          ),
                        ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF102517),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFF23412D),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: BottomNavigationBar(
                        type: BottomNavigationBarType.fixed,
                        currentIndex: _currentTab,
                        onTap: _onTapBottomNav,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        selectedItemColor: AppColors.primaryGreen,
                        unselectedItemColor: const Color(0xFF6C8471),
                        showUnselectedLabels: true,
                        items: const [
                          BottomNavigationBarItem(
                            icon: Icon(Icons.home_rounded),
                            label: 'Home',
                          ),
                          BottomNavigationBarItem(
                            icon: Icon(Icons.emoji_events_outlined),
                            label: 'Rank',
                          ),
                          BottomNavigationBarItem(
                            icon: Icon(Icons.task_alt_outlined),
                            label: 'Tasks',
                          ),
                          BottomNavigationBarItem(
                            icon: Icon(Icons.map_outlined),
                            label: 'Map',
                          ),
                          BottomNavigationBarItem(
                            icon: Icon(Icons.storefront_outlined),
                            label: 'Store',
                          ),
                        ],
                      ),
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

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF153726),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A5A3D)),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: const Color(0xFFB4D8BE)),
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
        color: const Color(0xFF102517),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF23412D)),
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
              color: Color(0xFF6D846F),
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
              color: Color(0xFF9BC5A2),
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
    required this.totalText,
    required this.progress,
    required this.accent,
    required this.percentText,
  });

  final String label;
  final String resetLabel;
  final String valueText;
  final String totalText;
  final double progress;
  final Color accent;
  final String percentText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              color: Color(0xFFB7D7BF),
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              resetLabel,
              style: const TextStyle(
                color: Color(0xFF7F9E86),
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
            Text(
              totalText,
              style: const TextStyle(
                color: Color(0xFF6D846F),
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: const Color(0xFF1A3424),
            color: accent,
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            percentText,
            style: const TextStyle(
              color: Color(0xFF7FD29D),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
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
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 84,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: background,
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

class _EmptyDashboardState extends StatelessWidget {
  const _EmptyDashboardState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF122A1C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF23412D)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFF8AB89A), fontSize: 12),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.points,
    required this.accent,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String timeLabel;
  final String points;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF23412D)),
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
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8AB89A),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.schedule_outlined,
                      size: 12,
                      color: Color(0xFF678B73),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        color: Color(0xFF678B73),
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
                points,
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'pts',
                style: TextStyle(color: Color(0xFF678B73), fontSize: 11),
              ),
            ],
          ),
        ],
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
        color: const Color(0xFF122B1D),
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
              color: Color(0xFF7E9D85),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
