import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../providers/chatbot_provider.dart';
import '../providers/gelisimim_provider.dart';
import '../providers/study_plan_provider.dart';
import '../screens/denemeler_screen.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import '../services/user_prefs_service.dart';
import '../core/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool  _obscure    = true;
  bool  _loading        = false;
  bool  _messageShown   = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_messageShown) {
      _messageShown = true;
      final extra = GoRouterState.of(context).extra as String?;
      if (extra != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showSuccessSnack(extra);
        });
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final response = await ApiService().login(
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );
      if (response != null && response.statusCode == 200) {
        final token = response.data['token'] as String?;
        if (token != null) {
          await const FlutterSecureStorage()
              .write(key: 'jwt_token', value: token);
        }
        // Reset user-specific local providers so new user sees clean state
        ref.invalidate(completedTaskIdsProvider);
        ref.invalidate(manualTasksProvider);
        ref.invalidate(onboardingDataProvider);
        ref.invalidate(studyPlanProvider);
        ref.invalidate(examGoalProvider);
        ref.invalidate(examCountdownProvider);
        ref.invalidate(quickNotesProvider);
        ref.invalidate(examsProvider);
        ref.invalidate(xpInfoProvider);
        ref.invalidate(gelisimimStatsProvider('all'));
        ref.invalidate(gelisimimStatsProvider('today'));
        ref.invalidate(lessonDistributionProvider('all'));
        ref.invalidate(questionSubjectsProvider);
        ref.invalidate(topicAssignmentsProvider);
        ref.invalidate(chatbotProvider);
        ref.read(restDaysProvider.notifier).state = 0;
        if (!mounted) return;
        await _checkOnboardingStatus();
      }
    } catch (e) {
      if (!mounted) return;
      String msg = 'Bağlantı hatası. Sunucuya ulaşılamıyor.';
      try {
        final errData = (e as dynamic).response?.data;
        if (errData is Map && errData['error'] != null) {
          msg = errData['error'] as String;
        }
      } catch (_) {}
      _showSnack(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkOnboardingStatus() async {
    final userId = await TokenService.getUserId() ?? '';

    // Backend'den profil kontrolü
    bool? profileExists;
    try {
      final response = await ApiService().dio.get('/UserProfile');
      if (response.statusCode == 200 && response.data != null) {
        profileExists = true;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        profileExists = false; // Açıkça profil yok → onboarding
      }
      // Diğer tüm DioException (bağlantı hatası, timeout, 500 vb.) → profileExists = null
    } catch (_) {
      // Beklenmedik hata → profileExists = null
    }

    if (profileExists == true) {
      // Profil var, onboarding tamamlandı
      await UserPrefsService.setOnboardingCompleted(userId, true);
      if (mounted) context.go('/dashboard');
    } else if (profileExists == false) {
      // Açıkça 404 → profil yok, local'e bak
      final completed = await UserPrefsService.isOnboardingCompleted(userId);
      if (mounted) context.go(completed ? '/dashboard' : '/onboarding');
    } else {
      // Ağ/sunucu hatası → local'e bak; local'de de yoksa dashboard'a gönder
      // (giriş başarılıysa kullanıcı zaten kayıtlı, onboarding'e atmak yanlış)
      final completed = await UserPrefsService.isOnboardingCompleted(userId);
      if (mounted) context.go(completed ? '/dashboard' : '/dashboard');
    }
  }

  void _showSuccessSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient top section ────────────────────────────────────────
          Container(
            height: size.height * 0.42,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3730A3), AppColors.primary, Color(0xFF6D28D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ── White card scrollable ───────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Logo + title in gradient area
                  SizedBox(
                    height: size.height * 0.32,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: AppRadius.xl,
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1.5),
                          ),
                          child: const Icon(Icons.school_rounded,
                              size: 40, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'AI Study Coach',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Koçun seni bekliyor',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // White card
                  Container(
                    constraints:
                        BoxConstraints(minHeight: size.height * 0.65),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32)),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Giriş Yap',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          const Text('Hesabınla devam et',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14)),
                          const SizedBox(height: 28),

                          // Email
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'E-posta',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (v) => (v == null || !v.contains('@'))
                                ? 'Geçerli bir e-posta girin'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            onFieldSubmitted: (_) => _login(),
                            decoration: InputDecoration(
                              labelText: 'Şifre',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Şifre boş olamaz'
                                : null,
                          ),
                          const SizedBox(height: 32),

                          // Button
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                shape: const RoundedRectangleBorder(
                                    borderRadius: AppRadius.md),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    )
                                  : const Text('Giriş Yap',
                                      style: TextStyle(fontSize: 16)),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Register link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Hesabın yok mu?',
                                  style: TextStyle(
                                      color: AppColors.textSecondary)),
                              TextButton(
                                onPressed: () => context.go('/register'),
                                style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8)),
                                child: const Text('Kayıt Ol',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
