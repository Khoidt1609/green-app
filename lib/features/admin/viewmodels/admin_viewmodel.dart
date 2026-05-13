import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/models/submission_model.dart';
import '../providers/submission_provider.dart';
import '../../../data/repositories/notification_repository.dart';
// ViewModel xử lý khi Admin bấm nút Duyệt/Từ chối
class AdminActionViewModel extends StateNotifier<AsyncValue<void>> {
  final AdminRepository _repo;
  final NotificationRepository _notiRepo = NotificationRepository();

  AdminActionViewModel(this._repo) : super(const AsyncValue.data(null));

  Future<void> approve(String submissionId, String userId, int points) async {
    state = const AsyncValue.loading();
    try {
      await _repo.approveTask(submissionId, userId, points);
      await _notiRepo.sendNotification(
        userId: userId,
        title: "✅ Nhiệm vụ được duyệt",
        body: "Tuyệt vời! Bài nộp nhiệm vụ của bạn đã được duyệt. Bạn được cộng thêm $points điểm.",
        type: "submission",
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> reject(String submissionId, String userId, String reason) async {
    state = const AsyncValue.loading();
    try {
      await _repo.rejectTask(submissionId, reason);
      await _notiRepo.sendNotification(
        userId: userId,
        title: "⚠️ Nhiệm vụ chưa hợp lệ",
        body: "Rất tiếc, bài nộp của bạn không được chấp nhận. Lý do: $reason. Vui lòng thử lại nhé!",
        type: "submission",
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final adminActionProvider = StateNotifierProvider<AdminActionViewModel, AsyncValue<void>>((ref) {
  return AdminActionViewModel(ref.read(adminRepoProvider));
});