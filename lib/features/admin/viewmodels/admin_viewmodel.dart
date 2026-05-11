import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/models/submission_model.dart';
import '../providers/submission_provider.dart';

// ViewModel xử lý khi Admin bấm nút Duyệt/Từ chối
class AdminActionViewModel extends StateNotifier<AsyncValue<void>> {
  final AdminRepository _repo;

  AdminActionViewModel(this._repo) : super(const AsyncValue.data(null));

  Future<void> approve(String submissionId, String userId, int points) async {
    state = const AsyncValue.loading();
    try {
      await _repo.approveTask(submissionId, userId, points);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> reject(String submissionId, String reason) async {
    state = const AsyncValue.loading();
    try {
      await _repo.rejectTask(submissionId, reason);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final adminActionProvider = StateNotifierProvider<AdminActionViewModel, AsyncValue<void>>((ref) {
  return AdminActionViewModel(ref.read(adminRepoProvider));
});