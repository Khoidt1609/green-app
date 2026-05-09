// lib/data/repositories/leaderboard_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/leaderboard_model.dart';

class LeaderboardRepository {
  LeaderboardRepository(this._firestore);
  final FirebaseFirestore _firestore;

  /// Firestore không cho phép orderBy(fieldA) + where(fieldB) trên 2 field khác nhau
  /// mà không có composite index.
  /// Chiến lược:
  ///   - Không filter → orderBy trên Firestore (tối ưu, limit 50)
  ///   - Có filter    → where trên Firestore, sort + limit client-side
  Future<List<LeaderboardEntry>> getLeaderboard({
    required LeaderboardPeriod period,
    required LeaderboardScope scope,
    String? filterValue,
  }) async {
    final pointsField = period.pointsField;

    QuerySnapshot<Map<String, dynamic>> snapshot;

    if (filterValue == null || filterValue.isEmpty) {
      snapshot = await _firestore
          .collection('users')
          .orderBy(pointsField, descending: true)
          .limit(50)
          .get();
    } else {
      snapshot = await _firestore
          .collection('users')
          .where(scope.filterField, isEqualTo: filterValue)
          .get();
    }

    final rawList = <Map<String, dynamic>>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (!data.containsKey('weekPoints') && !data.containsKey('monthPoints')) {
        continue;
      }
      data['uid'] = doc.id;
      rawList.add(data);
    }

    if (filterValue != null && filterValue.isNotEmpty) {
      rawList.sort((a, b) {
        final pa = (a[pointsField] as num?)?.toInt() ?? 0;
        final pb = (b[pointsField] as num?)?.toInt() ?? 0;
        return pb.compareTo(pa);
      });
    }

    final limited = rawList.take(50).toList();
    return [
      for (int i = 0; i < limited.length; i++)
        LeaderboardEntry.fromMap(limited[i], i + 1, period),
    ];
  }

  Future<List<String>> getDistricts() async {
    final snapshot = await _firestore.collection('users').get();
    final result = <String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final address = data['address'];
      if (address is Map<String, dynamic>) {
        final d = (address['district'] as String?)?.trim();
        if (d != null && d.isNotEmpty) result.add(d);
      }
      final flat = (data['district'] as String?)?.trim();
      if (flat != null && flat.isNotEmpty) result.add(flat);
    }
    return result.toList()..sort();
  }

  Future<List<String>> getCities() async {
    final snapshot = await _firestore.collection('users').get();
    final result = <String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final address = data['address'];
      if (address is Map<String, dynamic>) {
        final c = (address['city'] as String?)?.trim();
        if (c != null && c.isNotEmpty) result.add(c);
      }
      final flat = (data['city'] as String?)?.trim();
      if (flat != null && flat.isNotEmpty) result.add(flat);
    }
    return result.toList()..sort();
  }
}

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepository(FirebaseFirestore.instance);
});