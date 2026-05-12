// lib/features/leaderboard/views/leaderboard_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/vietnam_geography_api.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/leaderboard_model.dart';
import '../viewmodels/leaderboard_viewmodel.dart';

const _kGold = Color(0xFFFFD54F);
const _kSilver = Color(0xFFCFD8DC);
const _kBronze = Color(0xFFD7A56D);

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      leaderboardViewModelProvider,
    );

    final vm = ref.read(
      leaderboardViewModelProvider.notifier,
    );

    final canPop =
        Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        elevation: 0,

        centerTitle: true,

        leading: canPop
            ? IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                ),
              )
            : null,

        title: const Text(
          '🏆 Bảng Xếp Hạng',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Làm mới',

            onPressed: state.isRefreshing
                ? null
                : vm.refresh,

            icon: state.isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                  ),
          ),
        ],
      ),

      body: Column(
        children: [
          _TopControls(
            state: state,
            vm: vm,
          ),
          Expanded(
            child: _buildBody(
              context,
              state,
              vm,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    LeaderboardState state,
    LeaderboardViewModel vm,
  ) {
    if (state.isLoading &&
        state.entries.isEmpty) {
      return const _LoadingView();
    }

    if (state.hasError) {
      return _ErrorView(
        message: state.error!,
        onRetry: vm.refresh,
      );
    }

    if (state.entries.isEmpty) {
      return _EmptyView(
        scopeLabel:
            state.scope.emptyLabel,
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryGreen,

      onRefresh: vm.refresh,

      child: CustomScrollView(
        physics:
            const BouncingScrollPhysics(),

        slivers: [
          SliverToBoxAdapter(
  child: Padding(
    padding:
        const EdgeInsets.fromLTRB(
      16,
      4,
      16,
      10,
    ),

    child: _RewardBanner(
      period: state.period,
    ),
  ),
),
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                4,
                16,
                0,
              ),
              child: _Podium(
                entries: state.top3,
                prizes: state.prizes,
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 18),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.leaderboard_rounded,
                    color:
                        AppColors.primaryGreen,
                    size: 18,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    state.hasActiveFilter
                        ? 'BXH ${state.selectedFilter}'
                        : 'BẢNG XẾP HẠNG',

                    style: const TextStyle(
                      color:
                          AppColors.textSecondary,
                      fontSize: 12,
                      letterSpacing: 1,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 10),
          ),

          SliverPadding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 16,
            ),

            sliver: SliverList(
              delegate:
                  SliverChildBuilderDelegate(
                (context, index) {
                  final entry =
                      state.entries[index];

                  if (entry.rank <= 3) {
                    return const SizedBox
                        .shrink();
                  }

                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 10,
                    ),

                    child: _LeaderboardTile(
                      entry: entry,
                      prize: state.prizes[
                          entry.rank],
                    ),
                  );
                },

                childCount:
                    state.entries.length,
              ),
            ),
          ),

          if (state.showPinnedCurrentUser)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  18,
                  16,
                  24,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VỊ TRÍ CỦA BẠN',
                      style: TextStyle(
                        color:
                            AppColors.textSecondary,
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 10),

                    _LeaderboardTile(
                      entry:
                          state.currentUserEntry!,
                      isPinnedCurrentUser:
                          true,
                    ),
                  ],
                ),
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _TopControls extends StatelessWidget {
  const _TopControls({
    required this.state,
    required this.vm,
  });

  final LeaderboardState state;

  final LeaderboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        10,
      ),

      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SegmentControl<
                    LeaderboardPeriod>(
                  options:
                      LeaderboardPeriod.values,

                  selected:
                      state.period,

                  labelBuilder:
                      (e) => e.label,

                  onChanged:
                      vm.setPeriod,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _SegmentControl<
                    LeaderboardScope>(
                  options:
                      LeaderboardScope.values,

                  selected:
                      state.scope,

                  labelBuilder:
                      (e) => e.label,

                  onChanged:
                      vm.setScope,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          InkWell(
            borderRadius:
                BorderRadius.circular(14),

            onTap: () {
              _showFilterSheet(
                context,
                state,
                vm,
              );
            },

            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),

              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surface,

                borderRadius:
                    BorderRadius.circular(
                  14,
                ),

                border: Border.all(
                  color:
                      Theme.of(context)
                          .dividerColor,
                ),
              ),

              child: Row(
                children: [
                  const Icon(
                    Icons.filter_alt_rounded,
                    color:
                        AppColors.primaryGreen,
                    size: 20,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      state.selectedFilter ??
                          'Lọc theo ${state.scope.label}',

                      style: TextStyle(
                        color:
                            state.selectedFilter !=
                                    null
                                ? Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                : AppColors
                                    .textSecondary,

                        fontSize: 14,

                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),

                  if (state.isFilterLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            AppColors.primaryGreen,
                      ),
                    )
                  else
                    const Icon(
                      Icons
                          .keyboard_arrow_down_rounded,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(
    BuildContext context,
    LeaderboardState state,
    LeaderboardViewModel vm,
  ) {
    showModalBottomSheet(
      context: context,

      isScrollControlled: true,

      backgroundColor:
          Colors.transparent,

      builder: (_) {
        return _FilterSheet(
          state: state,
          vm: vm,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.state,
    required this.vm,
  });

  final LeaderboardState state;
  final LeaderboardViewModel vm;

  @override
  State<_FilterSheet> createState() =>
      _FilterSheetState();
}

class _FilterSheetState
    extends State<_FilterSheet> {
  final _api = VietnamGeographyApi();

  List<dynamic> provinces = [];
  List<dynamic> districts = [];

  bool isLoading = true;

  String search = '';

  String? selectedProvinceCode;
  String? selectedDistrictCode;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  Future<void> _loadProvinces() async {
    try {
      final data = await _api.getProvinces();

      if (!mounted) return;
      setState(() {
        provinces = data;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadDistricts(String province) async {
    setState(() {
      districts = [];
      selectedProvinceCode = province;
      selectedDistrictCode = null;
      search = '';
    });

    try {
      final data = await _api.getDistricts(province);

      if (!mounted) return;
      setState(() {
        districts = data;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isCity =
        widget.state.scope == LeaderboardScope.city;

    final items = isCity
        ? provinces
            .where((e) {
              final name = (e['name'] ?? '').toString().toLowerCase();
              return name.contains(search.toLowerCase().trim());
            })
            .toList()
        : selectedDistrictCode != null
            ? districts
                .where((e) =>
                    e['code'].toString() == selectedDistrictCode)
                .toList()
            : districts
                .where((e) {
                  final name = (e['name'] ?? '').toString().toLowerCase();
                  return name.contains(search.toLowerCase().trim());
                })
                .toList();

    return Container(
      height:
          MediaQuery.of(context)
                  .size
                  .height *
              0.84,

      decoration: BoxDecoration(
        color:
            Theme.of(context)
                .colorScheme
                .surface,

        borderRadius:
            const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),

      child: Column(
        children: [
          const SizedBox(height: 12),

          Container(
            width: 46,
            height: 5,

            decoration: BoxDecoration(
              color: Colors.grey.shade400,

              borderRadius:
                  BorderRadius.circular(
                999,
              ),
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
            ),

            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isCity
                        ? 'Chọn Tỉnh / Thành'
                        : 'Chọn Quận / Huyện',

                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),

                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);

                    await widget.vm
                        .clearFilter();
                  },

                  child:
                      const Text('Xóa lọc'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
            ),

            child: TextField(
              onChanged: (v) {
                setState(() {
                  search = v;
                });
              },

              decoration: InputDecoration(
                hintText: 'Tìm kiếm...',

                prefixIcon: const Icon(
                  Icons.search_rounded,
                ),

                filled: true,

                fillColor:
                    Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,

                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),

                  borderSide:
                      BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (!isCity)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tỉnh / Thành phố',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedProvinceCode,
                        hint: const Text('Chọn tỉnh/thành'),
                        items: provinces.map((e) {
                          return DropdownMenuItem<String>(
                            value: e['code'].toString(),
                            child: Text(
                              e['name'],
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          _loadDistricts(value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),

          if (!isCity && selectedProvinceCode != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quận / Huyện',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedDistrictCode,
                        hint: const Text('Chọn quận/huyện'),
                        items: districts.map((e) {
                          return DropdownMenuItem<String>(
                            value: e['code'].toString(),
                            child: Text(
                              e['name'],
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            selectedDistrictCode = value;
                            search = '';
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),

          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  )
                : items.isEmpty
                    ? const Center(
                        child: Text(
                          'Không có dữ liệu để lọc',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        itemBuilder: (_, index) {
                          final item = items[index] as Map<String, dynamic>;
                          final name = (item['name'] ?? '').toString();
                          final selected =
                              widget.state.selectedFilter == name;

                          return InkWell(
                            borderRadius:
                                BorderRadius.circular(16),
                            onTap: () async {
                              Navigator.pop(context);
                              await widget.vm.setFilter(name);
                            },
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 15,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primaryGreen
                                        .withValues(alpha: 0.1)
                                    : Colors.transparent,
                                borderRadius:
                                    BorderRadius.circular(16),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primaryGreen
                                      : Theme.of(context)
                                          .dividerColor,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontWeight:
                                            FontWeight.w700,
                                        color: selected
                                            ? AppColors.primaryGreen
                                            : null,
                                      ),
                                    ),
                                  ),
                                  if (selected)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color:
                                          AppColors.primaryGreen,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemCount: items.length,
                      ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _SegmentControl<T>
    extends StatelessWidget {
  const _SegmentControl({
    required this.options,
    required this.selected,
    required this.labelBuilder,
    required this.onChanged,
  });

  final List<T> options;

  final T selected;

  final String Function(T)
      labelBuilder;

  final void Function(T) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,

      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surface,

        borderRadius:
            BorderRadius.circular(14),

        border: Border.all(
          color:
              Theme.of(context)
                  .dividerColor,
        ),
      ),

      child: Row(
        children: options.map((e) {
          final active =
              e == selected;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                onChanged(e);
              },

              child: AnimatedContainer(
                duration:
                    const Duration(
                  milliseconds: 220,
                ),

                margin:
                    const EdgeInsets.all(4),

                decoration:
                    BoxDecoration(
                  color: active
                      ? AppColors
                          .primaryGreen
                      : Colors
                          .transparent,

                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),

                child: Center(
                  child: Text(
                    labelBuilder(e),

                    style: TextStyle(
                      fontWeight:
                          FontWeight.w700,

                      color: active
                          ? Colors.white
                          : AppColors
                              .textSecondary,

                      fontSize: 12,
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

// ─────────────────────────────────────────────────────────────

class _RewardBanner
    extends StatelessWidget {
  const _RewardBanner({
    required this.period,
  });

  final LeaderboardPeriod period;

  @override
  Widget build(BuildContext context) {
    final prizes =
        period.prizes;

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
      ),

      child: Container(
        padding:
            const EdgeInsets.all(14),

        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryGreen,
              AppColors.primaryDarkGreen,
            ],
          ),

          borderRadius:
              BorderRadius.circular(
            22,
          ),

          boxShadow: [
            BoxShadow(
              color: AppColors
                  .primaryGreen
                  .withValues(alpha: 0.25),

              blurRadius: 16,

              offset:
                  const Offset(0, 6),
            ),
          ],
        ),

        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  '🎁',
                  style:
                      TextStyle(fontSize: 24),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    period.rewardTitle,

                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight:
                          FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),

                  decoration:
                      BoxDecoration(
                    color: Colors.white
                        .withValues(
                          alpha: 0.18,
                        ),

                    borderRadius:
                        BorderRadius
                            .circular(
                      999,
                    ),
                  ),

                  child: Text(
                    period.label,

                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontWeight:
                          FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,

              children: [
                _PrizeBox(
                  medal: '🥇',
                  amount:
                      prizes[1] ?? '',
                ),

                _PrizeBox(
                  medal: '🥈',
                  amount:
                      prizes[2] ?? '',
                ),

                _PrizeBox(
                  medal: '🥉',
                  amount:
                      prizes[3] ?? '',
                ),

                _PrizeBox(
                  medal: '🏅',
                  amount:
                      prizes[4] ?? '',
                ),

                _PrizeBox(
                  medal: '🎖️',
                  amount:
                      prizes[5] ?? '',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _PrizeBox extends StatelessWidget {
  const _PrizeBox({
    required this.medal,
    required this.amount,
  });

  final String medal;

  final String amount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          medal,
          style:
              const TextStyle(fontSize: 22),
        ),

        const SizedBox(height: 6),

        Text(
          amount,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
// ─────────────────────────────────────────────────────────────

// FIX OVERFLOW PODIUM
// THAY TOÀN BỘ class _Podium

class _Podium extends StatelessWidget {
  const _Podium({
    required this.entries,
    required this.prizes,
  });

  final List<LeaderboardEntry> entries;
  final Map<int, String> prizes;

  @override
  Widget build(BuildContext context) {
    final first =
        entries.where((e) => e.rank == 1).firstOrNull;

    final second =
        entries.where((e) => e.rank == 2).firstOrNull;

    final third =
        entries.where((e) => e.rank == 3).firstOrNull;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.end,
        children: [
          Expanded(
            child: second != null
                ? _PodiumCard(
                    entry: second,
                    height: 155,
                    color: _kSilver,
                    medal: '🥈',
                    prize:
                        prizes[2] ?? '',
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: first != null
                ? _PodiumCard(
                    entry: first,
                    height: 190,
                    color: _kGold,
                    medal: '🥇',
                    prize:
                        prizes[1] ?? '',
                    isChampion: true,
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: third != null
                ? _PodiumCard(
                    entry: third,
                    height: 140,
                    color: _kBronze,
                    medal: '🥉',
                    prize:
                        prizes[3] ?? '',
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

// THAY TOÀN BỘ class _PodiumCard

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    required this.entry,
    required this.height,
    required this.color,
    required this.medal,
    required this.prize,
    this.isChampion = false,
  });

  final LeaderboardEntry entry;
  final double height;
  final Color color;
  final String medal;
  final String prize;
  final bool isChampion;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isChampion)
          const Padding(
            padding:
                EdgeInsets.only(bottom: 4),
            child: Text(
              '👑',
              style:
                  TextStyle(fontSize: 24),
            ),
          ),

        CircleAvatar(
          radius: isChampion ? 34 : 28,
          backgroundColor: color,
          child: Text(
            entry.avatarInitial,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          height: 38,
          child: Column(
            children: [
              Flexible(
                child: Text(
                  entry.displayName,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),

              if (entry.locationLabel
                  .isNotEmpty)
                Flexible(
                  child: Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 2,
                    ),
                    child: Text(
                      entry.locationLabel,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        fontSize: 10,
                        color: AppColors
                            .textSecondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        Container(
          height: height,

          decoration: BoxDecoration(
            color: color,

            borderRadius:
                const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),

          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 10,
              ),

              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [
                  Text(
                    medal,
                    style: const TextStyle(
                      fontSize: 28,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '#${entry.rank}',
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Flexible(
                    child: Text(
                      '${entry.points} điểm',
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      textAlign:
                          TextAlign.center,
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),

                    decoration:
                        BoxDecoration(
                      color: Colors.white
                          .withValues(
                        alpha: 0.28,
                      ),

                      borderRadius:
                          BorderRadius
                              .circular(
                        999,
                      ),
                    ),

                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        prize,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight
                                  .w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _LeaderboardTile
    extends StatelessWidget {
  const _LeaderboardTile({
    required this.entry,
    this.prize,
    this.isPinnedCurrentUser =
        false,
  });

  final LeaderboardEntry entry;
  final String? prize;
  final bool isPinnedCurrentUser;

  @override
  Widget build(BuildContext context) {
    final isTop3 = entry.rank <= 3;

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(22),

      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 10,
          sigmaY: 10,
        ),

        child: Container(
          padding:
              const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: isPinnedCurrentUser
                ? AppColors.primaryGreen
                    .withValues(
                    alpha: 0.10,
                  )
                : Theme.of(context)
                    .colorScheme
                    .surface,

            borderRadius:
                BorderRadius.circular(
              22,
            ),

            border: Border.all(
              color: isPinnedCurrentUser
                  ? AppColors
                      .primaryGreen
                  : Theme.of(context)
                      .dividerColor,
            ),
          ),

          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,

                alignment:
                    Alignment.center,

                decoration:
                    BoxDecoration(
                  color: isTop3
                      ? _rankColor(
                          entry.rank,
                        )
                      : AppColors
                          .primaryGreen
                          .withValues(
                          alpha: 0.12,
                        ),

                  borderRadius:
                      BorderRadius
                          .circular(
                    14,
                  ),
                ),

                child: Text(
                  '#${entry.rank}',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w900,

                    color: isTop3
                        ? Colors.black
                        : AppColors
                            .primaryGreen,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              CircleAvatar(
                radius: 24,
                backgroundColor:
                    AppColors.primaryGreen,
                child: Text(
                  entry.avatarInitial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry
                                .displayName,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight
                                      .w800,
                              fontSize: 15,
                            ),
                          ),
                        ),

                        if (isPinnedCurrentUser)
                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration:
                                BoxDecoration(
                              color: AppColors
                                  .primaryGreen,

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                999,
                              ),
                            ),
                            child:
                                const Text(
                              'Bạn',
                              style:
                                  TextStyle(
                                color: Colors
                                    .white,
                                fontSize: 10,
                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    if (entry.locationLabel
                        .isNotEmpty)
                      Text(
                        entry.locationLabel,
                        style:
                            const TextStyle(
                          color: AppColors
                              .textSecondary,
                          fontSize: 12,
                        ),
                      ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 16,
                          color:
                              Colors.orange,
                        ),

                        const SizedBox(
                          width: 5,
                        ),

                        Text(
                          '${entry.points} điểm',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .w800,
                            color:
                                AppColors
                                    .primaryGreen,
                          ),
                        ),

                        if (prize != null)
                          Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              left: 10,
                            ),
                            child:
                                Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal:
                                    8,
                                vertical: 4,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: AppColors
                                    .accentOrange
                                    .withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  999,
                                ),
                              ),
                              child: Text(
                                prize!,
                                style:
                                    const TextStyle(
                                  color:
                                      AppColors
                                          .accentOrange,
                                  fontSize:
                                      10,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return _kGold;
      case 2:
        return _kSilver;
      case 3:
        return _kBronze;
      default:
        return AppColors.primaryGreen;
    }
  }
}

// ─────────────────────────────────────────────────────────────

class _LoadingView
    extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child:
          CircularProgressIndicator(
        color: AppColors.primaryGreen,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.scopeLabel,
  });

  final String scopeLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 32,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Text(
              '🏆',
              style:
                  TextStyle(fontSize: 70),
            ),

            const SizedBox(height: 18),

            const Text(
              'Chưa có dữ liệu',
              style: TextStyle(
                fontWeight:
                    FontWeight.w800,
                fontSize: 22,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Hiện chưa có người chơi nào trong bộ lọc $scopeLabel.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color:
                    AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function()
      onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 28,
        ),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 70,
            ),

            const SizedBox(height: 16),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight:
                    FontWeight.w700,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed: onRetry,

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primaryGreen,
                foregroundColor:
                    Colors.white,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),

              icon: const Icon(
                Icons.refresh_rounded,
              ),

              label: const Text(
                'Thử lại',
              ),
            ),
          ],
        ),
      ),
    );
  }
}