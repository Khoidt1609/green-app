// lib/features/leaderboard/viewmodels/leaderboard_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_app/data/models/leaderboard_model.dart';
import 'package:green_app/data/repositories/leaderboard_repository.dart';

class LeaderboardState {
  final List<LeaderboardEntry> entries;
  final bool isLoading;
  final String? error;
  final LeaderboardPeriod period;
  final LeaderboardScope scope;
  final String? selectedFilter;
  final List<String> filterOptions;

  const LeaderboardState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
    this.period = LeaderboardPeriod.week,
    this.scope = LeaderboardScope.district,
    this.selectedFilter,
    this.filterOptions = const [],
  });

  LeaderboardState copyWith({
    List<LeaderboardEntry>? entries,
    bool? isLoading,
    String? error,
    LeaderboardPeriod? period,
    LeaderboardScope? scope,
    String? selectedFilter,
    List<String>? filterOptions,
    bool clearError = false,
    bool clearFilter = false,
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      period: period ?? this.period,
      scope: scope ?? this.scope,
      selectedFilter:
          clearFilter ? null : selectedFilter ?? this.selectedFilter,
      filterOptions: filterOptions ?? this.filterOptions,
    );
  }

  List<LeaderboardEntry> get top3 => entries.take(3).toList();
  List<LeaderboardEntry> get rest => entries.skip(3).toList();
}

class LeaderboardViewModel extends StateNotifier<LeaderboardState> {
  final LeaderboardRepository _repo;

  LeaderboardViewModel(this._repo) : super(const LeaderboardState()) {
    _init();
  }

  Future<void> _init() async {
    await _loadFilterOptions();
    await loadLeaderboard();
  }

  Future<void> _loadFilterOptions() async {
    try {
      final options = state.scope == LeaderboardScope.district
          ? await _repo.getDistincts()
          : await _repo.getCities();
      state = state.copyWith(filterOptions: options);
    } catch (_) {}
  }

  Future<void> loadLeaderboard() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final entries = await _repo.getLeaderboard(
        period: state.period,
        scope: state.scope,
        filterValue: state.selectedFilter,
      );
      state = state.copyWith(entries: entries, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Không thể tải bảng xếp hạng: $e',
      );
    }
  }

  Future<void> setPeriod(LeaderboardPeriod period) async {
    if (state.period == period) return;
    state = state.copyWith(period: period);
    await loadLeaderboard();
  }

  Future<void> setScope(LeaderboardScope scope) async {
    if (state.scope == scope) return;
    state = state.copyWith(scope: scope, clearFilter: true);
    await _loadFilterOptions();
    await loadLeaderboard();
  }

  Future<void> setFilter(String? filter) async {
    state = state.copyWith(
      selectedFilter: filter,
      clearFilter: filter == null,
    );
    await loadLeaderboard();
  }
}

final leaderboardViewModelProvider =
    StateNotifierProvider<LeaderboardViewModel, LeaderboardState>((ref) {
  return LeaderboardViewModel(ref.read(leaderboardRepositoryProvider));
});
