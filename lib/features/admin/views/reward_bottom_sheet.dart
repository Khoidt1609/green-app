import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/reward_model.dart';
import '../viewmodels/admin_reward_viewmodel.dart';

class RewardFormBottomSheet extends ConsumerStatefulWidget {
  final RewardModel? rewardToEdit;

  const RewardFormBottomSheet({super.key, this.rewardToEdit});

  @override
  ConsumerState<RewardFormBottomSheet> createState() =>
      _RewardFormBottomSheetState();
}

class _RewardFormBottomSheetState extends ConsumerState<RewardFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _pointCostController;
  late TextEditingController _valueVNDController;
  late TextEditingController _imageUrlController;

  String _selectedType = 'cash'; // 'cash' hoặc 'voucher'

  @override
  void initState() {
    super.initState();
    final isEdit = widget.rewardToEdit != null;

    _nameController = TextEditingController(
      text: isEdit ? widget.rewardToEdit!.name : '',
    );
    _descController = TextEditingController(
      text: isEdit ? widget.rewardToEdit!.description : '',
    );
    _pointCostController = TextEditingController(
      text: isEdit ? widget.rewardToEdit!.pointCost.toString() : '',
    );
    _valueVNDController = TextEditingController(
      text: isEdit ? widget.rewardToEdit!.valueVND.toString() : '',
    );
    _imageUrlController = TextEditingController(
      text: isEdit ? (widget.rewardToEdit!.imageUrl ?? '') : '',
    );

    if (isEdit) {
      _selectedType = widget.rewardToEdit!.type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _pointCostController.dispose();
    _valueVNDController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final newReward = RewardModel(
        id: widget.rewardToEdit?.id ?? '',
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        pointCost: int.parse(_pointCostController.text.trim()),
        valueVND: int.parse(_valueVNDController.text.trim()),
        type: _selectedType,
        imageUrl: _imageUrlController.text.trim(),
        isActive: widget.rewardToEdit?.isActive ?? true,
      );

      final actionNotifier = ref.read(adminRewardActionProvider.notifier);

      if (widget.rewardToEdit == null) {
        await actionNotifier.add(newReward);
      } else {
        await actionNotifier.update(newReward);
      }

      if (mounted && !ref.read(adminRewardActionProvider).hasError) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.rewardToEdit == null
                  ? "Thêm thành công!"
                  : "Cập nhật thành công!",
            ),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.rewardToEdit != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isLoading = ref.watch(adminRewardActionProvider).isLoading;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
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
                isEdit ? "Chỉnh sửa phần thưởng" : "Thêm phần thưởng mới",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên gói (VD: Rút 50k về MB Bank)',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pointCostController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Điểm cần đổi',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val!.isEmpty ? 'Nhập điểm' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _valueVNDController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Giá trị VNĐ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val!.isEmpty ? 'Nhập VNĐ' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Loại phần thưởng',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'cash',
                    child: Text('Tiền mặt (Chuyển khoản)'),
                  ),
                  DropdownMenuItem(
                    value: 'voucher',
                    child: Text('Voucher / Thẻ cào'),
                  ),
                ],
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Link ảnh (URL)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Mô tả chi tiết',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

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
                          isEdit ? "CẬP NHẬT" : "TẠO GÓI THƯỞNG",
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
