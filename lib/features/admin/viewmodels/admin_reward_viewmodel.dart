import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/reward_model.dart';
import '../../../data/repositories/admin_reward_repository.dart';

final adminRewardRepoProvider = Provider((ref) => AdminRewardRepository());

final adminRewardsStreamProvider = StreamProvider<List<RewardModel>>((ref) {
  return ref.watch(adminRewardRepoProvider).getAllRewards();
});

final rewardSearchQueryProvider = StateProvider<String>((ref) => "");

final searchRewardsProvider = Provider<AsyncValue<List<RewardModel>>>((ref) {
  final rewardsAsync = ref.watch(adminRewardsStreamProvider);
  final query = ref.watch(rewardSearchQueryProvider).toLowerCase();

  return rewardsAsync.whenData((list) {
    if (query.isEmpty) return list;

    // Lọc theo Tên phần thưởng
    return list.where((reward) {
      final name = (reward.name).toLowerCase();
      return name.contains(query);
    }).toList();
  });
});

// Viewmodel action
class AdminRewardActionViewModel extends StateNotifier<AsyncValue<void>> {
  final AdminRewardRepository _repo;

  AdminRewardActionViewModel(this._repo) : super(const AsyncValue.data(null));

  Future<void> toggleStatus(String rewardId, bool currentStatus) async {
    try {
      await _repo.toggleRewardStatus(rewardId, currentStatus);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> add(RewardModel reward) async {
    state = const AsyncValue.loading();
    try {
      await _repo.addReward(reward);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> update(RewardModel reward) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateReward(reward);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> delete(String rewardId) async {
    try {
      await _repo.deleteReward(rewardId);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Cung cấp ViewModel ra cho UI gọi
final adminRewardActionProvider = StateNotifierProvider<AdminRewardActionViewModel, AsyncValue<void>>((ref) {
  return AdminRewardActionViewModel(ref.read(adminRewardRepoProvider));
});