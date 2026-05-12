// lib/data/repositories/reward_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reward_model.dart';
import '../models/transaction_model.dart';

class RewardRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  RewardRepository(this._firestore, this._auth);

  /// Lấy uid an toàn
  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập. Vui lòng đăng nhập lại.');
    }
    return user.uid;
  }

  // ── Rewards list ─────────────────────────────
  Future<List<RewardModel>> getRewards() async {
    final snapshot = await _firestore.collection('rewards').get();
    return snapshot.docs
        .map(RewardModel.fromDoc)
        .toList()
      ..sort((a, b) => a.pointCost.compareTo(b.pointCost));
  }

  // ── User profile (points) ────────────────────
  Stream<Map<String, dynamic>> watchUserProfile() {
    return _firestore
        .collection('users')
        .doc(_uid)
        .snapshots()
        .map((s) => s.data() ?? {});
  }

  // ── Redeem a reward ──────────────────────────
  Future<void> redeemReward({
    required RewardModel reward,
    required Map<String, String> bankDetails,
    required String userName,
  }) async {
    final userRef = _firestore.collection('users').doc(_uid);
    final txRef = _firestore.collection('transactions').doc();

    await _firestore.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      final currentPoints =
          (userSnap.data()?['currentPoints'] as num?)?.toInt() ?? 0;

      if (currentPoints < reward.pointCost) {
        throw Exception('Không đủ điểm để đổi phần thưởng này.');
      }

      tx.update(userRef, {
        'currentPoints': FieldValue.increment(-reward.pointCost),
      });

      tx.set(txRef, {
        'userId': _uid,
        'userName': userName,
        'rewardId': reward.id,
        'rewardName': reward.name,
        'pointCost': reward.pointCost,
        'amountVND': reward.valueVND,
        'type': 'redeem',
        'status': 'pending',
        'bankDetails': bankDetails,
        'createdAt': FieldValue.serverTimestamp(),
        'paidAt': null,
      });
    });
  }

  // ── Transaction history ───────────────────────
  Future<List<TransactionModel>> getTransactions({int limit = 20}) async {
    final snapshot = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map(TransactionModel.fromDocument).toList();
  }
}

final rewardRepositoryProvider = Provider<RewardRepository>((ref) {
  return RewardRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});