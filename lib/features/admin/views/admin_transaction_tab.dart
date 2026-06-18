import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/transaction_model.dart';
import '../viewmodels/admin_tx_action_viewmodel.dart';

class AdminTransactionsTab extends ConsumerWidget {
  const AdminTransactionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(pendingWithdrawalsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: txAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text("Không có yêu cầu rút tiền nào."));
          }
          return Column(
            children: [
              _buildSummaryHeader(list),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final tx = list[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor: AppColors.accentOrange
                                      .withOpacity(0.1),
                                  child: const Icon(
                                    Icons.account_balance_wallet,
                                    color: AppColors.accentOrange,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${tx.userName} muốn rút tiền",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Ngân hàng: ${tx.bankDetails?.bankCode}",
                                      ),
                                      Text(
                                        "Số tiền: ${tx.amountVND} VNĐ",
                                        style: const TextStyle(
                                          color: AppColors.error,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(
                              height: 24,
                            ), // Đường kẻ ngang phân tách nội dung và nút

                            Row(
                              children: [
                                // Nút Từ chối kiểu Outlined cho nhẹ nhàng
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(
                                        color: Colors.red,
                                        width: 1,
                                      ),
                                    ),

                                    onPressed: () => _showRejectConfirmDialog(
                                      context,
                                      ref,
                                      tx,
                                    ),
                                    icon: const Icon(
                                      Icons.cancel_outlined,
                                      size: 18,
                                    ),
                                    label: const Text("Từ chối"),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Nút Xử lý kiểu Elevated cho nổi bật
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryGreen,
                                    ),
                                    onPressed: () =>
                                        _showVietQRDialog(context, ref, tx),
                                    icon: const Icon(
                                      Icons.qr_code_scanner,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      "Xử lý",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Lỗi: $e")),
      ),
    );
  }

  // Dialog hiển thị mã QR
  void _showVietQRDialog(
    BuildContext context,
    WidgetRef ref,
    TransactionModel tx,
  ) {
    final bankCode = tx.bankDetails?.bankCode ?? '';
    final accountNo = tx.bankDetails?.accountNo ?? '';
    final accountName = tx.bankDetails?.accountName ?? '';
    final amount = tx.amountVND;
    final note = "GREENAPP ${tx.id}";
    // Mã hóa chuỗi để bỏ vào URL (biến khoảng trắng thành %20)
    final encodedNote = Uri.encodeComponent(note);
    // Tạo QR bằng vietqr.io
    final qrUrl =
        'https://img.vietqr.io/image/$bankCode-$accountNo-compact2.png'
        '?amount=$amount&addInfo=$encodedNote&accountName=$accountName';

    showDialog(
      context: context,
      barrierDismissible: false, // Bắt buộc admin bấm Hoàn thành hoặc Hủy
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Quét mã chuyển tiền", textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Khung hiển thị mã QR
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  // Tự động load ảnh QR từ API
                  child: Image.network(
                    qrUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Dùng app ngân hàng của bạn quét mã trên.\nTiền và nội dung sẽ tự động điền.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              // Hiệu ứng chờ
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Đang chờ xử lý...",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                      color: AppColors.primaryDarkGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Đóng", style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  void _showRejectConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    TransactionModel tx,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          "Xác nhận từ chối",
          style: TextStyle(color: Colors.red),
        ),
        content: Text(
          "Bạn có chắc chắn muốn hủy lệnh rút ${tx.amountVND}đ của ${tx.userName}?\n\n"
          "Hệ thống sẽ hoàn lại điểm vào tài khoản của người dùng này.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx); // Đóng popup

              // Gọi ViewModel để xử lý Firebase
              await ref
                  .read(adminTxActionProvider.notifier)
                  .reject(tx.id, tx.userId, tx.pointsUsed);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Đã hủy và hoàn điểm!"),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text(
              "Từ chối lệnh",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(List<TransactionModel> list) {
    // Tính tổng tiền đang chờ xử lý
    final totalAmount = list.fold<int>(
      0,
      (sum, item) => sum + (item.amountVND ?? 0),
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.primaryDarkGreen],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tổng tiền cần thanh toán",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            "${totalAmount.toString()} VNĐ", // Nên dùng intl để format 1.000.000
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Có ${list.length} yêu cầu đang chờ duyệt",
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
