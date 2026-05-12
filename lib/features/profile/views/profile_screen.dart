import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/services/auth_service.dart';
import '../../../router/app_router.dart';
import '../../../core/services/vietnam_geography_api.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _role = 'user';
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

  final VietnamGeographyApi _geoApi = VietnamGeographyApi();
  List<dynamic> _provinces =[];
  List<dynamic> _districts =[];
  String? _selectedProvince;
  String? _selectedDistrict;
  bool _isSaving = false;
  bool _isLoading = true;

  int _currentTab = 4;

  String? _avatarUrl;

  int _totalPoints = 0;
  int _weeklyPoints = 0;
  int _monthlyPoints = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadProvinces();
    await _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final authService = ref.read(authServiceProvider);

    final user = authService.currentUser;

    final data = await authService.getCurrentUserProfile();

    if (!mounted) {
      return;
    }

    setState(() {
      _role = data?['role']?.toString() ?? 'user';
    });

    final fallbackUsername = user?.email?.split('@').first ?? 'user';

    _nameController.text =
        (data?['displayName'] as String?)?.trim() ??
        (data?['fullName'] as String?)?.trim() ??
        '';

    _usernameController.text =
        (data?['username'] as String?)?.trim().isNotEmpty == true
        ? (data!['username'] as String).trim()
        : fallbackUsername;


final address = data?['address'] as Map<String, dynamic>? ?? {};

    final cityFromDb = (address['city'] as String?)?.trim();
    
    // Map province name hoặc code sang province code
    if (cityFromDb != null && cityFromDb.isNotEmpty) {
      // Kiểm xem có phải code không
      final isCode = _provinces.any((p) => p['code'].toString() == cityFromDb);
      if (isCode) {
        _selectedProvince = cityFromDb;
      } else {
        // Tìm code từ tên province (database lưu tên)
        final province = _provinces.firstWhere(
          (p) => p['name'].toString().toLowerCase() == cityFromDb.toLowerCase(),
          orElse: () => null,
        );
        _selectedProvince = province != null ? province['code'].toString() : null;
      }
    } else {
      // Database lưu empty → set null
      _selectedProvince = null;
    }
    
    _selectedDistrict = (address['district'] as String?)?.trim();
    if (_selectedProvince != null){
      await _loadDistricts(_selectedProvince!);
    }

    _avatarUrl = (data?['avatarUrl'] as String?)?.trim();

    _totalPoints = (data?['totalPoints'] as num?)?.toInt() ?? 0;

    _weeklyPoints = (data?['weekPoints'] as num?)?.toInt() ?? 0;

    _monthlyPoints = (data?['monthPoints'] as num?)?.toInt() ?? 0;

    setState(() {
      _isLoading = false;
    });
  }
  Future<void> _loadProvinces() async {
    try {
      final provinces = await _geoApi.fetchProvinces();
      setState(() {
        _provinces = provinces;
      });
    } catch (e) {
      // Handle error
    }
  }
  Future<void> _loadDistricts(String provinceId) async {
    try {
      final districts = await _geoApi.fetchDistricts(provinceId);
      setState(() {
        _districts = districts;
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _saveProfile({bool showSuccess = true}) async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập họ tên.')));
      return;
    }

    if (_usernameController.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên đăng nhập tối thiểu 3 ký tự.')),
      );
      return;
    }

    // Kiểm tra province/district
    if (_selectedProvince == null || _selectedProvince!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn tỉnh/thành phố.')),
      );
      return;
    }

    if (_selectedDistrict == null || _selectedDistrict!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn quận/huyện.')),
      );
      return;
    }

    // Kiểm tra province/district có hợp lệ không
    final provinceExists = _provinces.any((p) => p['code'].toString() == _selectedProvince);
    if (!provinceExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tỉnh/thành phố không hợp lệ. Vui lòng chọn lại.')),
      );
      return;
    }

    final districtExists = _districts.any((d) => d['name'].toString() == _selectedDistrict);
    if (!districtExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quận/huyện không hợp lệ. Vui lòng chọn lại.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final authService = ref.read(authServiceProvider);

    try {
      // Debug: In ra để xem giá trị
      print('DEBUG: _selectedProvince = $_selectedProvince');
      print('DEBUG: _selectedDistrict = $_selectedDistrict');
      print('DEBUG: _provinces length = ${_provinces.length}');
      if (_provinces.isNotEmpty) {
        print('DEBUG: First province = ${_provinces.first}');
      }

      // Lấy tên province từ code
      String provinceName = '';
      try {
        final selectedProvinceObj = _provinces.firstWhere(
          (p) => p['code'].toString() == _selectedProvince,
        );
        provinceName = selectedProvinceObj['name'] ?? '';
        print('DEBUG: Found province name = $provinceName');
      } catch (e) {
        print('DEBUG: Error finding province: $e');
        provinceName = _selectedProvince ?? '';
      }

      print('DEBUG: Saving with provinceName = $provinceName');

      await authService.updateProfile(
        displayName: _nameController.text,
        username: _usernameController.text,
        city: provinceName,
        district: _selectedDistrict!,
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

    if (!mounted || newValue == null) {
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
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              itemCount: _avatarGallery.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final url = _avatarGallery[index];

                return InkWell(
                  onTap: () => Navigator.of(context).pop(url),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(url, fit: BoxFit.cover),
                  ),
                );
              },
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
    ).showSnackBar(const SnackBar(content: Text('Đã cập nhật avatar.')));
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
        Navigator.of(context).pushReplacementNamed(AppRouter.home);
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRouter.leaderboard);
        break;

      case 2:
        Navigator.of(context).pushReplacementNamed(AppRouter.tasks);
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed(AppRouter.greenMap);
        break;

      case 4:
        Navigator.of(context).pushReplacementNamed(AppRouter.rewardWallet);
        break;

      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: _signOutAndGoToLogin,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.primaryGreen.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 68,
                              backgroundColor: AppColors.primaryGreen
                                  .withOpacity(0.16),
                              backgroundImage:
                                  _avatarUrl != null && _avatarUrl!.isNotEmpty
                                  ? NetworkImage(_avatarUrl!)
                                  : null,
                              child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                                  ? Text(
                                      avatarInitial,
                                      style: const TextStyle(
                                        color: AppColors.primaryDarkGreen,
                                        fontSize: 44,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: InkWell(
                                onTap: _pickAvatarFromGallery,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primaryGreen,
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

                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '@$displayUsername',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 12),

                        OutlinedButton.icon(
                          onPressed: _pickAvatarFromGallery,
                          icon: const Icon(Icons.collections_outlined),
                          label: const Text('Avatar mẫu'),
                        ),

                        const SizedBox(height: 12),

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
                        const SizedBox(height: 12),
                        if (_role == 'admin')
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.of(
                                  context,
                                ).pushNamed(AppRouter.admin);
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primaryDarkGreen,
                              ),
                              icon: const Icon(Icons.admin_panel_settings),
                              label: const Text('Admin'),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
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

                        const SizedBox(height: 8),

                        Text(
                          '$_totalPoints điểm',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 12),

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

                        const SizedBox(height: 12),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: weeklyProgress,
                            minHeight: 8,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
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
                          ),
                        ),

                        _ProfileInfoRow(
                          label: 'Tên đăng nhập',
                          value: _usernameController.text,
                          hint: 'Chưa cập nhật',
                          onEdit: () => _editField(
                            title: 'Tên đăng nhập',
                            controller: _usernameController,
                          ),
                        ),

                        // MỚI
const SizedBox(height: 12),
const Text(
  'Tỉnh / Thành phố',
  style: TextStyle(
    color: AppColors.textSecondary,
    fontSize: 13,
  ),
),
const SizedBox(height: 6),
_provinces.isEmpty
    ? Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'Đang tải tỉnh/thành phố...',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      )
    : DropdownButtonFormField<String>(
        value: _selectedProvince != null && _provinces.any((p) => p['code'].toString() == _selectedProvince)
            ? _selectedProvince
            : null,
        items: _provinces.map<DropdownMenuItem<String>>((province) {
          return DropdownMenuItem<String>(
            value: province['code'].toString(),
            child: Text(province['name']),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedProvince = value;
            _selectedDistrict = null;
            _districts = [];
          });
          if (value != null) {
            _loadDistricts(value);
          }
        },
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.location_city),
          border: OutlineInputBorder(),
        ),
        validator: (value) => value == null ? 'Vui lòng chọn thành phố' : null,
      ),

const SizedBox(height: 12),
const Text(
  'Quận / Huyện',
  style: TextStyle(
    color: AppColors.textSecondary,
    fontSize: 13,
  ),
),
const SizedBox(height: 6),
_selectedProvince == null || _selectedProvince!.isEmpty
    ? Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'Chọn tỉnh/thành phố trước',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      )
    : _districts.isEmpty
        ? Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderLight),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Đang tải quận/huyện...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        : DropdownButtonFormField<String>(
            value: _selectedDistrict,
            items: _districts.map<DropdownMenuItem<String>>((district) {
              return DropdownMenuItem<String>(
                value: district['name'],
                child: Text(district['name']),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedDistrict = value;
              });
            },
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.map_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null ? 'Vui lòng chọn quận/huyện' : null,
          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          onPressed: _isSaving ? null : _saveProfile,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _isSaving ? 'Đang lưu...' : 'Lưu thay đổi',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: _onTapBottomNav,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textSecondary,
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
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Map'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      subtitle: Text(
        value.trim().isEmpty ? hint : value.trim(),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: value.trim().isEmpty
              ? AppColors.textSecondary
              : AppColors.textPrimary,
        ),
      ),
      trailing: IconButton(
        onPressed: onEdit,
        icon: const Icon(Icons.edit_outlined),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 4),
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
        decoration: InputDecoration(hintText: widget.hint),
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