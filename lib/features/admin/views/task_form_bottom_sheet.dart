import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/task_model.dart';
import '../../../data/services/cloudinary_service.dart';
import '../viewmodels/admin_task_viewmodel.dart';

class TaskFormBottomSheet extends ConsumerStatefulWidget {
  final TaskModel? taskToEdit; // Nếu null là Thêm mới, nếu có data là Sửa

  const TaskFormBottomSheet({super.key, this.taskToEdit});

  @override
  ConsumerState<TaskFormBottomSheet> createState() =>
      _TaskFormBottomSheetState();
}

class _TaskFormBottomSheetState extends ConsumerState<TaskFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  // Các controller quản lý text input
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _pointsController;
  late TextEditingController _imageUrlController;

  // Theo dõi trạng thái action
  late final actionState = ref.watch(adminTaskActionProvider);
  late final isLoading = actionState.isLoading;

  String _selectedCategory = 'Tái chế'; // Giá trị mặc định
  final List<String> _categories = [
    'Tái chế',
    'Trồng cây',
    'Làm sạch',
    'Tiết kiệm',
    'Khác',
  ];
  File? _selectedImageFile;

  @override
  void initState() {
    super.initState();
    final isEdit = widget.taskToEdit != null;

    // Nếu là chế độ Sửa, điền sẵn dữ liệu cũ vào form
    _titleController = TextEditingController(
      text: isEdit ? widget.taskToEdit!.title : '',
    );
    _descController = TextEditingController(
      text: isEdit ? widget.taskToEdit!.description : '',
    );
    _pointsController = TextEditingController(
      text: isEdit ? widget.taskToEdit!.pointsReward.toString() : '',
    );
    _imageUrlController = TextEditingController(
      text: isEdit ? widget.taskToEdit!.imageUrl : '',
    );

    if (isEdit && _categories.contains(widget.taskToEdit!.category)) {
      _selectedCategory = widget.taskToEdit!.category;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _pointsController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ref.read(imageUploadServiceProvider).pickSingleImage();
    if (file != null) {
      setState(() {
        _selectedImageFile = file;
      });
    }
  }

  // Hàm xử lý khi bấm nút Lưu
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final isEdit = widget.taskToEdit != null;

      if (!isEdit && _selectedImageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vui lòng chọn hình ảnh minh họa!")),
        );
        return;
      }

      // Tạo object TaskModel từ dữ liệu nhập
      final newTask = TaskModel(
        id: widget.taskToEdit?.id ?? '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        pointsReward: int.parse(_pointsController.text.trim()),
        category: _selectedCategory,
        imageUrl: _imageUrlController.text.trim(),
        isActive:
            widget.taskToEdit?.isActive ??
            true, // Giữ nguyên trạng thái nếu đang sửa
      );

      await ref
          .read(adminTaskActionProvider.notifier)
          .saveTask(newTask, _selectedImageFile, isEdit);

      if (mounted && !ref.read(adminTaskActionProvider).hasError) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.taskToEdit == null
                  ? "Thêm thành công!"
                  : "Cập nhật thành công!",
              style: TextStyle(backgroundColor: AppColors.primaryGreen),
            ),
          ),
        );
      } else if (mounted && ref.read(adminTaskActionProvider).hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(adminTaskActionProvider).error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.taskToEdit != null;
    // Lấy kích thước bàn phím để BottomSheet tự động đẩy lên không bị che khuất
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20, // Đẩy lên khi bàn phím xuất hiện
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh kéo để user biết có thể vuốt xuống
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

              Text(
                isEdit ? "Chỉnh sửa nhiệm vụ" : "Thêm nhiệm vụ mới",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Tên nhiệm vụ
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tên nhiệm vụ',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 12),

              // Điểm thưởng và Phân loại
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _pointsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Điểm thưởng',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Nhập điểm';
                        if (int.tryParse(val) == null) return 'Phải là số';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Phân loại',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .map(
                            (cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCategory = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              const Text(
                "Hình ảnh minh họa:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _selectedImageFile != null
                        ? Image.file(
                            _selectedImageFile!,
                            fit: BoxFit.cover,
                          ) // Ảnh vừa chọn
                        : (widget.taskToEdit?.imageUrl != null &&
                              widget.taskToEdit!.imageUrl!.isNotEmpty)
                        ? Image.network(
                            widget.taskToEdit!.imageUrl!,
                            fit: BoxFit.cover,
                          ) // Ảnh cũ
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 40,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Nhấn để tải ảnh lên",
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 4. Mô tả chi tiết
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Hướng dẫn / Mô tả chi tiết',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // 5. Nút Lưu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isEdit ? "CẬP NHẬT" : "TẠO NHIỆM VỤ",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
