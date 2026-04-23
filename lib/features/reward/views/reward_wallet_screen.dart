// lib/features/reward/views/reward_wallet_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import 'package:green_app/data/models/reward_model.dart';
import 'package:green_app/data/models/transaction_model.dart';
import '../viewmodels/reward_viewmodel.dart';

class RewardWalletScreen extends ConsumerStatefulWidget {
  const RewardWalletScreen({super.key});

  @override
  ConsumerState<RewardWalletScreen> createState() => _RewardWalletScreenState();
}

class _RewardWalletScreenState extends ConsumerState<RewardWalletScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(rewardViewModelProvider);
    final vm = ref.read(rewardViewModelProvider.notifier);

    // Show success/error snackbar
    ref.listen<RewardState>(rewardViewModelProvider, (prev, next) {
      if (next.successMessage != null &&
          next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.successMessage!),
          backgroundColor: AppColors.primaryGreen,
        ));
        vm.clearMessages();
      }
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: colorScheme.error,
        ));
        vm.clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text(
          '🎁  Ví Phần Thưởng',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        actions: [
          IconButton(
            onPressed: ref.read(rewardViewModelProvider.notifier).refresh,
            icon: Icon(Icons.refresh_rounded, color: colorScheme.onPrimary),
          ),
        ],
      ),
      body: Column(
        children: [
          // Points card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _PointsCard(state: state),
          ),
          const SizedBox(height: 12),
          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildTabBar(theme),
          ),
          const SizedBox(height: 8),
          // Tab body
          Expanded(
            child: state.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        color: colorScheme.primary))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _RewardListTab(state: state, vm: vm),
                      _TransactionHistoryTab(
                          transactions: state.transactions),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: colorScheme.onPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: const [
          Tab(text: '🏪  Gói Thưởng'),
          Tab(text: '📋  Lịch Sử'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Points card
// ─────────────────────────────────────────────
class _PointsCard extends StatelessWidget {
  const _PointsCard({required this.state});
  final RewardState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            AppColors.primaryDarkGreen,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ĐIỂM XANH CỦA BẠN',
            style: TextStyle(
              color: colorScheme.onPrimary.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${state.currentPoints}',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 6),
                child: Text(
                  'pts',
                  style: TextStyle(
                      color: colorScheme.onPrimary.withValues(alpha: 0.7),
                      fontSize: 16),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Tổng tích lũy',
                    style: TextStyle(
                        color: colorScheme.onPrimary.withValues(alpha: 0.7),
                        fontSize: 11),
                  ),
                  Text(
                    '${state.totalPoints} pts',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PointsProgressBar(currentPoints: state.currentPoints),
        ],
      ),
    );
  }
}

class _PointsProgressBar extends StatelessWidget {
  const _PointsProgressBar({required this.currentPoints});
  final int currentPoints;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const milestones = [500, 1000, 2000, 5000];
    final next = milestones.firstWhere(
      (m) => m > currentPoints,
      orElse: () => milestones.last,
    );
    final prev = next == milestones.first
        ? 0
        : milestones[milestones.indexOf(next) - 1];
    final progress =
        ((currentPoints - prev) / (next - prev)).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.25),
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${next - currentPoints} pts đến mốc tiếp theo',
              style: TextStyle(
                  color: colorScheme.onPrimary.withValues(alpha: 0.75),
                  fontSize: 11),
            ),
            Text(
              '$next pts',
              style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Reward list tab
// ─────────────────────────────────────────────
class _RewardListTab extends StatelessWidget {
  const _RewardListTab({required this.state, required this.vm});
  final RewardState state;
  final RewardViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (state.rewards.isEmpty) {
      return Center(
          child: Text(
        'Chưa có gói thưởng nào.',
        style: TextStyle(color: AppColors.textSecondary),
      ));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: state.rewards.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final reward = state.rewards[index];
        final canAfford = state.currentPoints >= reward.pointCost;
        return _RewardCard(
          reward: reward,
          canAfford: canAfford,
          isRedeeming: state.isRedeeming,
          savedBankInfo: state.savedBankInfo,
          onRedeem: () => _showRedeemSheet(context, reward, state, vm),
        );
      },
    );
  }

  void _showRedeemSheet(
    BuildContext context,
    RewardItem reward,
    RewardState state,
    RewardViewModel vm,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _RedeemSheet(
        reward: reward,
        savedBankInfo: state.savedBankInfo,
        isRedeeming: state.isRedeeming,
        currentPoints: state.currentPoints,
        onConfirm: (bankCode, accountNo, accountName) async {
          Navigator.pop(ctx);
          await vm.redeemReward(
            reward: reward,
            bankCode: bankCode,
            accountNo: accountNo,
            accountName: accountName,
          );
        },
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.canAfford,
    required this.isRedeeming,
    required this.onRedeem,
    this.savedBankInfo,
  });
  final RewardItem reward;
  final bool canAfford;
  final bool isRedeeming;
  final VoidCallback onRedeem;
  final Map<String, String>? savedBankInfo;

  static const _gold = Color(0xFFD4970A);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: canAfford
              ? colorScheme.primary.withValues(alpha: 0.4)
              : colorScheme.outline,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: reward.isCash
                  ? _gold.withValues(alpha: 0.12)
                  : colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              reward.isCash
                  ? Icons.account_balance_rounded
                  : Icons.card_giftcard_rounded,
              color: reward.isCash ? _gold : colorScheme.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.name,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  reward.description,
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${reward.pointCost} pts',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatVND(reward.valueVND),
                      style: const TextStyle(
                        color: _gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Button
          GestureDetector(
            onTap: canAfford && !isRedeeming ? onRedeem : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: canAfford ? colorScheme.primary : colorScheme.outline,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                canAfford ? 'Đổi' : 'Thiếu',
                style: TextStyle(
                  color: canAfford
                      ? colorScheme.onPrimary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Redeem bottom sheet
// ─────────────────────────────────────────────
class _RedeemSheet extends StatefulWidget {
  const _RedeemSheet({
    required this.reward,
    required this.isRedeeming,
    required this.currentPoints,
    required this.onConfirm,
    this.savedBankInfo,
  });
  final RewardItem reward;
  final bool isRedeeming;
  final int currentPoints;
  final Map<String, String>? savedBankInfo;
  final Future<void> Function(String, String, String) onConfirm;

  @override
  State<_RedeemSheet> createState() => _RedeemSheetState();
}

class _RedeemSheetState extends State<_RedeemSheet> {
  late final TextEditingController _bankCodeCtrl;
  late final TextEditingController _accountNoCtrl;
  late final TextEditingController _accountNameCtrl;
  final _formKey = GlobalKey<FormState>();

  static const _gold = Color(0xFFD4970A);

  @override
  void initState() {
    super.initState();
    final saved = widget.savedBankInfo;
    _bankCodeCtrl = TextEditingController(text: saved?['bankCode'] ?? '');
    _accountNoCtrl = TextEditingController(text: saved?['accountNo'] ?? '');
    _accountNameCtrl =
        TextEditingController(text: saved?['accountName'] ?? '');
  }

  @override
  void dispose() {
    _bankCodeCtrl.dispose();
    _accountNoCtrl.dispose();
    _accountNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reward = widget.reward;
    final remaining = widget.currentPoints - reward.pointCost;
    final mediaQuery = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.outline,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                'Xác nhận đổi thưởng',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              // Reward summary
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Row(
                  children: [
                    Icon(
                      reward.isCash
                          ? Icons.account_balance_rounded
                          : Icons.card_giftcard_rounded,
                      color: reward.isCash ? _gold : colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reward.name,
                            style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 14),
                          ),
                          Text(
                            _formatVND(reward.valueVND),
                            style: const TextStyle(
                                color: _gold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '−${reward.pointCost} pts',
                          style: TextStyle(
                              color: colorScheme.error,
                              fontWeight: FontWeight.w700,
                              fontSize: 13),
                        ),
                        Text(
                          'Còn: $remaining pts',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'THÔNG TIN NGÂN HÀNG (VietQR)',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              _buildField(
                context: context,
                controller: _bankCodeCtrl,
                label: 'Mã ngân hàng',
                hint: 'VD: VCB, TCB, MB...',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập mã ngân hàng'
                    : null,
              ),
              const SizedBox(height: 10),
              _buildField(
                context: context,
                controller: _accountNoCtrl,
                label: 'Số tài khoản',
                hint: 'Nhập số tài khoản',
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập số tài khoản'
                    : null,
              ),
              const SizedBox(height: 10),
              _buildField(
                context: context,
                controller: _accountNameCtrl,
                label: 'Tên chủ tài khoản',
                hint: 'Viết không dấu, in hoa',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập tên tài khoản'
                    : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: widget.isRedeeming
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            widget.onConfirm(
                              _bankCodeCtrl.text.trim().toUpperCase(),
                              _accountNoCtrl.text.trim(),
                              _accountNameCtrl.text.trim().toUpperCase(),
                            );
                          }
                        },
                  child: widget.isRedeeming
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Xác nhận đổi thưởng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Transaction history tab
// ─────────────────────────────────────────────
class _TransactionHistoryTab extends StatelessWidget {
  const _TransactionHistoryTab({required this.transactions});
  final List<TransactionRecord> transactions;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded,
                color: AppColors.textSecondary, size: 48),
            const SizedBox(height: 12),
            Text(
              'Chưa có giao dịch nào.',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _TransactionTile(tx: transactions[i]),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx});
  final TransactionRecord tx;

  static const _gold = Color(0xFFD4970A);
  static const _pendingOrange = Color(0xFFE07B00);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final statusColor = tx.isCompleted
        ? colorScheme.primary
        : tx.status == 'cancelled'
            ? colorScheme.error
            : _pendingOrange;

    final statusLabel = tx.isCompleted
        ? 'Đã thanh toán'
        : tx.status == 'cancelled'
            ? 'Đã hủy'
            : 'Đang xử lý';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              tx.isCompleted
                  ? Icons.check_circle_outline_rounded
                  : tx.status == 'cancelled'
                      ? Icons.cancel_outlined
                      : Icons.pending_outlined,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.rewardName,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusLabel,
                        style:
                            TextStyle(color: statusColor, fontSize: 10),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(tx.createdAt),
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '−${tx.pointCost} pts',
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                _formatVND(tx.amountVND),
                style: const TextStyle(color: _gold, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────
String _formatVND(int amount) {
  final s = amount.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
    buffer.write(s[i]);
  }
  return '${buffer}đ';
}

String _formatDate(DateTime dt) {
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}