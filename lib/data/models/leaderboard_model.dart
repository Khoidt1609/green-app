// lib/data/models/leaderboard_model.dart

// ─────────────────────────────────────────────────────────────
// LEADERBOARD PERIOD
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

enum LeaderboardPeriod {
  week,
  month;

  String get pointsField {
    switch (this) {
      case LeaderboardPeriod.week:
        return 'weekPoints';

      case LeaderboardPeriod.month:
        return 'monthPoints';
    }
  }

  String get label {
    switch (this) {
      case LeaderboardPeriod.week:
        return 'Tuần này';

      case LeaderboardPeriod.month:
        return 'Tháng này';
    }
  }

  String get rewardTitle {
    switch (this) {
      case LeaderboardPeriod.week:
        return 'Giải thưởng tuần';

      case LeaderboardPeriod.month:
        return 'Giải thưởng tháng';
    }
  }

  Map<int, String> get prizes {
    switch (this) {
      case LeaderboardPeriod.week:
        return {
          1: '100.000đ',
          2: '50.000đ',
          3: '20.000đ',
          4: '10.000đ',
          5: '5.000đ',
        };

      case LeaderboardPeriod.month:
        return {
          1: '500.000đ',
          2: '200.000đ',
          3: '100.000đ',
          4: '50.000đ',
          5: '20.000đ',
        };
    }
  }
}

// ─────────────────────────────────────────────────────────────
// LEADERBOARD SCOPE
// ─────────────────────────────────────────────────────────────

enum LeaderboardScope {
  district,
  city;

  String get label {
    switch (this) {
      case LeaderboardScope.district:
        return 'Quận/Huyện';

      case LeaderboardScope.city:
        return 'Tỉnh/TP';
    }
  }

  String get filterField {
    switch (this) {
      case LeaderboardScope.district:
        return 'address.district';

      case LeaderboardScope.city:
        return 'address.city';
    }
  }

  String get emptyLabel {
    switch (this) {
      case LeaderboardScope.district:
        return 'quận/huyện';

      case LeaderboardScope.city:
        return 'tỉnh/thành phố';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.points,
    required this.rank,
    required this.avatarInitial,
    required this.avatarUrl,

    this.district,
    this.city,

    this.weekPoints,
    this.monthPoints,

    this.isCurrentUser = false,
  });

  // ─────────────────────────────

  final String uid;

  final String displayName;

  final int points;

  final int rank;

  final String avatarInitial;

  final String avatarUrl;

  final String? district;

  final String? city;

  final int? weekPoints;

  final int? monthPoints;

  final bool isCurrentUser;

  // ─────────────────────────────
  // FACTORY
  // ─────────────────────────────

  factory LeaderboardEntry.fromMap(
    Map<String, dynamic> map,
    int rank,
    LeaderboardPeriod period, {
    String? currentUid,
  }) {
    final displayName = _resolveDisplayName(map);

    final address =
        map['address'] as Map<String, dynamic>?;

    String? district =
        (address?['district'] as String?)
            ?.trim();

    String? city =
        (address?['city'] as String?)
            ?.trim();

    // fallback old structure

    district ??=
        (map['district'] as String?)
            ?.trim();

    city ??=
        (map['city'] as String?)
            ?.trim();

    final weekPoints =
        (map['weekPoints'] as num?)
            ?.toInt() ??
        0;

    final monthPoints =
        (map['monthPoints'] as num?)
            ?.toInt() ??
        0;

    final activePoints =
        period == LeaderboardPeriod.week
            ? weekPoints
            : monthPoints;

    final avatarUrl =
        (map['avatarUrl'] as String?)
            ?.trim() ??
        '';

    final uid =
        (map['uid'] as String?) ??
        '';

    return LeaderboardEntry(
      uid: uid,

      displayName: displayName,

      points: activePoints,

      rank: rank,

      avatarInitial:
          _buildInitial(displayName),

      avatarUrl: avatarUrl,

      district:
          district != null &&
                  district.isNotEmpty
              ? district
              : null,

      city:
          city != null &&
                  city.isNotEmpty
              ? city
              : null,

      weekPoints: weekPoints,

      monthPoints: monthPoints,

      isCurrentUser:
          currentUid != null &&
          currentUid == uid,
    );
  }

  // ─────────────────────────────
  // HELPERS
  // ─────────────────────────────

  static String _resolveDisplayName(
    Map<String, dynamic> map,
  ) {
    final candidates = [
      (map['displayName'] as String?)
          ?.trim(),

      (map['fullName'] as String?)
          ?.trim(),

      (map['username'] as String?)
          ?.trim(),
    ];

    for (final item in candidates) {
      if (item != null &&
          item.isNotEmpty) {
        return item;
      }
    }

    return 'Người dùng';
  }

  static String _buildInitial(
    String value,
  ) {
    final text = value.trim();

    if (text.isEmpty) {
      return 'U';
    }

    return text.characters.first
        .toUpperCase();
  }

  // ─────────────────────────────
  // GETTERS
  // ─────────────────────────────

  bool get hasAvatar =>
      avatarUrl.trim().isNotEmpty;

  bool get hasLocation =>
      district != null || city != null;

  String get locationLabel {
    if (district != null &&
        city != null) {
      return '$district, $city';
    }

    if (district != null) {
      return district!;
    }

    if (city != null) {
      return city!;
    }

    return '';
  }

  bool get isTop1 => rank == 1;

  bool get isTop2 => rank == 2;

  bool get isTop3 => rank == 3;

  bool get isTop5 => rank <= 5;

  String get medalEmoji {
    switch (rank) {
      case 1:
        return '🥇';

      case 2:
        return '🥈';

      case 3:
        return '🥉';

      default:
        return '';
    }
  }

  // ─────────────────────────────
  // COPY WITH
  // ─────────────────────────────

  LeaderboardEntry copyWith({
    String? uid,
    String? displayName,
    int? points,
    int? rank,
    String? avatarInitial,
    String? avatarUrl,

    String? district,
    String? city,

    int? weekPoints,
    int? monthPoints,

    bool? isCurrentUser,
  }) {
    return LeaderboardEntry(
      uid: uid ?? this.uid,

      displayName:
          displayName ??
          this.displayName,

      points: points ?? this.points,

      rank: rank ?? this.rank,

      avatarInitial:
          avatarInitial ??
          this.avatarInitial,

      avatarUrl:
          avatarUrl ??
          this.avatarUrl,

      district:
          district ?? this.district,

      city: city ?? this.city,

      weekPoints:
          weekPoints ??
          this.weekPoints,

      monthPoints:
          monthPoints ??
          this.monthPoints,

      isCurrentUser:
          isCurrentUser ??
          this.isCurrentUser,
    );
  }

  // ─────────────────────────────

  @override
  String toString() {
    return '''
LeaderboardEntry(
  uid: $uid,
  displayName: $displayName,
  points: $points,
  rank: $rank
)
''';
  }
}