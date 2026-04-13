// --- PROVIDERS ---
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/admin_transaction_repository.dart';

final adminTxRepoProvider = Provider((ref) => AdminTransactionRepository());

// Stream danh sách
final pendingWithdrawalsProvider = StreamProvider<List<TransactionModel>>((ref) {
  return ref.watch(adminTxRepoProvider).getPendingWithdrawals();
});

// Action xử lý nút bấm
class AdminTxActionViewModel extends StateNotifier<AsyncValue<void>> {
  final AdminTransactionRepository _repo;
  AdminTxActionViewModel(this._repo) : super(const AsyncValue.data(null));

  Future<void> markAsCompleted(String txId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.completeTransaction(txId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> reject(String txId, String userId, int pointsToRefund) async {
    state = const AsyncValue.loading();
    try {
      await _repo.rejectAndRefund(txId, userId, pointsToRefund);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final adminTxActionProvider = StateNotifierProvider<AdminTxActionViewModel, AsyncValue<void>>((ref) {
  return AdminTxActionViewModel(ref.read(adminTxRepoProvider));
});