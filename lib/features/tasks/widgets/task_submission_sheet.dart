import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/task_model.dart';
import '../providers/submission_provider.dart';

class TaskSubmissionSheet extends ConsumerStatefulWidget {
  final TaskModel task;
  const TaskSubmissionSheet({super.key, required this.task});

  @override
  ConsumerState<TaskSubmissionSheet> createState() => _TaskSubmissionSheetState();
}

class _TaskSubmissionSheetState extends ConsumerState<TaskSubmissionSheet> {
  final TextEditingController _noteController = TextEditingController();

  //làm trống popup khi bat

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Theo dõi trạng thái từ Riverpod
    final pickedImages = ref.watch(pickedImagesProvider);
    final isLoading = ref.watch(submissionLoadingProvider);
    final submissionService = ref.read(submissionServiceProvider);

    return Container(
      // Padding tự động đẩy lên khi mở bàn phím nhập Ghi chú
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //Tiêu đề
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const Text('Nộp bằng chứng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
            Text(widget.task.title, style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),

            // Mô tả nhiệm vụ
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF2F8F5), borderRadius: BorderRadius.circular(12)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(widget.task.description, style: const TextStyle(color: Colors.black87, fontSize: 13))),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Vùng hiển thị ảnh (Preview)
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryGreen.withOpacity(0.5), width: 1.5, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: pickedImages.isNotEmpty
                  ? ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                itemCount: pickedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 140,
                        height: 160,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(pickedImages[index], fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 4, right: 12,
                        child: GestureDetector(
                          onTap: () => submissionService.removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFE8F9F1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.image_outlined, color: AppColors.primaryGreen),
                  ),
                  const SizedBox(height: 8),
                  const Text('Chọn ảnh bằng chứng', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Text('JPG, PNG – tối đa 10MB', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Hai nút Chụp ảnh & Tải lên
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : () => submissionService.pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Chụp ảnh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8F9F1),
                      foregroundColor: AppColors.primaryGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : () => submissionService.pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.upload_outlined, size: 18),
                    label: const Text('Tải lên'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),

            //Ghi chú
            const SizedBox(height: 20),
            const Text('Ghi chú (tùy chọn)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Mô tả thêm về những gì bạn đã làm...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),

            //Điểm thưởng
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFFE8F9F1), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Phần thưởng khi được duyệt', style: TextStyle(color: Colors.black87)),
                  Text('+${widget.task.pointsReward} XP', style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            // Nút nộp bài
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                // Nút chỉ bấm được khi đã chọn ảnh VÀ không trong trạng thái đang upload
                onPressed: isLoading
                    ? null
                    : () async {
                  bool isSuccess = await ref.read(submissionServiceProvider).submitTask(widget.task, _noteController.text);

                  if (isSuccess) {
                    // Nếu THÀNH CÔNG: Đóng popup và trả về true để màn hình ngoài báo xanh
                    if (context.mounted) Navigator.of(context).pop(true);
                  } else {
                    // Nếu THẤT BẠI: Hiện lỗi NGAY LẬP TỨC trên chính cái Popup này
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lỗi: Không thể nộp bài. Vui lòng kiểm tra lại!'),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating, // Để nó nổi lên trên bàn phím
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: pickedImages.isEmpty ? Colors.grey[300] : AppColors.primaryGreen,
                  foregroundColor: pickedImages.isEmpty ? Colors.grey[500] : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Nộp bằng chứng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}