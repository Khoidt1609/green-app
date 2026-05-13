import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Để format ngày tháng
import '../../../core/constants/app_colors.dart';
import '../../../data/models/submission_model.dart';

class SubmissionDetailBottomSheet extends ConsumerWidget {
  final SubmissionModel submission;

  const SubmissionDetailBottomSheet({super.key, required this.submission});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenHeight = MediaQuery.of(context).size.height;
    // final isPending = submission.status == 'pending';
    print("Dữ liệu ghi chú nạp về: ${submission.userNote}");
    return Container(
      height: screenHeight * 0.7,
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const Text(
            "Chi tiết bài nộp",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Ghi chú + Hình ảnh
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          Icons.person,
                          "Người nộp:",
                          submission.userName,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.task_alt,
                          "Nhiệm vụ:",
                          submission.taskTitle ?? "Không rõ",
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.access_time,
                          "Thời gian:",
                          DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(submission.createdAt),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.stars,
                          "Điểm thưởng:",
                          "+${submission.pointsReward} điểm",
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // note
                  const Text(
                    "Ghi chú của người dùng:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      (submission.userNote != null &&
                              submission.userNote!.isNotEmpty)
                          ? submission.userNote!
                          : "Người dùng không để lại ghi chú.",
                      style: TextStyle(
                        fontStyle: (submission.userNote?.isEmpty ?? true)
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // h/ảnh
                  const Text(
                    "Ảnh minh chứng:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (submission.proofUrls != null &&
                      submission.proofUrls!.isNotEmpty)
                    SizedBox(
                      height: 200, // Chiều cao khung chứa ảnh
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: submission.proofUrls!.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                submission.proofUrls![index],
                                width: 150,
                                height: 200,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Container(
                                    width: 150,
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                },
                                errorBuilder: (ctx, err, stack) => Container(
                                  width: 150,
                                  color: Colors.grey.shade200,
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    const Text(
                      "Không có ảnh đính kèm.",
                      style: TextStyle(
                        color: Colors.red,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // if (isPending)
          //   Padding(
          //     padding: EdgeInsets.only(
          //       bottom: MediaQuery.of(context).padding.bottom + 16,
          //       top: 16,
          //     ),
          //     child: Row(
          //       children: [
          //         Expanded(
          //           child: OutlinedButton.icon(
          //             style: OutlinedButton.styleFrom(
          //               padding: const EdgeInsets.symmetric(vertical: 14),
          //               foregroundColor: Colors.red,
          //               side: const BorderSide(color: Colors.red),
          //               shape: RoundedRectangleBorder(
          //                 borderRadius: BorderRadius.circular(12),
          //               ),
          //             ),
          //             icon: const Icon(Icons.close),
          //             label: const Text(
          //               "Từ chối",
          //               style: TextStyle(
          //                 fontWeight: FontWeight.bold,
          //                 fontSize: 16,
          //               ),
          //             ),
          //             onPressed: () {
          //               // TODO: Gọi hàm từ chối từ ViewModel của bạn
          //               ref.read(adminSubmissionActionProvider.notifier).reject(submission.id);
          //               Navigator.pop(context);
          //             },
          //           ),
          //         ),
          //         const SizedBox(width: 16),
          //         Expanded(
          //           child: ElevatedButton.icon(
          //             style: ElevatedButton.styleFrom(
          //               padding: const EdgeInsets.symmetric(vertical: 14),
          //               backgroundColor: AppColors.primaryGreen,
          //               shape: RoundedRectangleBorder(
          //                 borderRadius: BorderRadius.circular(12),
          //               ),
          //             ),
          //             icon: const Icon(Icons.check, color: Colors.white),
          //             label: const Text(
          //               "Duyệt ngay",
          //               style: TextStyle(
          //                 color: Colors.white,
          //                 fontWeight: FontWeight.bold,
          //                 fontSize: 16,
          //               ),
          //             ),
          //             onPressed: () {
          //               // TODO: Gọi hàm duyệt từ ViewModel của bạn (nhớ cộng điểm cho User)
          //               // ref.read(adminSubmissionActionProvider.notifier).approve(submission.id, submission.userId, submission.pointsReward);
          //               Navigator.pop(context);
          //             },
          //           ),
          //         ),
          //       ],
          //     ),
          //   )
          // else
          //   // Nếu đã duyệt hoặc từ chối rồi thì hiện trạng thái
          //   Padding(
          //     padding: EdgeInsets.only(
          //       bottom: MediaQuery.of(context).padding.bottom + 16,
          //       top: 16,
          //     ),
          //     child: Container(
          //       width: double.infinity,
          //       padding: const EdgeInsets.all(16),
          //       decoration: BoxDecoration(
          //         color: submission.status == 'approved'
          //             ? Colors.green.shade100
          //             : Colors.red.shade100,
          //         borderRadius: BorderRadius.circular(12),
          //       ),
          //       child: Text(
          //         submission.status == 'approved'
          //             ? "Bài này ĐÃ ĐƯỢC DUYỆT"
          //             : "Bài này ĐÃ BỊ TỪ CHỐI",
          //         textAlign: TextAlign.center,
          //         style: TextStyle(
          //           fontWeight: FontWeight.bold,
          //           color: submission.status == 'approved'
          //               ? Colors.green.shade800
          //               : Colors.red.shade800,
          //         ),
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }

  // Hàm phụ để vẽ các dòng thông tin cho gọn code
  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color color = Colors.black87,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey.shade700)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }
}
