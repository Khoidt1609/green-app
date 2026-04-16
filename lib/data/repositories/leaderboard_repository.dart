// lib/features/leaderboard/repositories/leaderboard_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/leaderboard_model.dart';

class LeaderboardRepository {
  final FirebaseFirestore _firestore;

  LeaderboardRepository(this._firestore);

  /// Lấy top users theo tuần hoặc tháng, filter theo district/city
  Future<List<LeaderboardEntry>> getLeaderboard({
    required LeaderboardPeriod period,
    required LeaderboardScope scope,
    String? filterValue, // tên quận hoặc tỉnh
  }) async {
    final pointsField =
        period == LeaderboardPeriod.week ? 'weekPoints' : 'monthPoints';

    Query query = _firestore
        .collection('users')
        .orderBy(pointsField, descending: true)
        .limit(50);

    // Filter theo địa chỉ nếu có
    if (filterValue != null && filterValue.isNotEmpty) {
      if (scope == LeaderboardScope.district) {
        query = query.where('address.district', isEqualTo: filterValue);
      } else {
        query = query.where('address.city', isEqualTo: filterValue);
      }
    }

    final snapshot = await query.get();
    final entries = <LeaderboardEntry>[];

    for (int i = 0; i < snapshot.docs.length; i++) {
      final data = snapshot.docs[i].data() as Map<String, dynamic>;
      data['uid'] = snapshot.docs[i].id;

      // Override points field để đồng nhất
      final pts = (data[pointsField] as num?)?.toInt() ?? 0;
      final entry = LeaderboardEntry(
        uid: data['uid'] as String,
        displayName:
            (data['displayName'] as String?)?.trim() ?? 'User',
        points: pts,
        rank: i + 1,
        district: (data['address'] as Map<String, dynamic>?)?['district']
            as String?,
        city: (data['address'] as Map<String, dynamic>?)?['city'] as String?,
        avatarInitial: ((data['displayName'] as String?)?.trim().isNotEmpty ??
                false)
            ? (data['displayName'] as String)[0].toUpperCase()
            : 'U',
      );
      entries.add(entry);
    }

    return entries;
  }

  /// Lấy danh sách quận từ users (distinct)
  Future<List<String>> getDistincts() async {
    final snapshot = await _firestore
        .collection('users')
        .get();
    final districts = <String>{};
    for (final doc in snapshot.docs) {
      final address = doc.data()['address'] as Map<String, dynamic>?;
      final d = address?['district'] as String?;
      if (d != null && d.isNotEmpty) districts.add(d);
    }
    return districts.toList()..sort();
  }

  /// Lấy danh sách tỉnh/thành từ users (distinct)
  Future<List<String>> getCities() async {
    final snapshot = await _firestore.collection('users').get();
    final cities = <String>{};
    for (final doc in snapshot.docs) {
      final address = doc.data()['address'] as Map<String, dynamic>?;
      final c = address?['city'] as String?;
      if (c != null && c.isNotEmpty) cities.add(c);
    }
    return cities.toList()..sort();
  }
}

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepository(FirebaseFirestore.instance);
});
