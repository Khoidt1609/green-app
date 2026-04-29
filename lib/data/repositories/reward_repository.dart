// lib/data/repositories/reward_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reward_model.dart';
import '../models/transaction_model.dart'; // FIX: dùng TransactionModel thay TransactionRecord

class RewardRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  RewardRepository(this._firestore, this._auth);

  String get _uid => _auth.currentUser!.uid;

  // ── Rewards list ─────────────────────────────
  Future<List<RewardItem>> getRewards() async {
    final snapshot = await _firestore.collection('rewards').get();
    return snapshot.docs.map(RewardItem.fromDoc).toList()
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
    required RewardItem reward,
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
  // FIX: trả về List<TransactionModel> thay vì List<TransactionRecord>
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