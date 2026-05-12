import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') rethrow;
    }
  }

  runApp(const ProviderScope(child: GreenStepApp()));
}

// Chuyển thành ConsumerStatefulWidget để kiểm tra session khi mở app
class GreenStepApp extends ConsumerStatefulWidget {
  const GreenStepApp({super.key});

  @override
  ConsumerState<GreenStepApp> createState() => _GreenStepAppState();
}

class _GreenStepAppState extends ConsumerState<GreenStepApp> {
  String? _savedUid;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      final storedUid = prefs.getString('user_uid')?.trim();
      final currentUid = FirebaseAuth.instance.currentUser?.uid.trim();

      final hasValidSession = storedUid != null &&
          storedUid.isNotEmpty &&
          currentUid != null &&
          currentUid.isNotEmpty &&
          storedUid == currentUid;

      _savedUid = hasValidSession ? currentUid : null;
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Nếu đang kiểm tra UID thì hiện màn hình chờ, tránh lỗi Null initialRoute
    if (_isChecking) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      title: 'GreenStep',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi'), Locale('en')],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      onGenerateRoute: AppRouter.onGenerateRoute,
      // Nếu có UID trong máy thì vào thẳng Home, không thì vào Onboarding
      initialRoute: _savedUid != null ? AppRouter.home : AppRouter.onboarding,
    );
  }
}