// lib/features/leaderboard/views/leaderboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/leaderboard_model.dart';
import '../viewmodels/leaderboard_viewmodel.dart';

const _kGold   = Color(0xFFFFD700);
const _kSilver = Color(0xFFB0BEC5);
const _kBronze = Color(0xFFCD7F32);

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state  = ref.watch(leaderboardViewModelProvider);
    final vm     = ref.read(leaderboardViewModelProvider.notifier);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        // Nút back: hiện khi được push từ màn hình khác
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text(
          '🏆  Bảng Xếp Hạng',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: vm.refresh,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          // Controls: period + scope + filter chips
          _Controls(state: state, vm: vm),

          // Prize banner — giải tuần < giải tháng, lấy từ period.prizes
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: _PrizeBanner(state: state),
          ),

          // Body
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryGreen))
                : state.error != null
                    ? _ErrorView(error: state.error!, onRetry: vm.loadLeaderboard)
                    : state.entries.isEmpty
                        ? _EmptyView(scopeLabel: state.scopeLabel)
                        : _Body(state: state, vm: vm),
          ),
        ],
      ),
    );
  }
}

// ─── Controls ─────────────────────────────────────────────────────────────────

class _Controls extends StatelessWidget {
  const _Controls({required this.state, required this.vm});
  final LeaderboardState    state;
  final LeaderboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Column(
        children: [
          // Row 1: Period + Scope
          Row(
            children: [
              Expanded(
                child: _Toggle<LeaderboardPeriod>(
                  options:  LeaderboardPeriod.values,
                  selected: state.period,
                  label:    (p) => p.label,
                  onSelect: vm.setPeriod,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Toggle<LeaderboardScope>(
                  options:  LeaderboardScope.values,
                  selected: state.scope,
                  label:    (s) => s.label,
                  onSelect: vm.setScope,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: Filter chips (quận hoặc tỉnh)
          if (state.filterOptions.isNotEmpty)
            _FilterRow(
              options:    state.filterOptions,
              selected:   state.selectedFilter,
              scopeLabel: state.scopeLabel,
              onChanged:  vm.setFilter,
            ),
        ],
      ),
    );
  }
}

class _Toggle<T> extends StatelessWidget {
  const _Toggle({
    required this.options,
    required this.selected,
    required this.label,
    required this.onSelect,
  });
  final List<T> options;
  final T selected;
  final String Function(T) label;
  final void Function(T) onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color:        scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: scheme.outline),
      ),
      child: Row(
        children: options.map((opt) {
          final active = opt == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color:        active ? AppColors.primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text(
                    label(opt),
                    style: TextStyle(
                      color:      active ? Colors.white : AppColors.textSecondary,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      fontSize:   12,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.options,
    required this.selected,
    required this.scopeLabel,
    required this.onChanged,
  });
  final List<String>     options;
  final String?          selected;
  final String           scopeLabel;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _Chip(
            label:    'Tất cả',
            selected: selected == null,
            onTap:    () => onChanged(null),
          ),
          const SizedBox(width: 8),
          ...options.map((o) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _Chip(
                  label:    o,
                  selected: selected == o,
                  onTap:    () => onChanged(o),
                ),
              )),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
  final String   label;
  final bool     selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color:        selected ? AppColors.primaryGreen : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: selected ? AppColors.primaryGreen : scheme.outline),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:      selected ? Colors.white : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize:   12,
          ),
        ),
      ),
    );
  }
}

// ─── Prize Banner ─────────────────────────────────────────────────────────────

class _PrizeBanner extends StatelessWidget {
  const _PrizeBanner({required this.state});
  final LeaderboardState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final prizes = state.prizes; // từ period.prizes — tuần < tháng

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: scheme.outline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _PrizeItem(medal: '🥇', label: 'Top 1', amount: prizes[1]!),
          _PrizeItem(medal: '🥈', label: 'Top 2', amount: prizes[2]!),
          _PrizeItem(medal: '🥉', label: 'Top 3', amount: prizes[3]!),
          Column(
            children: [
              Text(
                state.period == LeaderboardPeriod.week
                    ? '📅  Giải Tuần'
                    : '📅  Giải Tháng',
                style: const TextStyle(
                  color:      AppColors.primaryGreen,
                  fontWeight: FontWeight.w700,
                  fontSize:   12,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Reset tự động',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrizeItem extends StatelessWidget {
  const _PrizeItem({required this.medal, required this.label, required this.amount});
  final String medal, label, amount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(medal, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 2),
        Text(amount,
            style: TextStyle(
                color:      Theme.of(context).colorScheme.onSurface,
                fontSize:   13,
                fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
      ],
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.vm});
  final LeaderboardState    state;
  final LeaderboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color:    AppColors.primaryGreen,
      onRefresh: vm.refresh,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Podium Top 3
          if (state.top3.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                child: _Podium(top3: state.top3, prizes: state.prizes),
              ),
            ),

          // Header danh sách đầy đủ
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 6),
              child: Row(
                children: const [
                  Icon(Icons.format_list_numbered_rounded,
                      color: AppColors.primaryGreen, size: 15),
                  SizedBox(width: 6),
                  Text(
                    'BẢNG ĐẦY ĐỦ',
                    style: TextStyle(
                      color:       AppColors.textSecondary,
                      fontSize:    11,
                      fontWeight:  FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Toàn bộ danh sách (bao gồm cả top 3 để scroll liền mạch)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final entry = state.entries[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: _EntryRow(entry: entry, prize: state.prizes[entry.rank]),
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
}

// ─── Podium ───────────────────────────────────────────────────────────────────

class _Podium extends StatefulWidget {
  const _Podium({required this.top3, required this.prizes});
  final List<LeaderboardEntry> top3;
  final Map<int, String>       prizes;

  @override
  State<_Podium> createState() => _PodiumState();
}

class _PodiumState extends State<_Podium> with TickerProviderStateMixin {
  late final List<AnimationController> _ctrl;
  late final List<Animation<double>>   _fade;
  late final List<Animation<Offset>>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = List.generate(3, (i) => AnimationController(
        vsync: this, duration: Duration(milliseconds: 400 + i * 100)));
    _fade  = _ctrl.map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut)).toList();
    _slide = _ctrl.map((c) => Tween<Offset>(
          begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic))).toList();
    for (int i = 0; i < _ctrl.length; i++) {
      Future.delayed(Duration(milliseconds: i * 80),
          () { if (mounted) _ctrl[i].forward(); });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrl) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.top3;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
      decoration: BoxDecoration(
        color:        Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 🥈 rank 2 (trái)
          if (t.length > 1)
            Expanded(
              child: FadeTransition(opacity: _fade[1],
                child: SlideTransition(position: _slide[1],
                  child: _PodiumCard(entry: t[1], medal: _kSilver,
                      isFirst: false, prize: widget.prizes[2]))),
            )
          else const Spacer(),
          const SizedBox(width: 8),
          // 🥇 rank 1 (giữa, cao hơn)
          Expanded(
            child: FadeTransition(opacity: _fade[0],
              child: SlideTransition(position: _slide[0],
                child: _PodiumCard(entry: t[0], medal: _kGold,
                    isFirst: true, prize: widget.prizes[1]))),
          ),
          const SizedBox(width: 8),
          // 🥉 rank 3 (phải)
          if (t.length > 2)
            Expanded(
              child: FadeTransition(opacity: _fade[2],
                child: SlideTransition(position: _slide[2],
                  child: _PodiumCard(entry: t[2], medal: _kBronze,
                      isFirst: false, prize: widget.prizes[3]))),
            )
          else const Spacer(),
        ],
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    required this.entry,
    required this.medal,
    required this.isFirst,
    this.prize,
  });
  final LeaderboardEntry entry;
  final Color  medal;
  final bool   isFirst;
  final String? prize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sz = isFirst ? 56.0 : 44.0;
    final fz = isFirst ? 14.0 : 12.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isFirst)
          const Text('👑', style: TextStyle(fontSize: 22))
        else
          const SizedBox(height: 26),
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: sz, height: sz,
              decoration: BoxDecoration(
                color:        medal.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(isFirst ? 18 : 14),
                border:       Border.all(color: medal, width: isFirst ? 2.5 : 2),
              ),
              child: Center(
                child: Text(entry.avatarInitial,
                    style: TextStyle(color: medal,
                        fontSize: isFirst ? 22 : 17, fontWeight: FontWeight.w900)),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(color: medal, borderRadius: BorderRadius.circular(5)),
              child: Text('#${entry.rank}',
                  style: const TextStyle(color: Colors.black,
                      fontSize: 9, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(entry.displayName,
            style: TextStyle(color: scheme.onSurface,
                fontSize: fz, fontWeight: FontWeight.w800),
            maxLines: 1, overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center),
        // ── Location từ Firebase address ──
        if (entry.locationLabel.isNotEmpty)
          Text(entry.locationLabel,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
              maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        const SizedBox(height: 3),
        Text(_fmtPts(entry.points),
            style: const TextStyle(color: AppColors.primaryGreen,
                fontSize: 11, fontWeight: FontWeight.w700)),
        if (prize != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color:        scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border:       Border.all(color: scheme.outline),
            ),
            child: Text(prize!,
                style: TextStyle(color: scheme.onSurface,
                    fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
        const SizedBox(height: 6),
        Text(entry.rank == 1 ? '🥇' : entry.rank == 2 ? '🥈' : '🥉',
            style: const TextStyle(fontSize: 17)),
      ],
    );
  }
}

// ─── Entry Row ────────────────────────────────────────────────────────────────

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, this.prize});
  final LeaderboardEntry entry;
  final String?          prize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:        scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text('#${entry.rank}',
                style: const TextStyle(color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w800, fontSize: 14)),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.18),
            child: Text(entry.avatarInitial,
                style: const TextStyle(color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w800, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.displayName,
                    style: TextStyle(color: scheme.onSurface,
                        fontWeight: FontWeight.w700, fontSize: 14),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                // ── Location từ Firebase address ──
                if (entry.locationLabel.isNotEmpty)
                  Text(entry.locationLabel,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_fmtPts(entry.points),
                  style: const TextStyle(color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w800, fontSize: 15)),
              if (prize != null)
                Text(prize!,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Empty / Error ─────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.scopeLabel});
  final String scopeLabel;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.people_outline_rounded,
          color: AppColors.textSecondary, size: 52),
      const SizedBox(height: 12),
      Text('Chưa có dữ liệu cho $scopeLabel này.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          textAlign: TextAlign.center),
    ]),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String   error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.wifi_off_rounded, color: AppColors.textSecondary, size: 48),
      const SizedBox(height: 12),
      Text(error,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          textAlign: TextAlign.center),
      const SizedBox(height: 16),
      OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Thử lại')),
    ]),
  );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _fmtPts(int n) {
  if (n >= 1000) {
    final k = n / 1000;
    return k == k.truncateToDouble() ? '${k.toInt()}k pts' : '${k.toStringAsFixed(1)}k pts';
  }
  return '$n pts';
}