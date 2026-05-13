// lib/features/notifications/views/notification_bell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';
import 'notification_screen.dart';

class NotificationBell extends ConsumerWidget {
  final Color iconColor;

  const NotificationBell({super.key, this.iconColor = Colors.black87});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lắng nghe số lượng thông báo chưa đọc
    final unreadCount = ref.watch(unreadCountProvider);

    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_outlined, size: 28, color: iconColor),

          // Nếu có thông báo chưa đọc thì mới hiện chấm đỏ
          if (unreadCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Center(
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
      onPressed: () {
        // Khi bấm vào chuông -> Chuyển sang màn hình danh sách thông báo
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationScreen()),
        );
      },
    );
  }
}