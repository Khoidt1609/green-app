// lib/features/admin/views/admin_user_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/submission_model.dart';
import '../../../data/models/transaction_model.dart';
import '../providers/admin_user_provider.dart';

class AdminUserDetailsScreen extends ConsumerWidget {
  final UserModel user;
  const AdminUserDetailsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(activeHistoryTabProvider);
    final bool isActive = user.role != 'blocked';
    final bool isAdmin = user.role == 'admin';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text("Hồ sơ Quản trị", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Header: Avatar & Status
            _buildProfileHeader(isAdmin, isActive),
            const SizedBox(height: 24),

            // 2. Thẻ Thông tin Điểm số
            _buildSectionHeader(Icons.stars, "Thống kê Điểm số", Colors.orange),
            _buildPointsCard(),
            const SizedBox(height: 20),

            // 3. Thẻ Thông tin Liên hệ & Ngân hàng
            _buildSectionHeader(Icons.contact_mail, "Thông tin cá nhân", Colors.blue),
            _buildContactCard(),
            const SizedBox(height: 20),

            // 4. KHU VỰC QUẢN TRỊ (Cấp quyền & Khóa tài khoản)
            _buildSectionHeader(Icons.admin_panel_settings, "Hành động Quản trị", Colors.deepPurple),
            _buildAdminActionCard(context, ref, isAdmin, isActive),
            const SizedBox(height: 24),

            // 5. LỊCH SỬ HOẠT ĐỘNG (Tabs)
            _buildSectionHeader(Icons.history, "Lịch sử Hoạt động", AppColors.primaryDarkGreen),
            const SizedBox(height: 12),
            _buildHistorySection(ref, activeTab),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- WIDGET CẤU TRÚC ---

  Widget _buildProfileHeader(bool isAdmin, bool isActive) {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: isActive
                    ? (isAdmin ? Colors.amber.withOpacity(0.2) : AppColors.primaryGreen.withOpacity(0.2))
                    : Colors.red.withOpacity(0.2),
                child: Text(
                  user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                  style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: isActive ? (isAdmin ? Colors.amber.shade800 : AppColors.primaryDarkGreen) : Colors.red),
                ),
              ),
              if (isAdmin)
                const CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.shield, color: Colors.amber, size: 20),
                )
            ],
          ),
          const SizedBox(height: 12),
          Text(user.displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(user.email, style: const TextStyle(fontSize: 15, color: Colors.grey)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? (isAdmin ? Colors.amber.shade50 : Colors.green.shade50) : Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isActive ? (isAdmin ? Colors.amber.shade200 : Colors.green.shade200) : Colors.red.shade200),
            ),
            child: Text(
              isActive ? (isAdmin ? "🛡️ QUẢN TRỊ VIÊN" : "NGƯỜI DÙNG") : "TÀI KHOẢN ĐANG KHÓA",
              style: TextStyle(
                  color: isActive ? (isAdmin ? Colors.amber.shade900 : Colors.green.shade800) : Colors.red.shade800,
                  fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPointsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow("Ví điểm hiện tại", "${user.currentPoints}", isHighlight: true, highlightColor: Colors.orange),
            const Divider(height: 24),
            _buildInfoRow("Tổng tích lũy", "${user.totalPoints}"),
            const SizedBox(height: 10),
            _buildInfoRow("Điểm tuần/tháng", "${user.weekPoints} / ${user.monthPoints}"),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow("Địa chỉ", "${user.address.district}, ${user.address.city}"),
            const Divider(height: 24),
            _buildInfoRow("Ngân hàng", user.bankInfo?.bankCode ?? "Chưa liên kết"),
            if (user.bankInfo != null) ...[
              const SizedBox(height: 10),
              _buildInfoRow("STK", user.bankInfo!.accountNo),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildAdminActionCard(BuildContext context, WidgetRef ref, bool isAdmin, bool isActive) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.deepPurple, width: 0.5)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Nút Cấp/Hủy quyền Admin
            _buildActionButton(
              icon: isAdmin ? Icons.remove_moderator : Icons.add_moderator,
              label: isAdmin ? "HỦY QUYỀN ADMIN" : "CẤP QUYỀN ADMIN",
              color: isAdmin ? Colors.red : Colors.deepPurple,
              onPressed: !isActive ? null : () => _showConfirmDialog(context, ref, "role", isAdmin),
            ),
            const SizedBox(height: 12),
            // Nút Khóa/Mở khóa tài khoản
            _buildActionButton(
              icon: isActive ? Icons.lock_outline : Icons.lock_open,
              label: isActive ? "KHÓA TÀI KHOẢN" : "MỞ KHÓA TÀI KHOẢN",
              color: isActive ? Colors.redAccent : Colors.green,
              onPressed: () => _showConfirmDialog(context, ref, "status", !isActive),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(WidgetRef ref, int activeTab) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              _buildTabButton(ref, "Nhiệm vụ", 0, activeTab),
              _buildTabButton(ref, "Rút tiền", 1, activeTab),
            ],
          ),
        ),
        const SizedBox(height: 12),
        activeTab == 0 ? _buildSubmissionHistory(ref) : _buildTransactionHistory(ref),
      ],
    );
  }

  // --- CÁC HÀM XỬ LÝ ACTION ---

  void _showConfirmDialog(BuildContext context, WidgetRef ref, String type, bool currentValue) {
    String title = "";
    String content = "";
    if (type == "role") {
      title = currentValue ? "Hủy quyền Admin" : "Cấp quyền Admin";
      content = "Bạn có chắc chắn muốn thay đổi đặc quyền quản trị của người dùng này?";
    } else {
      title = currentValue ? "Mở khóa tài khoản" : "Khóa tài khoản";
      content = "Hành động này sẽ thay đổi khả năng đăng nhập của người dùng.";
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              if (type == "role") {
                ref.read(adminUserActionProvider.notifier).changeRole(user.uid, currentValue ? 'user' : 'admin');
              } else {
                ref.read(adminUserActionProvider.notifier).toggleStatus(user.uid, !currentValue);
              }
              Navigator.pop(ctx);
              Navigator.pop(context); // Quay về danh sách để cập nhật UI
            },
            child: const Text("Xác nhận"),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildActionButton({required IconData icon, required String label, required Color color, VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 18),
        label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTabButton(WidgetRef ref, String label, int index, int currentTab) {
    final isSelected = currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(activeHistoryTabProvider.notifier).state = index,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: isSelected ? AppColors.primaryGreen : Colors.transparent, borderRadius: BorderRadius.circular(10)),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildSubmissionHistory(WidgetRef ref) {
    final submissionsAsync = ref.watch(userSubmissionsProvider(user.uid));
    return submissionsAsync.when(
      data: (list) => list.isEmpty ? const Padding(padding: EdgeInsets.all(20), child: Text("Chưa nộp bài nào", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)))
          : ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: list.length, itemBuilder: (ctx, i) => _buildHistoryTile(list[i].taskTitle, list[i].createdAt, "+${list[i].pointsReward}", list[i].status)),
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text("Lỗi: $e"),
    );
  }

  Widget _buildTransactionHistory(WidgetRef ref) {
    final txAsync = ref.watch(userTransactionsProvider(user.uid));
    return txAsync.when(
      data: (list) => list.isEmpty ? const Padding(padding: EdgeInsets.all(20), child: Text("Chưa rút tiền lần nào", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)))
          : ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: list.length, itemBuilder: (ctx, i) => _buildHistoryTile("Rút ${list[i].amountVND}đ", list[i].createdAt, "-${list[i].pointsUsed}", list[i].status)),
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text("Lỗi: $e"),
    );
  }

  Widget _buildHistoryTile(String title, DateTime date, String point, String status) {
    Color statusColor = status == 'approved' || status == 'completed' ? Colors.green : (status == 'rejected' ? Colors.red : Colors.orange);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(DateFormat('dd/MM HH:mm').format(date), style: const TextStyle(fontSize: 12)),
      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(point, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
        Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900)),
      ]),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(children: [Icon(icon, size: 20, color: color), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false, Color highlightColor = Colors.black}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.black54)),
      Text(value, style: TextStyle(fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500, fontSize: isHighlight ? 18 : 14, color: isHighlight ? highlightColor : Colors.black87)),
    ]);
  }
}