// --- PROVIDERS ---
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/admin_transaction_repository.dart';

final adminTxRepoProvider = Provider((ref) => AdminTransactionRepository());

// Stream danh sách
final pendingWithdrawalsProvider = StreamProvider<List<TransactionModel>>((
  ref,
) {
  return ref.watch(adminTxRepoProvider).getPendingWithdrawals();
});

// Action xử lý nút bấm
class AdminTxActionViewModel extends StateNotifier<AsyncValue<void>> {
  final AdminTransactionRepository _repo;
  final NotificationRepository _notiRepo = NotificationRepository();
  AdminTxActionViewModel(this._repo) : super(const AsyncValue.data(null));

  // Future<void> markAsCompleted(String txId, String userId) async {
  //   state = const AsyncValue.loading();
  //   try {
  //     // await _repo.completeTransaction(txId);
  //     // --- BẮN THÔNG BÁO: RÚT TIỀN THÀNH CÔNG ---
  //     await _notiRepo.sendNotification(
  //       userId: userId,
  //       title: "💰 Rút tiền thành công",
  //       body:
  //           "Yêu cầu rút tiền của bạn đã được xử lý thành công. Vui lòng kiểm tra tài khoản ngân hàng.",
  //       type: "transaction",
  //     );
  //     state = const AsyncValue.data(null);
  //   } catch (e, stack) {
  //     state = AsyncValue.error(e, stack);
  //   }
  // }

  Future<void> reject(String txId, String userId, int pointsToRefund) async {
    state = const AsyncValue.loading();
    try {
      await _repo.rejectAndRefund(txId, userId, pointsToRefund);
      // --- BẮN THÔNG BÁO: HỦY LỆNH RÚT TIỀN ---
      await _notiRepo.sendNotification(
        userId: userId,
        title: "❌ Hủy lệnh rút tiền",
        body:
            "Yêu cầu rút tiền của bạn đã bị hủy (có thể do sai thông tin ngân hàng). $pointsToRefund điểm đã được hoàn lại vào ví.",
        type: "transaction",
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final adminTxActionProvider =
    StateNotifierProvider<AdminTxActionViewModel, AsyncValue<void>>((ref) {
      return AdminTxActionViewModel(ref.read(adminTxRepoProvider));
    });
