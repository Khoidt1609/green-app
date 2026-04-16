// lib/features/leaderboard/models/leaderboard_model.dart

class LeaderboardEntry {
  final String uid;
  final String displayName;
  final int points;
  final int rank;
  final String? district;
  final String? city;
  final String? avatarInitial;

  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.points,
    required this.rank,
    this.district,
    this.city,
    this.avatarInitial,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map, int rank) {
    final displayName = (map['displayName'] as String?)?.trim() ?? 'User';
    final address = map['address'] as Map<String, dynamic>?;
    return LeaderboardEntry(
      uid: map['uid'] as String? ?? '',
      displayName: displayName,
      points: (map['weekPoints'] as num?)?.toInt() ??
          (map['monthPoints'] as num?)?.toInt() ??
          0,
      rank: rank,
      district: address?['district'] as String?,
      city: address?['city'] as String?,
      avatarInitial: displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
    );
  }
}

enum LeaderboardPeriod { week, month }

enum LeaderboardScope { district, city }
