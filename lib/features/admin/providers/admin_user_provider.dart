// lib/features/admin/providers/admin_user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/user_model.dart';
import '../../../data/models/submission_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/admin_user_repository.dart';

// --- CHỈNH SỬA 1: Import thêm NotificationRepository ---
import '../../../data/repositories/notification_repository.dart';
// -------------------------------------------------------

final adminUserRepoProvider = Provider((ref) => AdminUserRepository());

// Provider lấy danh sách nhiệm vụ của User
final userSubmissionsProvider = StreamProvider.family<List<SubmissionModel>, String>((ref, userId) {
  return ref.watch(adminUserRepoProvider).getUserSubmissions(userId);
});

// Provider lấy danh sách giao dịch của User
final userTransactionsProvider = StreamProvider.family<List<TransactionModel>, String>((ref, userId) {
  return ref.watch(adminUserRepoProvider).getUserTransactions(userId);
});

// Quản lý Tab đang chọn trong phần Lịch sử (0: Nhiệm vụ, 1: Giao dịch)
final activeHistoryTabProvider = StateProvider<int>((ref) => 0);

// --- CÁC PROVIDER TRẠNG THÁI (STATE) ---
final userSearchQueryProvider = StateProvider<String>((ref) => "");

enum UserFilter { all, active, blocked }
final userFilterProvider = StateProvider<UserFilter>((ref) => UserFilter.all);

enum UserSort { nameAZ, pointsDesc, totalPointsDesc }
final userSortProvider = StateProvider<UserSort>((ref) => UserSort.pointsDesc);

// --- LUỒNG DỮ LIỆU TỪ FIREBASE ---
final adminUsersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(adminUserRepoProvider).getAllUsers();
});

// --- PROVIDER XỬ LÝ LỌC & SẮP XẾP TỔNG HỢP ---
final filteredUsersProvider = Provider<AsyncValue<List<UserModel>>>((ref) {
  final usersAsync = ref.watch(adminUsersStreamProvider);
  final query = ref.watch(userSearchQueryProvider).toLowerCase();
  final filter = ref.watch(userFilterProvider);
  final sort = ref.watch(userSortProvider);

  return usersAsync.whenData((list) {
    // 1. Lọc theo từ khóa Tìm kiếm
    var filteredList = list.where((user) {
      if (query.isEmpty) return true;
      return (user.displayName).toLowerCase().contains(query) ||
          (user.email).toLowerCase().contains(query);
    }).toList();

    // 2. Lọc theo Trạng thái (Active / Blocked)
    filteredList = filteredList.where((user) {
      final isBlocked = user.role == 'blocked';
      if (filter == UserFilter.active) return !isBlocked;
      if (filter == UserFilter.blocked) return isBlocked;
      return true; // UserFilter.all
    }).toList();

    // 3. Sắp xếp danh sách
    filteredList.sort((a, b) {
      switch (sort) {
        case UserSort.nameAZ:
          return a.displayName.compareTo(b.displayName);
        case UserSort.pointsDesc:
          return b.currentPoints.compareTo(a.currentPoints); // Giàu điểm nhất xếp trên
        case UserSort.totalPointsDesc:
          return b.totalPoints.compareTo(a.totalPoints); // Tích lũy nhiều nhất xếp trên
      }
    });

    return filteredList;
  });
});

// --- VIEW MODEL XỬ LÝ ACTION ---
class AdminUserActionViewModel extends StateNotifier<AsyncValue<void>> {
  final AdminUserRepository _repo;

  // --- CHỈNH SỬA 2: Khởi tạo Notification Repo để gửi thông báo ---
  final NotificationRepository _notiRepo = NotificationRepository();
  // ---------------------------------------------------------------

  AdminUserActionViewModel(this._repo) : super(const AsyncValue.data(null));

  Future<void> toggleStatus(String uid, bool currentStatus) async {
    state = const AsyncValue.loading();
    try {
      await _repo.toggleUserStatus(uid, currentStatus);

      // --- CHỈNH SỬA 3: Bắn thông báo tự động khi Khóa/Mở khóa tài khoản ---
      String title = currentStatus ? "🔒 Tài khoản bị khóa" : "🔓 Mở khóa tài khoản";
      String body = currentStatus
          ? "Tài khoản của bạn đã bị khóa do vi phạm chính sách của hệ thống."
          : "Tài khoản của bạn đã được mở khóa. Chào mừng quay trở lại!";

      await _notiRepo.sendNotification(
        userId: uid,
        title: title,
        body: body,
        type: 'system', // Loại: Hệ thống
      );
      // --------------------------------------------------------------------

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> changeRole(String uid, String newRole) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateUserRole(uid, newRole);

      // --- CHỈNH SỬA 4: Bắn thông báo tự động khi Cấp/Hủy quyền Admin ---
      String title = newRole == 'admin' ? "🛡️ Thăng cấp Quản trị viên" : "Hủy quyền Quản trị";
      String body = newRole == 'admin'
          ? "Chúc mừng! Bạn đã được cấp quyền Admin. Bây giờ bạn có thể truy cập khu vực Quản trị."
          : "Tài khoản của bạn đã được chuyển về cấp độ Người dùng tiêu chuẩn.";

      await _notiRepo.sendNotification(
        userId: uid,
        title: title,
        body: body,
        type: 'role', // Loại: Vai trò
      );
      // ------------------------------------------------------------------

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final adminUserActionProvider = StateNotifierProvider<AdminUserActionViewModel, AsyncValue<void>>((ref) {
  return AdminUserActionViewModel(ref.read(adminUserRepoProvider));
});