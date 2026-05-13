import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeState {
  final bool isLoadingProfile;
  final bool isLoadingTasks;
  final String? error;

  final String displayName;
  final String avatarInitial;

  final int totalPoints;
  final int currentPoints;
  final int weekPoints;
  final int monthPoints;
  final int streakDays;

  final int? cityRank;

  final List<Map<String, dynamic>> recentTasks;
  final List<Map<String, dynamic>> recentAchievements;

  const HomeState({
    this.isLoadingProfile = true,
    this.isLoadingTasks = true,
    this.error,
    this.displayName = '',
    this.avatarInitial = 'U',
    this.totalPoints = 0,
    this.currentPoints = 0,
    this.weekPoints = 0,
    this.monthPoints = 0,
    this.streakDays = 0,
    this.cityRank,
    this.recentTasks = const [],
    this.recentAchievements = const [],
  });

  HomeState copyWith({
    bool? isLoadingProfile,
    bool? isLoadingTasks,
    String? error,
    String? displayName,
    String? avatarInitial,
    int? totalPoints,
    int? currentPoints,
    int? weekPoints,
    int? monthPoints,
    int? streakDays,
    int? cityRank,
    List<Map<String, dynamic>>? recentTasks,
    List<Map<String, dynamic>>? recentAchievements,
    bool clearError = false,
    bool clearCityRank = false,
  }) {
    return HomeState(
      isLoadingProfile:
          isLoadingProfile ?? this.isLoadingProfile,

      isLoadingTasks:
          isLoadingTasks ?? this.isLoadingTasks,

      error: clearError ? null : error ?? this.error,

      displayName: displayName ?? this.displayName,

      avatarInitial:
          avatarInitial ?? this.avatarInitial,

      totalPoints: totalPoints ?? this.totalPoints,

      currentPoints:
          currentPoints ?? this.currentPoints,

      weekPoints: weekPoints ?? this.weekPoints,

      monthPoints:
          monthPoints ?? this.monthPoints,

      streakDays: streakDays ?? this.streakDays,

      cityRank: clearCityRank
          ? null
          : cityRank ?? this.cityRank,

      recentTasks:
          recentTasks ?? this.recentTasks,

      recentAchievements:
          recentAchievements ??
              this.recentAchievements,
    );
  }

  int get tasksDoneCount =>
      recentTasks.where(
        (t) => (t['done'] as bool?) == true,
      ).length;

  int get level => (totalPoints ~/ 1000) + 1;

  double get levelProgress =>
      ((totalPoints % 1000) / 1000)
          .clamp(0.0, 1.0);

  double get weekProgress =>
      (weekPoints / 600).clamp(0.0, 1.0);

  double get monthProgress =>
      (monthPoints / 2000).clamp(0.0, 1.0);
}

class HomeViewModel extends StateNotifier<HomeState> {
  HomeViewModel() : super(const HomeState()) {
    _init();
  }

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  User? get _currentUser => _auth.currentUser;

  Future<void> _init() async {
    await Future.wait([
      _loadProfile(),
      _loadRecentTasks(),
    ]);
  }

  // =========================================================
  // PROFILE
  // =========================================================

  Future<void> _loadProfile() async {
    final user = _currentUser;

    if (user == null) {
      state = state.copyWith(
        isLoadingProfile: false,
      );
      return;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data() ?? {};

      _applyProfileData(data, user);
    } catch (e) {
      state = state.copyWith(
        isLoadingProfile: false,
        error:
            'Không thể tải thông tin người dùng.',
      );
    }
  }

  void _applyProfileData(
    Map<String, dynamic> data,
    User user,
  ) {
    final displayName =
        _resolveDisplayName(data, user);

    final avatarInitial =
        displayName.isNotEmpty
            ? displayName[0].toUpperCase()
            : 'U';

    final achievementsRaw =
        data['recentAchievements']
            as List<dynamic>? ??
        [];

    final achievements =
        achievementsRaw.map((e) {
      return Map<String, dynamic>.from(
        e as Map,
      );
    }).toList();

    state = state.copyWith(
      isLoadingProfile: false,

      displayName: displayName,

      avatarInitial: avatarInitial,

      totalPoints:
          (data['totalPoints'] as num?)
                  ?.toInt() ??
              0,

      currentPoints:
          (data['currentPoints'] as num?)
                  ?.toInt() ??
              0,

      weekPoints:
          (data['weekPoints'] as num?)
                  ?.toInt() ??
              0,

      monthPoints:
          (data['monthPoints'] as num?)
                  ?.toInt() ??
              0,

      streakDays:
          (data['streakDays'] as num?)
                  ?.toInt() ??
              0,

      cityRank:
          (data['cityRank'] as num?)
              ?.toInt(),

      recentAchievements: achievements,
    );
  }

  String _resolveDisplayName(
    Map<String, dynamic> data,
    User user,
  ) {
    final candidates = [
      (data['displayName'] as String?)
          ?.trim(),

      (data['fullName'] as String?)
          ?.trim(),

      (data['username'] as String?)
          ?.trim(),

      user.displayName?.trim(),

      user.email
          ?.split('@')
          .first
          .trim(),
    ];

    return candidates.firstWhere(
          (s) => s != null && s.isNotEmpty,
          orElse: () => 'Người dùng',
        ) ??
        'Người dùng';
  }

  // =========================================================
  // TASKS
  // =========================================================

  Future<void> _loadRecentTasks() async {
    final user = _currentUser;

    if (user == null) {
      state = state.copyWith(
        isLoadingTasks: false,
      );
      return;
    }

    try {
      final submissionsSnap =
          await _firestore
              .collection('submissions')
              .where(
                'userId',
                isEqualTo: user.uid,
              )
              .orderBy(
                'createdAt',
                descending: true,
              )
              .limit(3)
              .get();

      final tasks =
          submissionsSnap.docs.map((doc) {
        final d = doc.data();

        return {
          'id': doc.id,

          'title':
              d['taskTitle'] ?? 'Nhiệm vụ',

          'category':
              d['category'] ?? 'General',

          'points':
              (d['pointsReward'] as num?)
                      ?.toInt() ??
                  0,

          'done':
              d['status'] == 'approved',

          'status':
              d['status'] ?? 'pending',

          'dueLabel': _statusLabel(
            d['status'] as String?,
          ),
        };
      }).toList();

      state = state.copyWith(
        isLoadingTasks: false,
        recentTasks: tasks,
      );
    } catch (e) {
      await _loadRecentTasksFallback(user);
    }
  }

  Future<void> _loadRecentTasksFallback(
    User user,
  ) async {
    try {
      final snap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .orderBy(
            'updatedAt',
            descending: true,
          )
          .limit(3)
          .get();

      final tasks = snap.docs.map((doc) {
        final d = doc.data();

        return {
          'id': doc.id,

          'title':
              d['title'] ?? 'Nhiệm vụ',

          'category':
              d['category'] ?? 'General',

          'points':
              (d['pointsReward'] as num?)
                      ?.toInt() ??
                  0,

          'done':
              d['done'] ?? false,

          'dueLabel': 'Hôm nay',
        };
      }).toList();

      state = state.copyWith(
        isLoadingTasks: false,
        recentTasks: tasks,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingTasks: false,
      );
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'approved':
        return 'Đã duyệt';

      case 'rejected':
        return 'Từ chối';

      default:
        return 'Đang chờ';
    }
  }

  // =========================================================
  // REFRESH
  // =========================================================

  Future<void> refresh() async {
    state = state.copyWith(
      isLoadingProfile: true,
      isLoadingTasks: true,
      clearError: true,
    );

    await _init();
  }
}

final homeViewModelProvider =
    StateNotifierProvider<
      HomeViewModel,
      HomeState
    >((ref) {
  return HomeViewModel();
});
final approvedSubmissionsCountProvider = StreamProvider.family<int, String?>((ref, uid) {
  if (uid == null) return Stream.value(0);

  return FirebaseFirestore.instance
      .collection('submissions')
      .where('userId', isEqualTo: uid)
      .where('status', isEqualTo: 'approved')
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});
