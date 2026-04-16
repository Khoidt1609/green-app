// lib/features/leaderboard/models/leaderboard_model.dart

class LeaderboardEntry {
  final String uid;
  final String displayName;
  final int points;
  final int rank;
  final String? district;
  final String? city;
  final String avatarInitial;

const LeaderboardEntry({
  required this.uid,
  required this.displayName,
  required this.points,
  required this.rank,
  this.district,
  this.city,
  required this.avatarInitial,
});

factory LeaderboardEntry.fromMap(Map<String, dynamic> map, int rank) {
  final displayName = (map['displayName'] as String?)?.trim() ?? 'User';

  // Xử lý address có thể là Map hoặc List
  final addressRaw = map['address'];
  String? district;
  String? city;

  if (addressRaw is Map<String, dynamic>) {
    district = addressRaw['district'] as String?;
    city = addressRaw['city'] as String?;
  } else if (addressRaw is List) {
    // Giả định: address = ['district', 'city'] hoặc list of maps
    if (addressRaw.isNotEmpty) {
      final first = addressRaw[0];
      if (first is String) {
        district = first;
      } else if (first is Map<String, dynamic>) {
        district = first['district'] as String? ?? first['name'] as String?;
      }
    }
    if (addressRaw.length > 1) {
      final second = addressRaw[1];
      if (second is String) {
        city = second;
      } else if (second is Map<String, dynamic>) {
        city = second['city'] as String? ?? second['name'] as String?;
      }
    }
  }

  final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

  return LeaderboardEntry(
    uid: map['uid'] as String? ?? '',
    displayName: displayName,
    points: (map['weekPoints'] as num?)?.toInt() ??
        (map['monthPoints'] as num?)?.toInt() ??
        0,
    rank: rank,
    district: district,
    city: city,
    avatarInitial: initial,
  );
}

}

enum LeaderboardPeriod { week, month }

enum LeaderboardScope { district, city }
