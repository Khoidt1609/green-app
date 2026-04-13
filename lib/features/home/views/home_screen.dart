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

  void _onTapBottomNav(int index) {
    setState(() {
      _currentTab = index;
    });

    if (index == 1) {
      Navigator.of(context).pushNamed(AppRouter.tasks);
    } else if (index == 4) {
      Navigator.of(context).pushNamed(AppRouter.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final user = authService.currentUser;
    final email = user?.email ?? 'Chưa có email';

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.85),
            radius: 1.5,
            colors: [AppColors.primaryDarkGreen, AppColors.backgroundDark],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                14,
                                16,
                                18,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primaryDarkGreen,
                                    AppColors.primaryGreen,
                                  ],
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.white,
                                        child: Icon(
                                          Icons.person,
                                          color: AppColors.primaryDarkGreen,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Xin chào trở lại',
                                              style: TextStyle(
                                                color: Color(0xCCFFFFFF),
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              email,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () async {
                                          await authService.signOut();
                                        },
                                        tooltip: 'Đăng xuất',
                                        icon: const Icon(
                                          Icons.logout_rounded,
                                          color: Colors.white,
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
                                      color: AppColors.textSecondary.withValues(
                                        alpha: 0.2,
                                      ),
                                      border: Border.all(
                                        color: AppColors.textSecondary
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: const [
                                              Text(
                                                'Tổng điểm GreenXP',
                                                style: TextStyle(
                                                  color: Color(0xCCFFFFFF),
                                                  fontSize: 12,
                                                ),
                                              ),
                                              SizedBox(height: 6),
                                              Text(
                                                '-- XP',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 34,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Hạng: --',
                                                style: TextStyle(
                                                  color: Color(0xCCFFFFFF),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'Streak: -- ngày',
                                                style: TextStyle(
                                                  color: Color(0xCCFFFFFF),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        SizedBox(
                                          width: 96,
                                          height: 96,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: const [
                                              CircularProgressIndicator(
                                                value: 0,
                                                strokeWidth: 8,
                                                backgroundColor: Colors.white
                                                    .withValues(alpha: 0.33),
                                                color: Colors.white,
                                              ),
                                              Text(
                                                '--%',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Lv --',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      Text(
                                        '-- / --',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: const LinearProgressIndicator(
                                      value: 0,
                                      minHeight: 8,
                                      backgroundColor: Color(0x44FFFFFF),
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              color: const Color(0xFFF4F7F6),
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                14,
                                14,
                                16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      _StatsTile(
                                        icon:
                                            Icons.energy_savings_leaf_outlined,
                                        value: '--',
                                        label: 'CO₂ tiết kiệm',
                                        iconColor: AppColors.primaryGreen,
                                      ),
                                      SizedBox(width: 8),
                                      _StatsTile(
                                        icon: Icons.track_changes_outlined,
                                        value: '--',
                                        label: 'Nhiệm vụ',
                                        iconColor: Color(0xFF7F68EE),
                                      ),
                                      SizedBox(width: 8),
                                      _StatsTile(
                                        icon: Icons
                                            .local_fire_department_outlined,
                                        value: '--',
                                        label: 'Streak',
                                        iconColor: Color(0xFFFF7043),
                                      ),
                                      SizedBox(width: 8),
                                      _StatsTile(
                                        icon: Icons.bolt_outlined,
                                        value: '--',
                                        label: 'Tuần này',
                                        iconColor: Color(0xFFF7A800),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'Nhiệm vụ đang hoạt động',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(
                                          context,
                                        ).pushNamed(AppRouter.tasks),
                                        child: const Text('Xem tất cả'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const _TaskPlaceholderCard(),
                                  const SizedBox(height: 10),
                                  const _TaskPlaceholderCard(),
                                  const SizedBox(height: 10),
                                  const _TaskPlaceholderCard(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    BottomNavigationBar(
                      type: BottomNavigationBarType.fixed,
                      currentIndex: _currentTab,
                      onTap: _onTapBottomNav,
                      selectedItemColor: AppColors.primaryGreen,
                      unselectedItemColor: AppColors.textSecondary,
                      showUnselectedLabels: true,
                      items: const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.home_outlined),
                          label: 'Trang chủ',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.task_outlined),
                          label: 'Nhiệm vụ',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.emoji_events_outlined),
                          label: 'Xếp hạng',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.map_outlined),
                          label: 'Bản đồ',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.shield_outlined),
                          label: 'Admin',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsTile extends StatelessWidget {
  const _StatsTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskPlaceholderCard extends StatelessWidget {
  const _TaskPlaceholderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.15),
                child: Icon(
                  Icons.assignment_outlined,
                  size: 16,
                  color: AppColors.primaryGreen,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Nhiệm vụ trống',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Chip(label: Text('Chưa có')),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'User chưa tạo dữ liệu nhiệm vụ.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: 0,
            minHeight: 6,
            backgroundColor: AppColors.textSecondary.withValues(alpha: 0.2),
            color: AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }
}
