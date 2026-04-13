import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../router/app_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _index = 0;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      emoji: '🌱',
      title: 'Chào mừng đến\nGreenstep',
      badge: 'Nền tảng gamification bền vững hàng đầu Việt Nam',
      description:
          'Biến các hành động xanh hàng ngày thành điểm thưởng và giải thưởng tiền mặt thực sự.',
      accentStart: AppColors.primaryGreen,
      accentEnd: AppColors.primaryDarkGreen,
      cta: 'Tiếp theo',
    ),
    _OnboardingData(
      emoji: '🎯',
      title: 'Kiếm Điểm\nMỗi Ngày',
      badge: 'Hệ thống điểm Tuần + Tháng',
      description:
          'Mỗi hành động xanh = điểm thưởng. Điểm Tuần reset mỗi Chủ nhật. Điểm Tháng tích lũy để nhận giải thưởng lớn.',
      accentStart: AppColors.primaryDarkGreen,
      accentEnd: AppColors.primaryGreen,
      cta: 'Tiếp theo',
    ),
    _OnboardingData(
      emoji: '💰',
      title: 'Thắng Giải\nThưởng Thật',
      badge: 'Cash Rewards cho Top 3',
      description:
          'Top 1 nhận \$100 • Top 2 nhận \$50 • Top 3 nhận \$25. Bảng xếp hạng theo Phường và Thành phố.',
      accentStart: AppColors.accentOrange,
      accentEnd: AppColors.primaryGreen,
      cta: 'Bắt đầu ngay',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _skip() {
    Navigator.of(context).pushReplacementNamed(AppRouter.login);
  }

  void _next() {
    if (_index == _pages.length - 1) {
      _skip();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.6, -0.8),
            radius: 1.4,
            colors: [AppColors.primaryDarkGreen, AppColors.backgroundDark],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 20),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _skip,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      backgroundColor: Colors.white10,
                    ),
                    child: const Text('Bỏ qua'),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (value) => setState(() => _index = value),
                    itemCount: _pages.length,
                    itemBuilder: (context, pageIndex) {
                      final data = _pages[pageIndex];
                      return _OnboardingPage(data: data);
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (dotIndex) => AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _index == dotIndex ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: _index == dotIndex
                            ? AppColors.primaryGreen
                            : AppColors.primaryGreen.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [
                        _pages[_index].accentStart,
                        _pages[_index].accentEnd,
                      ],
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _next,
                      child: Center(
                        child: Text(
                          _pages[_index].cta,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
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

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _OnboardingData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 10),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 168,
            height: 168,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: Text(data.emoji, style: const TextStyle(fontSize: 74)),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 44,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              data.badge,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.4,
              fontSize: 17,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.emoji,
    required this.title,
    required this.badge,
    required this.description,
    required this.accentStart,
    required this.accentEnd,
    required this.cta,
  });

  final String emoji;
  final String title;
  final String badge;
  final String description;
  final Color accentStart;
  final Color accentEnd;
  final String cta;
}
