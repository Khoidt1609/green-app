// lib/features/notifications/providers/notification_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';

// 1. Khởi tạo Repository
final notificationRepoProvider = Provider((ref) => NotificationRepository());

// 2. Stream lấy danh sách thông báo của User đang đăng nhập
final userNotificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value([]);
  }
  return ref.watch(notificationRepoProvider).getUserNotifications(user.uid);
});

// 3. Provider tính toán số lượng thông báo "Chưa đọc" (để hiện số đỏ trên cái Chuông)
final unreadCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(userNotificationsProvider);

  return notificationsAsync.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});