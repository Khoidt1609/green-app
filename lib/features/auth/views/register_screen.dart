import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../router/app_router.dart';
import '../viewmodels/auth_view_model.dart';
import '../../../core/services/vietnam_geography_api.dart';
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _displayNameController =
      TextEditingController();

  final _usernameController =
      TextEditingController();

  final _cityController =
      TextEditingController();

  final _districtController =
      TextEditingController();

  final _emailController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  final _confirmPasswordController =
      TextEditingController();
  List<dynamic> _provinces = [];
  List<dynamic> _districts = [];
  String? _selectedProvince;
  String? _selectedDistrict;
  final VietnamGeographyApi _geographyApi =VietnamGeographyApi();



  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }
  Future<void>_loadProvinces() async {
    try {
      final provinces = await _geographyApi.fetchProvinces();
      setState(() {
        _provinces = provinces;
      });
    } catch (e) {
      // Handle error, e.g. show a snackbar
    }
  }
  Future<void> _loadDistricts(String provinceCode) async {
    try {
      final districts = await _geographyApi.fetchDistricts(provinceCode);
      setState(() {
        _districts = districts;
      });
    } catch (e) {
      // Handle error, e.g. show a snackbar
    }
  }
  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> _onRegisterPressed() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    // Lấy tên province từ code
    String provinceName = '';
    try {
      final provinceObj = _provinces.firstWhere(
        (p) => p['code'].toString() == _selectedProvince,
      );
      provinceName = provinceObj['name'] ?? _selectedProvince ?? '';
    } catch (e) {
      provinceName = _selectedProvince ?? '';
    }

    final error = await ref
        .read(authViewModelProvider.notifier)
        .register(
          email: _emailController.text.trim(),
          password:
              _passwordController.text.trim(),
          displayName:
              _displayNameController.text.trim(),
          username:
              _usernameController.text.trim(),
          city: provinceName,
          district:
              _selectedDistrict!,
        );

    if (!mounted) {
      return;
    }

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Đăng ký thành công.',
        ),
      ),
    );

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(
      AppRouter.login,
      (route) => false,
    );
  }

  Future<void> _onGooglePressed() async {
    FocusScope.of(context).unfocus();

    final error = await ref
        .read(authViewModelProvider.notifier)
        .loginWithGoogle();

    if (!mounted) {
      return;
    }

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Đăng nhập Google thành công.',
        ),
      ),
    );

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(
      AppRouter.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(
      authViewModelProvider.select(
        (state) => state.isLoading,
      ),
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.9, -0.95),
            radius: 1.4,
            colors: [
              Color(0xFFEAF7F0),
              AppColors.backgroundLight,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 440,
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius:
                        BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.borderLight,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment:
                            Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: isLoading
                              ? null
                              : () {
                                  Navigator.of(
                                    context,
                                  ).pushReplacementNamed(
                                    AppRouter.login,
                                  );
                                },
                          icon: const Icon(
                            Icons.arrow_back,
                            size: 16,
                          ),
                          label:
                              const Text('Quay lại'),
                        ),
                      ),

                      Center(
                        child: Container(
                          height: 74,
                          width: 74,
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(
                              18,
                            ),
                            gradient:
                                const LinearGradient(
                              colors: [
                                AppColors
                                    .primaryGreen,
                                AppColors
                                    .primaryDarkGreen,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors
                                    .primaryGreen
                                    .withOpacity(0.35),
                                blurRadius: 20,
                                offset:
                                    const Offset(
                                  0,
                                  8,
                                ),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.eco_outlined,
                            color: Colors.white,
                            size: 35,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Tạo tài khoản',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color:
                              AppColors.textPrimary,
                          fontWeight:
                              FontWeight.w800,
                          fontSize: 36,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'Tham gia cộng đồng xanh',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color: AppColors
                              .textSecondary,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Họ và tên',
                        style: TextStyle(
                          color: AppColors
                              .textSecondary,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 6),

                      _RegisterField(
                        controller:
                            _displayNameController,
                        hint: 'Nguyễn Văn A',
                        prefixIcon:
                            Icons.person_outline,
                        validator: (value) {
                          if (value == null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Vui lòng nhập họ tên';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Tên đăng nhập',
                        style: TextStyle(
                          color: AppColors
                              .textSecondary,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 6),

                      _RegisterField(
                        controller:
                            _usernameController,
                        hint: 'minhnguyen',
                        prefixIcon: Icons
                            .alternate_email_outlined,
                        validator: (value) {
                          if (value == null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Vui lòng nhập tên đăng nhập';
                          }

                          final username =
                              value.trim();

                          if (username.length <
                              3) {
                            return 'Tên đăng nhập tối thiểu 3 ký tự';
                          }

                          final regex = RegExp(
                            r'^[a-zA-Z0-9_.]+$',
                          );

                          if (!regex.hasMatch(
                            username,
                          )) {
                            return 'Chỉ gồm chữ, số, dấu gạch dưới hoặc chấm';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Email',
                        style: TextStyle(
                          color: AppColors
                              .textSecondary,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 6),

                      _RegisterField(
                        controller:
                            _emailController,
                        hint:
                            'email@example.com',
                        prefixIcon:
                            Icons.email_outlined,
                        keyboardType:
                            TextInputType
                                .emailAddress,
                        validator: (value) {
                          if (value == null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Vui lòng nhập email';
                          }

                          final emailRegex =
                              RegExp(
                            r'^[^@]+@[^@]+\.[^@]+',
                          );

                          if (!emailRegex
                              .hasMatch(
                            value.trim(),
                          )) {
                            return 'Email không hợp lệ';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Mật khẩu',
                        style: TextStyle(
                          color: AppColors
                              .textSecondary,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 6),

                      _RegisterField(
                        controller:
                            _passwordController,
                        hint: '••••••••',
                        prefixIcon:
                            Icons.lock_outline,
                        obscureText:
                            _obscurePassword,
                        suffixIcon:
                            IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword =
                                  !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons
                                      .visibility_outlined
                                : Icons
                                      .visibility_off_outlined,
                            color: AppColors
                                .primaryGreen
                                .withOpacity(0.75),
                          ),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty) {
                            return 'Vui lòng nhập mật khẩu';
                          }

                          if (value.length <
                              6) {
                            return 'Mật khẩu tối thiểu 6 ký tự';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Xác nhận mật khẩu',
                        style: TextStyle(
                          color: AppColors
                              .textSecondary,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 6),

                      _RegisterField(
                        controller:
                            _confirmPasswordController,
                        hint: '••••••••',
                        prefixIcon: Icons
                            .verified_user_outlined,
                        obscureText:
                            _obscureConfirmPassword,
                        suffixIcon:
                            IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons
                                      .visibility_outlined
                                : Icons
                                      .visibility_off_outlined,
                            color: AppColors
                                .primaryGreen
                                .withOpacity(0.75),
                          ),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty) {
                            return 'Vui lòng xác nhận mật khẩu';
                          }

                          if (value !=
                              _passwordController
                                  .text) {
                            return 'Mật khẩu không khớp';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 12),


                      DropdownButtonFormField<String>(
                        value: _selectedProvince,
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
                          labelText: 'Thành phố',
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        validator: (value) => value == null ? 'Vui lòng chọn thành phố' : null,
                      ),

                      const SizedBox(height: 12),


                      DropdownButtonFormField<String>(
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
                          labelText: 'Quận / Huyện',
                          prefixIcon: Icon(Icons.map_outlined),
                        ),
                        validator: (value) => value == null ? 'Vui lòng chọn quận/huyện' : null,
                      ),

                      const SizedBox(height: 18),

                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                          gradient:
                              const LinearGradient(
                            colors: [
                              AppColors
                                  .primaryGreen,
                              AppColors
                                  .primaryDarkGreen,
                            ],
                          ),
                        ),
                        child: FilledButton(
                          style:
                              FilledButton.styleFrom(
                            backgroundColor:
                                Colors.transparent,
                            shadowColor:
                                Colors.transparent,
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                          ),
                          onPressed: isLoading
                              ? null
                              : _onRegisterPressed,
                          child: isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                    color: Colors
                                        .white,
                                  ),
                                )
                              : const Text(
                                  'Tạo tài khoản',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight:
                                        FontWeight
                                            .w700,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: AppColors
                                  .borderLight,
                            ),
                          ),
                          const Padding(
                            padding:
                                EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            child: Text(
                              'hoặc',
                              style: TextStyle(
                                color: AppColors
                                    .textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: AppColors
                                  .borderLight,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      OutlinedButton.icon(
                        onPressed: isLoading
                            ? null
                            : _onGooglePressed,
                        style:
                            OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          side: BorderSide(
                            color: AppColors
                                .primaryGreen
                                .withOpacity(0.35),
                          ),
                          foregroundColor:
                              AppColors
                                  .primaryDarkGreen,
                        ),
                        icon: const Icon(
                          Icons.g_mobiledata_rounded,
                        ),
                        label: const Text(
                          'Tiếp tục với Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children: [
                          const Text(
                            'Đã có tài khoản? ',
                            style: TextStyle(
                              color: AppColors
                                  .textSecondary,
                            ),
                          ),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    Navigator.of(
                                      context,
                                    ).pushReplacementNamed(
                                      AppRouter
                                          .login,
                                    );
                                  },
                            child: const Text(
                              'Đăng nhập ngay',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterField extends StatelessWidget {
  const _RegisterField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: AppColors.primaryGreen
              .withOpacity(0.75),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.borderLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primaryGreen,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}