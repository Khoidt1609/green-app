import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/reward_model.dart';
import '../../../data/repositories/admin_reward_repository.dart';
import '../../../data/services/cloudinary_service.dart';

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
  final ImageUploadService _imageService;

  AdminRewardActionViewModel(this._repo, this._imageService)
    : super(const AsyncValue.data(null));

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

  // Hàm Upload Ảnh lên cloudinary và lưu DB
  Future<void> saveReward(
    RewardModel reward,
    File? imageFile,
    bool isEdit,
  ) async {
    state = const AsyncValue.loading();
    try {
      String finalImageUrl = reward.imageUrl ?? '';

      // Xử lý Upload Ảnh trước (nếu có ảnh mới)
      if (imageFile != null) {
        final uploadedUrl = await _imageService.uploadImage(
          imageFile,
          folder: 'greenstep/admin/rewards',
        );

        if (uploadedUrl == null) {
          throw Exception("Upload ảnh thất bại! Vui lòng thử lại.");
        }
        finalImageUrl = uploadedUrl;
      }

      // Cập nhật link ảnh mới vào Model
      final rewardToSave = RewardModel(
        id: reward.id,
        name: reward.name,
        description: reward.description,
        pointCost: reward.pointCost,
        valueVND: reward.valueVND,
        type: reward.type,
        imageUrl: finalImageUrl,
        isActive: reward.isActive,
      );

      // THêm mới hoặc sửa
      if (isEdit) {
        await _repo.updateReward(rewardToSave);
      } else {
        await _repo.addReward(rewardToSave);
      }

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Cung cấp ViewModel ra cho UI gọi
final adminRewardActionProvider =
    StateNotifierProvider<AdminRewardActionViewModel, AsyncValue<void>>((ref) {
      return AdminRewardActionViewModel(
        ref.read(adminRewardRepoProvider),
        ref.read(imageUploadServiceProvider),
      );
    });
