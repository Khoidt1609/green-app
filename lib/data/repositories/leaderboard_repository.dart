// lib/data/repositories/leaderboard_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/leaderboard_model.dart';

class LeaderboardRepository {
  LeaderboardRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<List<LeaderboardEntry>> getLeaderboard({
    required LeaderboardPeriod period,
    required LeaderboardScope scope,
    String? filterValue,
    int limit = 50,
  }) async {
    final pointsField = period.pointsField;

    Query<Map<String, dynamic>> query = _users;

    if (filterValue != null && filterValue.trim().isNotEmpty) {
      query = query.where(
        scope.filterField,
        isEqualTo: filterValue.trim(),
      );
    }

    final snapshot = await query.get();

    final raw = <Map<String, dynamic>>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final pts = (data[pointsField] as num?)?.toInt() ?? 0;

      if (pts <= 0) continue;

      data['uid'] = doc.id;

      raw.add(data);
    }

    raw.sort((a, b) {
      final pa = (a[pointsField] as num?)?.toInt() ?? 0;
      final pb = (b[pointsField] as num?)?.toInt() ?? 0;

      if (pa == pb) {
        final an = (a['displayName'] ?? '').toString();
        final bn = (b['displayName'] ?? '').toString();

        return an.compareTo(bn);
      }

      return pb.compareTo(pa);
    });

    final limited = raw.take(limit).toList();

    return List.generate(
      limited.length,
      (i) => LeaderboardEntry.fromMap(
        limited[i],
        i + 1,
        period,
      ),
    );
  }

  Future<List<String>> getDistricts() async {
    final snapshot = await _users.get();

    final result = <String>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final address = data['address'];

      if (address is Map<String, dynamic>) {
        final district =
            (address['district'] as String?)?.trim();

        if (district != null && district.isNotEmpty) {
          result.add(district);
        }
      }
    }

    final list = result.toList();

    list.sort();

    return list;
  }

  Future<List<String>> getCities() async {
    final snapshot = await _users.get();

    final result = <String>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final address = data['address'];

      if (address is Map<String, dynamic>) {
        final city =
            (address['city'] as String?)?.trim();

        if (city != null && city.isNotEmpty) {
          result.add(city);
        }
      }
    }

    final list = result.toList();

    list.sort();

    return list;
  }
}

final leaderboardRepositoryProvider =
    Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepository(
    FirebaseFirestore.instance,
  );
});
