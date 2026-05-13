// lib/features/notifications/views/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/notification_model.dart';
import '../providers/notification_provider.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text("Thông báo", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () {
              if (user != null) {
                ref.read(notificationRepoProvider).markAllAsRead(user.uid);
              }
            },
            child: const Text("Đã đọc tất cả", style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
          ),
          if (user != null)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              tooltip: 'Xóa thông báo đã đọc',
              onPressed: () => _showDeleteConfirmDialog(context, ref, user.uid),
            ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
            itemBuilder: (context, index) {
              final noti = notifications[index];
              return _buildNotificationItem(context, ref, noti);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Đã xảy ra lỗi: $err')),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, WidgetRef ref, NotificationModel noti) {
    // 1. Khai báo biến Icon và Màu sắc ở ĐẦU hàm để các phần dưới đều dùng được
    IconData icon;
    Color iconColor;
    if (noti.type == 'role') {
      icon = Icons.admin_panel_settings;
      iconColor = Colors.deepPurple;
    } else if (noti.type == 'system') {
      icon = Icons.info_outline;
      iconColor = Colors.blue;
    } else if (noti.type == 'transaction') {
      icon = Icons.account_balance_wallet;
      iconColor = Colors.orange;
    } else {
      icon = Icons.notifications;
      iconColor = AppColors.primaryGreen;
    }

    // 2. Trả về Dismissible để Vuốt là Xóa
    return Dismissible(
      key: Key(noti.id),
      direction: DismissDirection.endToStart, // Vuốt từ phải sang trái
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.redAccent,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) {
        ref.read(notificationRepoProvider).deleteNotification(noti.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã xóa thông báo"), duration: Duration(seconds: 1)),
        );
      },
      child: InkWell(
        onTap: () {
          if (!noti.isRead) {
            ref.read(notificationRepoProvider).markAsRead(noti.id);
          }
        },
        child: Container(
          color: noti.isRead ? Colors.transparent : Colors.blue.withOpacity(0.05),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: iconColor.withOpacity(0.1),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      noti.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: noti.isRead ? FontWeight.w600 : FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      noti.body,
                      style: TextStyle(
                        fontSize: 14,
                        color: noti.isRead ? Colors.black54 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(noti.createdAt),
                      style: TextStyle(fontSize: 12, color: noti.isRead ? Colors.grey : AppColors.primaryGreen, fontWeight: noti.isRead ? FontWeight.normal : FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (!noti.isRead)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("Bạn chưa có thông báo nào", style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, String userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep, color: Colors.redAccent),
            SizedBox(width: 8),
            Text("Dọn dẹp thông báo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text("Bạn có chắc chắn muốn xóa TẤT CẢ các thông báo đã đọc không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(notificationRepoProvider).deleteReadNotifications(userId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Đã dọn dẹp các thông báo cũ!"), backgroundColor: AppColors.primaryGreen),
              );
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}