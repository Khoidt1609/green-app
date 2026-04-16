// lib/features/reward/viewmodels/reward_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_app/data/models/reward_model.dart';
import 'package:green_app/data/repositories/reward_repository.dart';

class RewardState {
  final List<RewardItem> rewards;
  final List<TransactionRecord> transactions;
  final bool isLoading;
  final bool isRedeeming;
  final String? error;
  final String? successMessage;
  final int currentPoints;
  final int totalPoints;
  final String? displayName;
  final Map<String, String>? savedBankInfo;

  const RewardState({
    this.rewards = const [],
    this.transactions = const [],
    this.isLoading = false,
    this.isRedeeming = false,
    this.error,
    this.successMessage,
    this.currentPoints = 0,
    this.totalPoints = 0,
    this.displayName,
    this.savedBankInfo,
  });

  RewardState copyWith({
    List<RewardItem>? rewards,
    List<TransactionRecord>? transactions,
    bool? isLoading,
    bool? isRedeeming,
    String? error,
    String? successMessage,
    int? currentPoints,
    int? totalPoints,
    String? displayName,
    Map<String, String>? savedBankInfo,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return RewardState(
      rewards: rewards ?? this.rewards,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      isRedeeming: isRedeeming ?? this.isRedeeming,
      error: clearError ? null : error ?? this.error,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
      currentPoints: currentPoints ?? this.currentPoints,
      totalPoints: totalPoints ?? this.totalPoints,
      displayName: displayName ?? this.displayName,
      savedBankInfo: savedBankInfo ?? this.savedBankInfo,
    );
  }
}

class RewardViewModel extends StateNotifier<RewardState> {
  final RewardRepository _repo;

  RewardViewModel(this._repo) : super(const RewardState()) {
    _init();
  }

  void _init() {
    _watchProfile();
    _loadData();
  }

  void _watchProfile() {
    _repo.watchUserProfile().listen((data) {
      final bankInfo = data['bankInfo'] as Map<String, dynamic>?;
      state = state.copyWith(
        currentPoints: (data['currentPoints'] as num?)?.toInt() ?? 0,
        totalPoints: (data['totalPoints'] as num?)?.toInt() ?? 0,
        displayName: data['displayName'] as String?,
        savedBankInfo: bankInfo != null
            ? {
                'bankCode': bankInfo['bankCode'] as String? ?? '',
                'accountNo': bankInfo['accountNo'] as String? ?? '',
                'accountName': bankInfo['accountName'] as String? ?? '',
              }
            : null,
      );
    });
  }

  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true);
    try {
      final results = await Future.wait([
        _repo.getRewards(),
        _repo.getTransactions(),
      ]);
      state = state.copyWith(
        rewards: results[0] as List<RewardItem>,
        transactions: results[1] as List<TransactionRecord>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Không thể tải dữ liệu: $e');
    }
  }

  Future<void> refresh() => _loadData();

  Future<bool> redeemReward({
    required RewardItem reward,
    required String bankCode,
    required String accountNo,
    required String accountName,
  }) async {
    state = state.copyWith(isRedeeming: true, clearError: true);
    try {
      await _repo.redeemReward(
        reward: reward,
        bankDetails: {
          'bankCode': bankCode,
          'accountNo': accountNo,
          'accountName': accountName,
        },
        userName: state.displayName ?? 'User',
      );
      // Reload transactions
      final txs = await _repo.getTransactions();
      state = state.copyWith(
        isRedeeming: false,
        transactions: txs,
        successMessage: 'Đã gửi yêu cầu đổi thưởng! Admin sẽ xử lý sớm.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isRedeeming: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final rewardViewModelProvider =
    StateNotifierProvider<RewardViewModel, RewardState>((ref) {
  return RewardViewModel(ref.read(rewardRepositoryProvider));
});
