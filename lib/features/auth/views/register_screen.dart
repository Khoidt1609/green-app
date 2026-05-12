import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_app/core/providers/auth_providers.dart';

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

  final _emailController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  final _confirmPasswordController =
      TextEditingController();

  final VietnamGeographyApi _geographyApi =
      VietnamGeographyApi();

  List<dynamic> _provinces = [];
  List<dynamic> _districts = [];

  String? _selectedProvince;
  String? _selectedDistrict;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  @override
  void deactivate() {
    FocusScope.of(context).unfocus();
    super.deactivate();
  }

  Future<void> _loadProvinces() async {
    try {
      final provinces =
          await _geographyApi.getProvinces();

      if (!mounted) return;

      setState(() {
        _provinces = provinces;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không tải được tỉnh/thành phố: $e',
          ),
        ),
      );
    }
  }

  Future<void> _loadDistricts(
    String provinceName,
  ) async {
    try {
      final districts =
          await _geographyApi.getDistricts(
        provinceName,
      );

      if (!mounted) return;

      setState(() {
        _districts = districts;
        _selectedDistrict = null;
      });
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không tải được quận/huyện',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> _onRegisterPressed() async {
    final isLoading = ref.read(
      authViewModelProvider.select(
        (state) => state.isLoading,
      ),
    );

    if (isLoading) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

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
          city: _selectedProvince ?? '',
          district: _selectedDistrict ?? '',
        );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
        ),
      );

      return;
    }

    final user =
        FirebaseAuth.instance.currentUser;

    if (user != null) {
      await ref
          .read(authServiceProvider)
          .saveUserSession(user.uid);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đăng ký thành công'),
        backgroundColor:
            AppColors.primaryGreen,
      ),
    );

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRouter.home,
      (route) => false,
    );
  }

  Future<void> _onGooglePressed() async {
    FocusScope.of(context).unfocus();

    final error = await ref
        .read(authViewModelProvider.notifier)
        .loginWithGoogle();

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );

      return;
    }

    final user =
        FirebaseAuth.instance.currentUser;

    if (user != null) {
      await ref
          .read(authServiceProvider)
          .saveUserSession(user.uid);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Đăng nhập Google thành công',
        ),
      ),
    );

    Navigator.of(context)
        .pushNamedAndRemoveUntil(
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
              padding:
                  const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Container(
                  constraints:
                      const BoxConstraints(
                    maxWidth: 440,
                  ),
                  padding:
                      const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color:
                        AppColors.surfaceLight,
                    borderRadius:
                        BorderRadius.circular(
                      24,
                    ),
                    border: Border.all(
                      color:
                          AppColors.borderLight,
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
                        CrossAxisAlignment
                            .stretch,
                    children: [
                      Align(
                        alignment:
                            Alignment.centerLeft,
                        child:
                            TextButton.icon(
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
                          icon: const Icon(
                            Icons.arrow_back,
                            size: 16,
                          ),
                          label:
                              const Text(
                            'Quay lại',
                          ),
                        ),
                      ),

                      Center(
                        child: Container(
                          height: 74,
                          width: 74,
                          decoration:
                              BoxDecoration(
                            borderRadius:
                                BorderRadius
                                    .circular(
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
                          ),
                          child: const Icon(
                            Icons.eco_outlined,
                            color:
                                Colors.white,
                            size: 35,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      const Text(
                        'Tạo tài khoản',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color: AppColors
                              .textPrimary,
                          fontWeight:
                              FontWeight.w800,
                          fontSize: 34,
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      const Text(
                        'Tham gia cộng đồng xanh',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color: AppColors
                              .textSecondary,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      _RegisterField(
                        controller:
                            _displayNameController,
                        hint:
                            'Họ và tên',
                        prefixIcon:
                            Icons.person_outline,
                        autofillHints:
                            const [
                          AutofillHints.name,
                        ],
                        validator:
                            (value) {
                          if (value == null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Vui lòng nhập họ tên';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      _RegisterField(
                        controller:
                            _usernameController,
                        hint:
                            'Tên đăng nhập',
                        prefixIcon: Icons
                            .alternate_email_outlined,
                        validator:
                            (value) {
                          if (value == null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Vui lòng nhập username';
                          }

                          if (value
                                  .trim()
                                  .length <
                              3) {
                            return 'Ít nhất 3 ký tự';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      _RegisterField(
                        controller:
                            _emailController,
                        hint:
                            'Email',
                        prefixIcon:
                            Icons.email_outlined,
                        keyboardType:
                            TextInputType
                                .emailAddress,
                        autofillHints:
                            const [
                          AutofillHints.email,
                        ],
                        validator:
                            (value) {
                          if (value == null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Vui lòng nhập email';
                          }

                          final regex =
                              RegExp(
                            r'^[^@]+@[^@]+\.[^@]+',
                          );

                          if (!regex
                              .hasMatch(
                            value.trim(),
                          )) {
                            return 'Email không hợp lệ';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      _RegisterField(
                        controller:
                            _passwordController,
                        hint:
                            'Mật khẩu',
                        prefixIcon:
                            Icons.lock_outline,
                        obscureText:
                            _obscurePassword,
                        autofillHints:
                            const [
                          AutofillHints
                              .newPassword,
                        ],
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
                          ),
                        ),
                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value
                                  .isEmpty) {
                            return 'Nhập mật khẩu';
                          }

                          if (value
                                  .length <
                              6) {
                            return 'Ít nhất 6 ký tự';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      _RegisterField(
                        controller:
                            _confirmPasswordController,
                        hint:
                            'Xác nhận mật khẩu',
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
                          ),
                        ),
                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value
                                  .isEmpty) {
                            return 'Xác nhận mật khẩu';
                          }

                          if (value !=
                              _passwordController
                                  .text) {
                            return 'Mật khẩu không khớp';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      if (_provinces.isEmpty)
                        const Center(
                          child:
                              CircularProgressIndicator(),
                        )
                      else
                        DropdownButtonFormField<
                            String>(
                          value:
                              _selectedProvince,
                          isExpanded: true,
                          decoration:
                              InputDecoration(
                            labelText:
                                'Tỉnh / Thành phố',
                            prefixIcon:
                                const Icon(
                              Icons
                                  .location_city,
                            ),
                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                14,
                              ),
                            ),
                          ),
                          items: _provinces.map<
                                  DropdownMenuItem<
                                      String>>(
                              (
                            dynamic province,
                          ) {
                            final name =
                                (province?['name'] ??
                                        'Không xác định')
                                    .toString();

                            return DropdownMenuItem<
                                String>(
                              value: name,
                              child:
                                  Text(name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedProvince =
                                  value;

                              _selectedDistrict =
                                  null;

                              _districts = [];
                            });

                            if (value !=
                                null) {
                              _loadDistricts(
                                value,
                              );
                            }
                          },
                          validator:
                              (value) {
                            if (value ==
                                    null ||
                                value
                                    .isEmpty) {
                              return 'Chọn tỉnh/thành';
                            }

                            return null;
                          },
                        ),

                      const SizedBox(
                        height: 12,
                      ),

                      if (_selectedProvince !=
                              null &&
                          _districts.isEmpty)
                        const Padding(
                          padding:
                              EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                          child: Center(
                            child:
                                CircularProgressIndicator(),
                          ),
                        )
                      else
                        DropdownButtonFormField<
                            String>(
                          value:
                              _selectedDistrict,
                          isExpanded: true,
                          decoration:
                              InputDecoration(
                            labelText:
                                'Quận / Huyện',
                            prefixIcon:
                                const Icon(
                              Icons
                                  .map_outlined,
                            ),
                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                14,
                              ),
                            ),
                          ),
                          items: _districts.map<
                                  DropdownMenuItem<
                                      String>>(
                              (
                            dynamic district,
                          ) {
                            final name =
                                (district?['name'] ??
                                        'Không xác định')
                                    .toString();

                            return DropdownMenuItem<
                                String>(
                              value: name,
                              child:
                                  Text(name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedDistrict =
                                  value;
                            });
                          },
                          validator:
                              (value) {
                            if (value ==
                                    null ||
                                value
                                    .isEmpty) {
                              return 'Chọn quận/huyện';
                            }

                            return null;
                          },
                        ),

                      const SizedBox(
                        height: 18,
                      ),

                      FilledButton(
                        onPressed: isLoading
                            ? null
                            : _onRegisterPressed,
                        style:
                            FilledButton.styleFrom(
                          backgroundColor:
                              AppColors
                                  .primaryGreen,
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                        ),
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
                                style:
                                    TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                ),
                              ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

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

                      const SizedBox(
                        height: 14,
                      ),

                      OutlinedButton.icon(
                        onPressed: isLoading
                            ? null
                            : _onGooglePressed,
                        icon: const Icon(
                          Icons
                              .g_mobiledata_rounded,
                        ),
                        label: const Text(
                          'Tiếp tục với Google',
                        ),
                        style:
                            OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children: [
                          const Text(
                            'Đã có tài khoản?',
                          ),
                          TextButton(
                            onPressed:
                                isLoading
                                    ? null
                                    : () {
                                        Navigator.of(
                                          context,
                                        ).pushReplacementNamed(
                                          AppRouter
                                              .login,
                                        );
                                      },
                            child:
                                const Text(
                              'Đăng nhập',
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
    this.autofillHints,
  });

  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final Widget? suffixIcon;
  final List<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      autofillHints: autofillHints,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(
          prefixIcon,
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
        ),
      ),
    );
  }
}