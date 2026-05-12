// lib/features/leaderboard/viewmodels/leaderboard_viewmodel.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/leaderboard_model.dart';
import '../../../data/repositories/leaderboard_repository.dart';

// ─────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────

class LeaderboardState {
  const LeaderboardState({
    this.entries = const [],
    this.top3 = const [],
    this.currentUserEntry,

    this.isLoading = false,
    this.isRefreshing = false,
    this.isFilterLoading = false,

    this.error,

    this.period = LeaderboardPeriod.week,
    this.scope = LeaderboardScope.district,

    this.selectedFilter,

    this.filterOptions = const [],

    this.requestId = 0,
  });

  // ─────────────────────────────

  final List<LeaderboardEntry> entries;

  final List<LeaderboardEntry> top3;

  final LeaderboardEntry? currentUserEntry;

  // ─────────────────────────────

  final bool isLoading;

  final bool isRefreshing;

  final bool isFilterLoading;

  // ─────────────────────────────

  final String? error;

  // ─────────────────────────────

  final LeaderboardPeriod period;

  final LeaderboardScope scope;

  // ─────────────────────────────

  final String? selectedFilter;

  final List<String> filterOptions;

  // ─────────────────────────────

  final int requestId;

  // ─────────────────────────────
  // GETTERS
  // ─────────────────────────────

  bool get hasError =>
      error != null &&
      error!.trim().isNotEmpty;

  bool get isEmpty =>
      entries.isEmpty;

  bool get hasActiveFilter =>
      selectedFilter != null &&
      selectedFilter!.trim().isNotEmpty;

  bool get hasEntries =>
      entries.isNotEmpty;

  bool get hasCurrentUser =>
      currentUserEntry != null;

  bool get showPinnedCurrentUser {
    if (currentUserEntry == null) {
      return false;
    }

    return !entries.any(
      (e) => e.uid == currentUserEntry!.uid,
    );
  }

  Map<int, String> get prizes =>
      period.prizes;

  String get scopeLabel =>
      scope.label;

  String get periodLabel =>
      period.label;

  // ─────────────────────────────
  // COPY WITH
  // ─────────────────────────────

  LeaderboardState copyWith({
    List<LeaderboardEntry>? entries,

    List<LeaderboardEntry>? top3,

    LeaderboardEntry? currentUserEntry,

    bool? isLoading,
    bool? isRefreshing,
    bool? isFilterLoading,

    String? error,

    LeaderboardPeriod? period,

    LeaderboardScope? scope,

    String? selectedFilter,

    List<String>? filterOptions,

    int? requestId,

    bool clearError = false,

    bool clearFilter = false,

    bool clearCurrentUser = false,
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,

      top3: top3 ?? this.top3,

      currentUserEntry: clearCurrentUser
          ? null
          : currentUserEntry ??
              this.currentUserEntry,

      isLoading:
          isLoading ?? this.isLoading,

      isRefreshing:
          isRefreshing ??
          this.isRefreshing,

      isFilterLoading:
          isFilterLoading ??
          this.isFilterLoading,

      error:
          clearError
              ? null
              : error ?? this.error,

      period:
          period ?? this.period,

      scope:
          scope ?? this.scope,

      selectedFilter:
          clearFilter
              ? null
              : selectedFilter ??
                  this.selectedFilter,

      filterOptions:
          filterOptions ??
          this.filterOptions,

      requestId:
          requestId ?? this.requestId,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// VIEWMODEL
// ─────────────────────────────────────────────────────────────

class LeaderboardViewModel
    extends StateNotifier<LeaderboardState> {
  LeaderboardViewModel(
    this._repo,
  ) : super(const LeaderboardState()) {
    _init();
  }

  // ─────────────────────────────

  final LeaderboardRepository _repo;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  int _requestCounter = 0;

  // ─────────────────────────────
  // INIT
  // ─────────────────────────────

  Future<void> _init() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      await Future.wait([
        _loadFilterOptions(),
        loadLeaderboard(),
      ]);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
      );
    }
  }

  // ─────────────────────────────
  // FILTER OPTIONS
  // ─────────────────────────────

  Future<void> _loadFilterOptions() async {
    state = state.copyWith(
      isFilterLoading: true,
    );

    try {
      final options =
          state.scope ==
                  LeaderboardScope.district
              ? await _repo.getDistricts()
              : await _repo.getCities();

      state = state.copyWith(
        filterOptions: options,
        isFilterLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isFilterLoading: false,
      );
    }
  }

  // ─────────────────────────────
  // LOAD LEADERBOARD
  // ─────────────────────────────

  Future<void> loadLeaderboard({
    bool isRefresh = false,
  }) async {
    final requestId = ++_requestCounter;

    if (isRefresh) {
      state = state.copyWith(
        isRefreshing: true,
        clearError: true,
        requestId: requestId,
      );
    } else {
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        requestId: requestId,
      );
    }

    try {
      final entries =
          await _repo.getLeaderboard(
        period: state.period,
        scope: state.scope,
        filterValue:
            state.selectedFilter,
      );

      // request cũ -> bỏ

      if (requestId != state.requestId) {
        return;
      }

      final top3 =
          entries.take(3).toList();

      final currentUid =
          _auth.currentUser?.uid;

      LeaderboardEntry?
          currentUserEntry;

      if (currentUid != null) {
        try {
          currentUserEntry =
              entries.firstWhere(
            (e) => e.uid == currentUid,
          );
        } catch (_) {}
      }

      state = state.copyWith(
        entries: entries,

        top3: top3,

        currentUserEntry:
            currentUserEntry,

        isLoading: false,

        isRefreshing: false,
      );
    } catch (_) {
      if (requestId != state.requestId) {
        return;
      }

      state = state.copyWith(
        isLoading: false,

        isRefreshing: false,

        error:
            'Không thể tải bảng xếp hạng.',
      );
    }
  }

  // ─────────────────────────────
  // PERIOD
  // ─────────────────────────────

  Future<void> setPeriod(
    LeaderboardPeriod period,
  ) async {
    if (state.period == period) {
      return;
    }

    state = state.copyWith(
      period: period,
    );

    await loadLeaderboard();
  }

  // ─────────────────────────────
  // SCOPE
  // ─────────────────────────────

  Future<void> setScope(
    LeaderboardScope scope,
  ) async {
    if (state.scope == scope) {
      return;
    }

    state = state.copyWith(
      scope: scope,
      clearFilter: true,
    );

    await Future.wait([
      _loadFilterOptions(),
      loadLeaderboard(),
    ]);
  }

  // ─────────────────────────────
  // FILTER
  // ─────────────────────────────

  Future<void> setFilter(
    String? value,
  ) async {
    final normalized =
        value?.trim();

    if (normalized ==
        state.selectedFilter) {
      return;
    }

    state = state.copyWith(
      selectedFilter: normalized,
      clearFilter:
          normalized == null ||
          normalized.isEmpty,
    );

    await loadLeaderboard();
  }

  // ─────────────────────────────
  // CLEAR FILTER
  // ─────────────────────────────

  Future<void> clearFilter() async {
    if (!state.hasActiveFilter) {
      return;
    }

    state = state.copyWith(
      clearFilter: true,
    );

    await loadLeaderboard();
  }

  // ─────────────────────────────
  // REFRESH
  // ─────────────────────────────

  Future<void> refresh() async {
    if (state.isRefreshing) {
      return;
    }

    await Future.wait([
      _loadFilterOptions(),

      loadLeaderboard(
        isRefresh: true,
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────

final leaderboardViewModelProvider =
    StateNotifierProvider<
      LeaderboardViewModel,
      LeaderboardState
    >(
  (ref) {
    return LeaderboardViewModel(
      ref.read(
        leaderboardRepositoryProvider,
      ),
    );
  },
);