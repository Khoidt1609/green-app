import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_app/features/admin/views/reward_bottom_sheet.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/reward_model.dart';
import '../viewmodels/admin_reward_viewmodel.dart';

class AdminRewardsTab extends ConsumerWidget {
  const AdminRewardsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(searchRewardsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Thanh Tìm kiếm & Nút Thêm mới
            _buildTopBar(context, ref),

            // Danh sách Reward
            Expanded(
              child: rewardsAsync.when(
                data: (rewards) {
                  if (rewards.isEmpty) {
                    return const Center(
                      child: Text("Chưa có gói phần thưởng nào."),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: rewards.length,
                    itemBuilder: (context, index) {
                      final reward = rewards[index];
                      return _buildRewardCard(context, ref, reward);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) =>
                    Center(child: Text("Lỗi tải dữ liệu: $err")),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) {
                ref.read(rewardSearchQueryProvider.notifier).state = value;
              },
              decoration: InputDecoration(
                hintText: 'Tìm phần thưởng...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryGreen),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Nút Thêm Mới
          InkWell(
            onTap: () => _showRewardForm(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(
    BuildContext context,
    WidgetRef ref,
    RewardModel reward,
  ) {
    final bool isDisabled = !(reward.isActive ?? true);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: isDisabled ? 0 : 2,
      color: isDisabled ? Colors.grey.shade100 : Colors.white,
      child: Opacity(
        opacity: isDisabled ? 0.6 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ảnh minh họa
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      (reward.imageUrl != null && reward.imageUrl!.isNotEmpty)
                          ? reward.imageUrl!
                          : 'https://via.placeholder.com/150',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.card_giftcard,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Thông tin
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                reward.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Badge: Tiền mặt hay Voucher
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: reward.isCash
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                reward.isCash ? "Tiền mặt" : "Voucher",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: reward.isCash
                                      ? Colors.green.shade800
                                      : Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Điểm và Giá trị VNĐ
                        Row(
                          children: [
                            const Icon(
                              Icons.stars,
                              size: 14,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${reward.pointCost} điểm",
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(" = "),
                            Text(
                              "${reward.valueVND} VNĐ",
                              style: const TextStyle(
                                color: AppColors.primaryDarkGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              const Divider(height: 1),

              // Dòng dưới cùng: Nút Toggle, Sửa, Xóa
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Công tắc Hiện/Ẩn
                  Row(
                    children: [
                      SizedBox(
                        height: 40,
                        child: Switch(
                          value: reward.isActive ?? true,
                          activeColor: AppColors.primaryGreen,
                          onChanged: (value) {
                            ref
                                .read(adminRewardActionProvider.notifier)
                                .toggleStatus(reward.id, value);
                          },
                        ),
                      ),
                      Text(
                        (reward.isActive ?? true) ? "Đang bán" : "Tạm ngưng",
                        style: TextStyle(
                          fontSize: 13,
                          color: (reward.isActive ?? true)
                              ? AppColors.primaryGreen
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  // Nút Icon Sửa & Xóa
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.lightGreenAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.lightGreenAccent.withOpacity(0.5),
                          ),
                        ),
                        child: IconButton(
                          tooltip: "Sửa",
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: AppColors.primaryDarkGreen,
                            size: 20,
                          ),
                          onPressed: isDisabled
                              ? null
                              : () => _showRewardForm(context, reward: reward),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.2),
                          ),
                        ),
                        child: IconButton(
                          tooltip: "Xóa",
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: isDisabled
                              ? null
                              : () => _showDeleteConfirmDialog(
                                  context,
                                  ref,
                                  reward.id,
                                ),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRewardForm(BuildContext context, {RewardModel? reward}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RewardFormBottomSheet(rewardToEdit: reward),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    String rewardId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text(
          "Bạn có chắc chắn muốn xóa gói phần thưởng này không?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(adminRewardActionProvider.notifier).delete(rewardId);
              Navigator.pop(ctx);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
