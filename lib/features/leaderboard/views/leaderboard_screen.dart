import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import 'package:green_app/data/models/leaderboard_model.dart';
import '../viewmodels/leaderboard_viewmodel.dart';

// Medal colors (không đổi vì đây là màu cố định cho huy chương)
const _gold = Color(0xFFFFD700);
const _silver = Color(0xFFB0BEC5);
const _bronze = Color(0xFFCD7F32);

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(leaderboardViewModelProvider);
    final vm = ref.read(leaderboardViewModelProvider.notifier);

    // ── Lấy màu từ Theme ──────────────────────
    final scheme = Theme.of(context).colorScheme;
    final green = AppColors.primaryGreen;

    return Scaffold(
      // AppBar dùng theme mặc định từ AppTheme
      appBar: AppBar(
        title: const Text('Bảng xếp hạng'),
        // leading tự động hiển thị nút back khi có Navigator stack,
        // nhưng ta override để đảm bảo luôn có nút back
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, state, vm),
            Expanded(
              child: state.isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: green),
                    )
                  : state.error != null
                      ? _buildError(context, state.error!, vm)
                      : _buildBody(context, state, vm),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────
  Widget _buildHeader(
    BuildContext context,
    LeaderboardState state,
    LeaderboardViewModel vm,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final green = AppColors.primaryGreen;
    final textSub = Theme.of(context)
            .textTheme
            .bodyMedium
            ?.color
            ?.withValues(alpha: 0.7) ??
        Colors.grey.shade600;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '🏆  Bảng Xếp Hạng',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              _FilterDropdown(
                scope: state.scope,
                options: state.filterOptions,
                selected: state.selectedFilter,
                onScopeChanged: vm.setScope,
                onFilterChanged: vm.setFilter,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Period toggle
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outline),
            ),
            child: Row(
              children: [
                _PeriodTab(
                  label: '📅  Tuần này',
                  active: state.period == LeaderboardPeriod.week,
                  onTap: () => vm.setPeriod(LeaderboardPeriod.week),
                ),
                _PeriodTab(
                  label: '📅  Tháng này',
                  active: state.period == LeaderboardPeriod.month,
                  onTap: () => vm.setPeriod(LeaderboardPeriod.month),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Prize info banner
          _PrizeBanner(period: state.period),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Body ────────────────────────────────────
  Widget _buildBody(
      BuildContext context, LeaderboardState state, LeaderboardViewModel vm) {
    final green = AppColors.primaryGreen;
    final scheme = Theme.of(context).colorScheme;
    final textSub = Theme.of(context)
            .textTheme
            .bodyMedium
            ?.color
            ?.withValues(alpha: 0.7) ??
        Colors.grey.shade600;

    return RefreshIndicator(
      color: green,
      backgroundColor: scheme.surface,
      onRefresh: vm.loadLeaderboard,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Top 3 podium
          if (state.top3.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _Top3Podium(top3: state.top3),
              ),
            ),
          // Full list header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.format_list_numbered_rounded,
                      color: green, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'BẢNG XẾP HẠNG ĐẦY ĐỦ',
                    style: TextStyle(
                      color: textSub,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Full list rows
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final entry = state.entries[index];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _LeaderboardRow(entry: entry),
                );
              },
              childCount: state.entries.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildError(
      BuildContext context, String error, LeaderboardViewModel vm) {
    final green = AppColors.primaryGreen;
    final textSub = Theme.of(context)
            .textTheme
            .bodyMedium
            ?.color
            ?.withValues(alpha: 0.7) ??
        Colors.grey.shade600;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, color: textSub, size: 48),
          const SizedBox(height: 12),
          Text(
            error,
            style: TextStyle(color: textSub),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: vm.loadLeaderboard,
            icon: Icon(Icons.refresh, color: green),
            label: Text('Thử lại', style: TextStyle(color: green)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Prize Banner
// ─────────────────────────────────────────────
class _PrizeBanner extends StatelessWidget {
  const _PrizeBanner({required this.period});
  final LeaderboardPeriod period;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final green = AppColors.primaryGreen;
    final textSub = Theme.of(context)
            .textTheme
            .bodyMedium
            ?.color
            ?.withValues(alpha: 0.7) ??
        Colors.grey.shade600;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          const _PrizeChip(medal: '🥇', amount: r'$100', label: 'Top 1'),
          const SizedBox(width: 12),
          const _PrizeChip(medal: '🥈', amount: r'$50', label: 'Top 2'),
          const SizedBox(width: 12),
          const _PrizeChip(medal: '🥉', amount: r'$25', label: 'Top 3'),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                period == LeaderboardPeriod.week ? 'Giải Tuần' : 'Giải Tháng',
                style: TextStyle(
                  color: green,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'P. Bình Thạnh',
                style: TextStyle(color: textSub, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrizeChip extends StatelessWidget {
  const _PrizeChip(
      {required this.medal, required this.amount, required this.label});
  final String medal;
  final String amount;
  final String label;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final textSub = Theme.of(context)
            .textTheme
            .bodyMedium
            ?.color
            ?.withValues(alpha: 0.7) ??
        Colors.grey.shade600;

    return Column(
      children: [
        Text(medal, style: const TextStyle(fontSize: 18)),
        Text(
          amount,
          style: TextStyle(
            color: onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(label, style: TextStyle(color: textSub, fontSize: 10)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Period Tab
// ─────────────────────────────────────────────
class _PeriodTab extends StatelessWidget {
  const _PeriodTab(
      {required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final green = AppColors.primaryGreen;
    final textSub = Theme.of(context)
            .textTheme
            .bodyMedium
            ?.color
            ?.withValues(alpha: 0.7) ??
        Colors.grey.shade600;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? green : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : textSub,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Filter Dropdown
// ─────────────────────────────────────────────
class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.scope,
    required this.options,
    required this.selected,
    required this.onScopeChanged,
    required this.onFilterChanged,
  });
  final LeaderboardScope scope;
  final List<String> options;
  final String? selected;
  final ValueChanged<LeaderboardScope> onScopeChanged;
  final ValueChanged<String?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textSub = Theme.of(context)
            .textTheme
            .bodyMedium
            ?.color
            ?.withValues(alpha: 0.7) ??
        Colors.grey.shade600;

    return GestureDetector(
      onTap: () => _showFilterSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outline),
        ),
        child: Row(
          children: [
            Icon(Icons.people_outline_rounded, color: textSub, size: 14),
            const SizedBox(width: 5),
            Text(
              selected ??
                  (scope == LeaderboardScope.district
                      ? 'Phường ▾'
                      : 'Quận ▾'),
              style: TextStyle(color: textSub, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FilterSheet(
        scope: scope,
        options: options,
        selected: selected,
        onScopeChanged: (s) {
          onScopeChanged(s);
          Navigator.pop(ctx);
        },
        onFilterChanged: (f) {
          onFilterChanged(f);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({
    required this.scope,
    required this.options,
    required this.selected,
    required this.onScopeChanged,
    required this.onFilterChanged,
  });
  final LeaderboardScope scope;
  final List<String> options;
  final String? selected;
  final ValueChanged<LeaderboardScope> onScopeChanged;
  final ValueChanged<String?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final green = AppColors.primaryGreen;
    final textSub = Theme.of(context)
            .textTheme
            .bodyMedium
            ?.color
            ?.withValues(alpha: 0.7) ??
        Colors.grey.shade600;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lọc theo khu vực',
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ScopeChip(
                label: 'Quận/Huyện',
                active: scope == LeaderboardScope.district,
                onTap: () => onScopeChanged(LeaderboardScope.district),
              ),
              const SizedBox(width: 8),
              _ScopeChip(
                label: 'Tỉnh/Thành phố',
                active: scope == LeaderboardScope.city,
                onTap: () => onScopeChanged(LeaderboardScope.city),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (options.isEmpty)
            Text('Không có dữ liệu', style: TextStyle(color: textSub))
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    dense: true,
                    title: Text(
                      'Tất cả',
                      style: TextStyle(color: scheme.onSurface),
                    ),
                    leading: Icon(
                      selected == null
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selected == null ? green : textSub,
                      size: 18,
                    ),
                    onTap: () => onFilterChanged(null),
                  ),
                  ...options.map((o) => ListTile(
                        dense: true,
                        title: Text(
                          o,
                          style: TextStyle(color: scheme.onSurface),
                        ),
                        leading: Icon(
                          selected == o
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: selected == o ? green : textSub,
                          size: 18,
                        ),
                        onTap: () => onFilterChanged(o),
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip(
      {required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final green = AppColors.primaryGreen;
    final textSub = Theme.of(context)
            .textTheme
            .bodyMedium
            ?.color
            ?.withValues(alpha: 0.7) ??
        Colors.grey.shade600;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? green.withValues(alpha: 0.2)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? green : scheme.outline),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? green : textSub,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Top 3 Podium with animation
// ─────────────────────────────────────────────
class _Top3Podium extends StatefulWidget {
  const _Top3Podium({required this.top3});
  final List<LeaderboardEntry> top3;

  @override
  State<_Top3Podium> createState() => _Top3PodiumState();
}

class _Top3PodiumState extends State<_Top3Podium> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500 + i * 120),
      ),
    );
    _fadeAnims = _controllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .toList();
    _slideAnims = _controllers
        .map((c) => Tween<Offset>(
              begin: const Offset(0, 0.25),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic)))
        .toList();

    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top3 = widget.top3;
    if (top3.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final textSub = Theme.of(context)
            .textTheme
            .bodyMedium
            ?.color
            ?.withValues(alpha: 0.7) ??
        Colors.grey.shade600;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: _gold, size: 15),
              const SizedBox(width: 6),
              Text(
                'BẢNG VINH DANH TOP 3',
                style: TextStyle(
                  color: textSub,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd place
              if (top3.length > 1)
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnims[1],
                    child: SlideTransition(
                      position: _slideAnims[1],
                      child: _PodiumCard(
                        entry: top3[1],
                        medalColor: _silver,
                        isFirst: false,
                        prize: r'$50',
                      ),
                    ),
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: 8),
              // 1st place (taller)
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnims[0],
                  child: SlideTransition(
                    position: _slideAnims[0],
                    child: _PodiumCard(
                      entry: top3[0],
                      medalColor: _gold,
                      isFirst: true,
                      prize: r'$100',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 3rd place
              if (top3.length > 2)
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnims[2],
                    child: SlideTransition(
                      position: _slideAnims[2],
                      child: _PodiumCard(
                        entry: top3[2],
                        medalColor: _bronze,
                        isFirst: false,
                        prize: r'$25',
                      ),
                    ),
                  ),
                )
              else
                const Spacer(),
            ],
          ),
        ),
      ],
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    required this.entry,
    required this.medalColor,
    required this.isFirst,
    required this.prize,
  });
  final LeaderboardEntry entry;
  final Color medalColor;
  final bool isFirst;
  final String prize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final green = AppColors.primaryGreen;
    final textSub = Theme.of(context)
            .textTheme
            .bodyMedium
            ?.color
            ?.withValues(alpha: 0.7) ??
        Colors.grey.shade600;

    final avatarSize = isFirst ? 56.0 : 46.0;
    final fontSize = isFirst ? 14.0 : 12.0;
    final rankLabel = '#${entry.rank}';

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isFirst)
          const Text('👑', style: TextStyle(fontSize: 20))
        else
          const SizedBox(height: 24),
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isFirst ? 18 : 14),
                color: medalColor.withValues(alpha: 0.18),
                border:
                    Border.all(color: medalColor, width: isFirst ? 2.5 : 2),
              ),
              child: Center(
                child: Text(
                  entry.avatarInitial ?? 'U',
                  style: TextStyle(
                    color: medalColor,
                    fontSize: isFirst ? 22 : 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: medalColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                rankLabel,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          entry.displayName,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          '${_formatNum(entry.points)} pts',
          style: TextStyle(color: green, fontSize: 11),
        ),
        const SizedBox(height: 6),
        // Prize badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: scheme.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.credit_card_rounded, size: 11, color: textSub),
              const SizedBox(width: 3),
              Text(
                prize,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          entry.rank == 1
              ? '🥇'
              : entry.rank == 2
                  ? '🥈'
                  : '🥉',
          style: const TextStyle(fontSize: 18),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Full list row
// ─────────────────────────────────────────────
class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry});
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final green = AppColors.primaryGreen;
    final textSub = Theme.of(context)
            .textTheme
            .bodyMedium
            ?.color
            ?.withValues(alpha: 0.7) ??
        Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 28,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                color: green,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: green.withValues(alpha: 0.2),
            child: Text(
              entry.avatarInitial ?? 'U',
              style: TextStyle(
                color: green,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name & location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.district != null)
                  Text(
                    'P. ${entry.district}',
                    style: TextStyle(color: textSub, fontSize: 11),
                  ),
              ],
            ),
          ),
          // Points + prize
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatNum(entry.points),
                style: TextStyle(
                  color: green,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              if (entry.rank <= 3)
                Row(
                  children: [
                    Icon(Icons.credit_card_rounded,
                        size: 10, color: textSub),
                    const SizedBox(width: 3),
                    Text(
                      entry.rank == 1
                          ? r'$100'
                          : entry.rank == 2
                              ? r'$50'
                              : r'$25',
                      style: TextStyle(color: textSub, fontSize: 11),
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

// ─────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────
String _formatNum(int n) {
  if (n >= 1000) {
    return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 3).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')}k'
        .replaceAll('.', ',');
  }
  return n.toString();
}