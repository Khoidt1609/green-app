// lib/data/models/leaderboard_model.dart

// ─── Enums ────────────────────────────────────────────────────────────────────

enum LeaderboardPeriod {
  week,
  month;

  String get pointsField =>
      this == LeaderboardPeriod.week ? 'weekPoints' : 'monthPoints';

  String get label =>
      this == LeaderboardPeriod.week ? 'Tuần này' : 'Tháng này';

  // Tuần < Tháng
  Map<int, String> get prizes => this == LeaderboardPeriod.week
      ? {1: '100.000đ', 2: '50.000đ', 3: '20.000đ'}
      : {1: '500.000đ', 2: '200.000đ', 3: '100.000đ'};
}

enum LeaderboardScope {
  district,
  city;

  String get label =>
      this == LeaderboardScope.district ? 'Quận/Huyện' : 'Tỉnh/TP';

  String get filterField =>
      this == LeaderboardScope.district ? 'address.district' : 'address.city';
}

// ─── Model ────────────────────────────────────────────────────────────────────

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.points,
    required this.rank,
    required this.avatarInitial,
    this.district,
    this.city,
    this.weekPoints,
    this.monthPoints,
  });

  final String uid;
  final String displayName;
  final int points;
  final int rank;
  final String avatarInitial;
  final String? district;
  final String? city;
  final int? weekPoints;
  final int? monthPoints;

  factory LeaderboardEntry.fromMap(
    Map<String, dynamic> map,
    int rank,
    LeaderboardPeriod period,
  ) {
    final displayName = _resolveName(map);
    final address = map['address'];
    String? district;
    String? city;

    if (address is Map<String, dynamic>) {
      district = (address['district'] as String?)?.trim();
      city = (address['city'] as String?)?.trim();
    }
    // flat fallback (auth_service cũ)
    district = (district?.isNotEmpty == true) ? district : (map['district'] as String?)?.trim();
    city = (city?.isNotEmpty == true) ? city : (map['city'] as String?)?.trim();

    final weekPts = (map['weekPoints'] as num?)?.toInt() ?? 0;
    final monthPts = (map['monthPoints'] as num?)?.toInt() ?? 0;
    final activePts = period == LeaderboardPeriod.week ? weekPts : monthPts;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return LeaderboardEntry(
      uid: (map['uid'] as String?) ?? '',
      displayName: displayName,
      points: activePts,
      rank: rank,
      avatarInitial: initial,
      district: (district?.isEmpty == true) ? null : district,
      city: (city?.isEmpty == true) ? null : city,
      weekPoints: weekPts,
      monthPoints: monthPts,
    );
  }

  static String _resolveName(Map<String, dynamic> map) {
    final candidates = [
      (map['displayName'] as String?)?.trim(),
      (map['fullName'] as String?)?.trim(),
      (map['username'] as String?)?.trim(),
    ];
    return candidates.firstWhere((s) => s != null && s.isNotEmpty,
            orElse: () => 'Người dùng') ??
        'Người dùng';
  }

  String get locationLabel {
    if (district != null && city != null) return '$district, $city';
    if (district != null) return district!;
    if (city != null) return city!;
    return '';
  }
}