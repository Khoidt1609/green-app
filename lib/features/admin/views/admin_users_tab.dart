// lib/features/admin/views/admin_users_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../providers/admin_user_provider.dart';
import 'admin_user_details_screen.dart'; // File mình sẽ tạo ở Bước 3

class AdminUsersTab extends ConsumerWidget {
  const AdminUsersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(filteredUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _buildSearchAndFilterHeader(context, ref),
          Expanded(
            child: usersAsync.when(
              data: (list) => list.isEmpty
                  ? const Center(child: Text("Không tìm thấy người dùng"))
                  : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                itemBuilder: (context, index) => _buildUserCard(context, ref, list[index]),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text("Lỗi: $e")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterHeader(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(userFilterProvider);
    final currentSort = ref.watch(userSortProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Thanh tìm kiếm
          TextField(
            onChanged: (val) => ref.read(userSearchQueryProvider.notifier).state = val,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              hintText: "Tìm theo tên hoặc email...",
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12),
          // Hàng Lọc & Sắp xếp
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<UserFilter>(
                  value: currentFilter,
                  decoration: _dropdownDecoration('Trạng thái'),
                  items: const [
                    DropdownMenuItem(value: UserFilter.all, child: Text('Tất cả')),
                    DropdownMenuItem(value: UserFilter.active, child: Text('Đang HĐ')),
                    DropdownMenuItem(value: UserFilter.blocked, child: Text('Bị khóa')),
                  ],
                  onChanged: (val) => ref.read(userFilterProvider.notifier).state = val!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<UserSort>(
                  value: currentSort,
                  decoration: _dropdownDecoration('Sắp xếp'),
                  items: const [
                    DropdownMenuItem(value: UserSort.pointsDesc, child: Text('Ví điểm (↓)')),
                    DropdownMenuItem(value: UserSort.totalPointsDesc, child: Text('Tích lũy (↓)')),
                    DropdownMenuItem(value: UserSort.nameAZ, child: Text('Tên (A-Z)')),
                  ],
                  onChanged: (val) => ref.read(userSortProvider.notifier).state = val!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
    );
  }

  Widget _buildUserCard(BuildContext context, WidgetRef ref, UserModel user) {
    final bool isActive = (user.role != 'blocked');

    return InkWell(
      onTap: () {
        // Chuyển sang màn hình chi tiết khi bấm vào thẻ
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AdminUserDetailsScreen(user: user)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? Colors.transparent : Colors.red.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
              child: Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDarkGreen, fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isActive ? Colors.black87 : Colors.grey)),
                  Text(user.email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.stars, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text("${user.currentPoints} điểm", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Switch(
                  value: isActive,
                  activeColor: AppColors.primaryGreen,
                  inactiveThumbColor: Colors.red,
                  inactiveTrackColor: Colors.red.shade100,
                  onChanged: (val) => _confirmToggle(context, ref, user, isActive),
                ),
                Text(isActive ? "Hoạt động" : "Bị khóa", style: TextStyle(fontSize: 11, color: isActive ? AppColors.primaryGreen : Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmToggle(BuildContext context, WidgetRef ref, UserModel user, bool currentStatus) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(currentStatus ? "Khóa tài khoản" : "Mở khóa tài khoản"),
        content: Text("Bạn có chắc chắn muốn ${currentStatus ? 'khóa' : 'mở khóa'} người dùng ${user.displayName}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: currentStatus ? Colors.red : AppColors.primaryGreen),
            onPressed: () {
              ref.read(adminUserActionProvider.notifier).toggleStatus(user.uid, currentStatus);
              Navigator.pop(ctx);
            },
            child: const Text("Xác nhận", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
// @override
// Widget build(BuildContext context, WidgetRef ref) {
//   final allUsersAsync = ref.watch(allUsersStreamProvider);
//   final searchedUsersAsync = ref.watch(searchedUsersProvider);
//
//   return Scaffold(
//     backgroundColor: AppColors.backgroundLight,
//     body: SafeArea(
//       child: Column(
//         children: [
//
//           _buildUserSearchBar(context, ref),
//
//
//           Expanded(
//             child: SingleChildScrollView(
//               child: Column(
//                 children: [
//                   // Thống kê Users
//                   allUsersAsync.when(
//                     data: (users) => _buildUserStats(users),
//                     loading: () => const LinearProgressIndicator(),
//                     error: (e, _) => const SizedBox(),
//                   ),
//
//                   const SizedBox(height: 8),
//
//                   // Danh sách User
//                   searchedUsersAsync.when(
//                     data: (users) {
//                       if (users.isEmpty) return const Center(child: Text("Không tìm thấy người dùng."));
//                       return ListView.builder(
//                         shrinkWrap: true,
//                         physics: const NeverScrollableScrollPhysics(),
//                         padding: const EdgeInsets.all(16),
//                         itemCount: users.length,
//                         itemBuilder: (context, index) => _buildUserCard(context, ref, users[index]),
//                       );
//                     },
//                     loading: () => const Center(child: CircularProgressIndicator()),
//                     error: (e, _) => Center(child: Text("Lỗi: $e")),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }
//
// Widget _buildUserStats(List<UserModel> users) {
//   final total = users.length;
//   final active = users.where((u) => !(u.isBanned ?? false)).length;
//   final banned = total - active;
//
//   return Padding(
//     padding: const EdgeInsets.symmetric(horizontal: 16),
//     child: Row(
//       children: [
//         Expanded(child: StatCard(icon: Icons.people_outline, color: AppColors.primaryDarkGreen, value: total.toString(), label: 'Tổng User')),
//         const SizedBox(width: 8),
//         Expanded(child: StatCard(icon: Icons.verified_user_outlined, color: Colors.blue, value: active.toString(), label: 'Hoạt động')),
//         const SizedBox(width: 8),
//         Expanded(child: StatCard(icon: Icons.block_flipped, color: Colors.redAccent, value: banned.toString(), label: 'Bị khóa')),
//       ],
//     ),
//   );
// }