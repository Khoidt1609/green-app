import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reward_model.dart';

class AdminRewardRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Lấy toàn bộ danh sách phần thưởng theo Stream (Realtime)
  Stream<List<RewardModel>> getAllRewards() {
    return _db
        .collection('rewards')
        .snapshots()
        .map(
          (snapshot) =>
          snapshot.docs.map((doc) => RewardModel.fromDoc(doc)).toList(),
    );
  }

  // Thêm phần thưởng mới
  Future<void> addReward(RewardModel reward) async {
    await _db.collection('rewards').add(reward.toMap());
  }

  // Cập nhật thông tin phần thưởng
  Future<void> updateReward(RewardModel reward) async {
    await _db.collection('rewards').doc(reward.id).update(reward.toMap());
  }

  // Cập nhật trạng thái ẩn hiện
  Future<void> toggleRewardStatus(String rewardId, bool newStatus) async {
    await _db.collection('rewards').doc(rewardId).update({
      'isActive': newStatus,
    });
  }

  // Xóa phần thưởng
  Future<void> deleteReward(String rewardId) async {
    await _db.collection('rewards').doc(rewardId).delete();
  }
}