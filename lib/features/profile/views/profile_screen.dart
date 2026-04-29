import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/services/auth_service.dart';
import '../../../router/app_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const List<String> _avatarGallery = [
    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1547425260-76bcadfb4f2c?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1521119989659-a83eee488004?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=400&h=400&fit=crop',
  ];

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();

  bool _isSaving = false;
  bool _isLoading = true;
  int _currentTab = 0;

  String? _avatarUrl;
  int _totalPoints = 0;
  int _weeklyPoints = 0;
  int _monthlyPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    final data = await authService.getCurrentUserProfile();

    if (!mounted) {
      return;
    }

    final fallbackUsername = user?.email?.split('@').first ?? 'user';

    _nameController.text = (data?['fullName'] as String?)?.trim() ?? '';
    _usernameController.text =
        (data?['username'] as String?)?.trim().isNotEmpty == true
        ? (data!['username'] as String).trim()
        : fallbackUsername;
    _cityController.text = (data?['city'] as String?)?.trim() ?? '';
    _districtController.text = (data?['district'] as String?)?.trim() ?? '';

    _avatarUrl = (data?['avatarUrl'] as String?)?.trim();
    _totalPoints = (data?['totalPoints'] as num?)?.toInt() ?? 0;
    _weeklyPoints = (data?['weeklyPoints'] as num?)?.toInt() ?? 0;
    _monthlyPoints = (data?['monthlyPoints'] as num?)?.toInt() ?? 0;

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveProfile({bool showSuccess = true}) async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập họ và tên.')));
      return;
    }

    if (_usernameController.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên đăng nhập tối thiểu 3 ký tự.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final authService = ref.read(authServiceProvider);

    try {
      await authService.saveCurrentUserProfile(
        fullName: _nameController.text,
        username: _usernameController.text,
        city: _cityController.text,
        district: _districtController.text,
        avatarUrl: _avatarUrl,
      );

      if (!mounted) {
        return;
      }

      if (showSuccess) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã cập nhật hồ sơ.')));
      }
    } on AuthException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _editField({
    required String title,
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final newValue = await showDialog<String>(
      context: context,
      builder: (context) {
        return _EditFieldDialog(
          title: title,
          initialValue: controller.text,
          hint: hint,
          keyboardType: keyboardType,
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (newValue == null) {
      return;
    }

    setState(() {
      controller.text = newValue.trim();
    });
  }

  Future<void> _pickAvatarFromGallery() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn avatar mẫu',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: GridView.builder(
                    itemCount: _avatarGallery.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemBuilder: (context, index) {
                      final url = _avatarGallery[index];
                      return InkWell(
                        onTap: () => Navigator.of(context).pop(url),
                        borderRadius: BorderRadius.circular(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(url, fit: BoxFit.cover),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _avatarUrl = selected;
    });

    await _saveProfile(showSuccess: false);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã chọn avatar mẫu.')));
  }

  Future<void> _signOutAndGoToLogin() async {
    try {
      await ref.read(authServiceProvider).signOut();
      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamedAndRemoveUntil(AppRouter.login, (route) => false);
    } on AuthException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _onTapBottomNav(int index) {
    if (_currentTab == index) {
      return;
    }

    switch (index) {
      case 0:
        setState(() {
          _currentTab = index;
        });
        Navigator.of(context).pushReplacementNamed(AppRouter.home);
        break;
      case 1:
        break;
      case 2:
        setState(() {
          _currentTab = index;
        });
        Navigator.of(context).pushReplacementNamed(AppRouter.tasks);
        break;
      case 3:
        break;
      case 4:
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(authServiceProvider).currentUser;

    final displayUsername = _usernameController.text.trim().isNotEmpty
        ? _usernameController.text.trim()
        : (user?.email?.split('@').first ?? 'user');

    final displayName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : displayUsername;
    final avatarInitial = displayUsername.isNotEmpty
        ? displayUsername[0].toUpperCase()
        : 'U';

    final weeklyProgress = ((_weeklyPoints / 600).clamp(0, 1)).toDouble();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: _signOutAndGoToLogin,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.2),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 68,
                              backgroundColor: AppColors.primaryGreen
                                  .withValues(alpha: 0.16),
                              child: Text(
                                avatarInitial,
                                style: const TextStyle(
                                  color: AppColors.primaryDarkGreen,
                                  fontSize: 44,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: InkWell(
                                onTap: _pickAvatarFromGallery,
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colorScheme.primary,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _pickAvatarFromGallery,
                              icon: const Icon(Icons.collections_outlined),
                              label: const Text('Avatar mẫu'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@$displayUsername',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _signOutAndGoToLogin,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.error,
                            ),
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Đăng xuất'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryGreen,
                          AppColors.primaryDarkGreen,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Điểm của bạn',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$_totalPoints điểm',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _ScoreChip(
                                label: 'Tuần',
                                value: '$_weeklyPoints/600',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ScoreChip(
                                label: 'Tháng',
                                value: '$_monthlyPoints/2000',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: weeklyProgress,
                            minHeight: 8,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.3,
                            ),
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Column(
                      children: [
                        _ProfileInfoRow(
                          label: 'Họ và tên',
                          value: _nameController.text,
                          hint: 'Chưa cập nhật',
                          onEdit: () => _editField(
                            title: 'Họ và tên',
                            controller: _nameController,
                            hint: 'Nguyễn Văn A',
                          ),
                        ),
                        _ProfileInfoRow(
                          label: 'Tên đăng nhập',
                          value: _usernameController.text,
                          hint: 'Chưa cập nhật',
                          onEdit: () => _editField(
                            title: 'Tên đăng nhập',
                            controller: _usernameController,
                            hint: 'minhnguyen',
                          ),
                        ),
                        _ProfileInfoRow(
                          label: 'Tỉnh/Thành phố',
                          value: _cityController.text,
                          hint: 'Chưa cập nhật',
                          onEdit: () => _editField(
                            title: 'Tỉnh/Thành phố',
                            controller: _cityController,
                            hint: 'TP. Hồ Chí Minh',
                          ),
                        ),
                        _ProfileInfoRow(
                          label: 'Quận/Huyện',
                          value: _districtController.text,
                          hint: 'Chưa cập nhật',
                          onEdit: () => _editField(
                            title: 'Quận/Huyện',
                            controller: _districtController,
                            hint: 'Bình Thạnh',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _saveProfile,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_isSaving ? 'Đang lưu...' : 'Lưu thay đổi'),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentTab,
          onTap: _onTapBottomNav,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.primaryGreen,
          unselectedItemColor: AppColors.textSecondary,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              label: 'Rank',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.task_alt_outlined),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              label: 'Store',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.label,
    required this.value,
    required this.hint,
    required this.onEdit,
  });

  final String label;
  final String value;
  final String hint;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.trim().isEmpty ? hint : value.trim(),
                  style: TextStyle(
                    color: value.trim().isEmpty
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Sửa'),
          ),
        ],
      ),
    );
  }
}

class _EditFieldDialog extends StatefulWidget {
  const _EditFieldDialog({
    required this.title,
    required this.initialValue,
    required this.hint,
    required this.keyboardType,
  });

  final String title;
  final String initialValue;
  final String? hint;
  final TextInputType keyboardType;

  @override
  State<_EditFieldDialog> createState() => _EditFieldDialogState();
}

class _EditFieldDialogState extends State<_EditFieldDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Sửa ${widget.title}'),
      content: TextField(
        controller: _controller,
        keyboardType: widget.keyboardType,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        autocorrect: true,
        enableSuggestions: true,
        smartDashesType: SmartDashesType.disabled,
        smartQuotesType: SmartQuotesType.disabled,
        decoration: InputDecoration(hintText: widget.hint ?? ''),
        autofocus: true,
        onSubmitted: (_) => Navigator.of(context).pop(_controller.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white.withValues(alpha: 0.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
