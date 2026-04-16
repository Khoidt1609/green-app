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
  final doc = snapshot.docs[i];
  final raw = doc.data();

  // Bảo vệ kiểu: nếu raw không phải Map thì bỏ qua hoặc log
  if (raw is! Map<String, dynamic>) {
    // optional: log debug
    // print('Unexpected doc.data() type for ${doc.id}: ${raw.runtimeType}');
    continue;
  }

  final data = Map<String, dynamic>.from(raw);
  data['uid'] = doc.id;
  final entry = LeaderboardEntry.fromMap(data, i + 1);
  entries.add(entry);
}


    return entries;
  }

  /// Lấy danh sách quận từ users (distinct)
  Future<List<String>> getDistincts() async {
  final snapshot = await _firestore.collection('users').get();
  final districts = <String>{};
  for (final doc in snapshot.docs) {
    final raw = doc.data()['address'];
    String? d;
    if (raw is Map<String, dynamic>) {
      d = raw['district'] as String?;
    } else if (raw is List && raw.isNotEmpty) {
      final first = raw[0];
      if (first is String) d = first;
      else if (first is Map<String, dynamic>) d = first['district'] as String?;
    }
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
