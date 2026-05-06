import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_theme.dart';
import '../main.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _storage = const FlutterSecureStorage();
  String _userName  = 'Yükleniyor...';
  String _userEmail = 'Yükleniyor...';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null && !JwtDecoder.isExpired(token)) {
      final payload = JwtDecoder.decode(token);
      final name  = payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name']
              as String? ??
          payload['name'] as String? ??
          'İsimsiz Kullanıcı';
      final email = payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress']
              as String? ??
          payload['email'] as String? ??
          'E-posta bulunamadı';
      if (mounted) setState(() { _userName = name; _userEmail = email; });
    }
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    ref.read(themeModeProvider.notifier).state =
        value ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> _logout() async {
    await _storage.delete(key: 'jwt_token');
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Profilim')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded,
                    size: 56, color: Colors.white),
              ),
              const SizedBox(height: 16),

              Text(
                _userName,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                _userEmail,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 36),

              // Settings
              Card(
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.edit_calendar_rounded,
                      iconColor: AppColors.primary,
                      title: 'Çalışma Programını Güncelle',
                      subtitle: 'Hedef sınav, çalışma saatleri ve dersler',
                      onTap: () => context.go('/onboarding'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryO10,
                          borderRadius: AppRadius.sm,
                        ),
                        child: const Icon(Icons.dark_mode_rounded,
                            color: AppColors.primary),
                      ),
                      title: const Text('Karanlık Mod',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      value: isDark,
                      onChanged: _toggleDarkMode,
                      activeThumbColor: AppColors.primary,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      iconColor: AppColors.error,
                      titleColor: AppColors.error,
                      title: 'Çıkış Yap',
                      onTap: _logout,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // App version
              const Text('AI Study Coach v1.0.0',
                  style: TextStyle(
                      color: AppColors.textHint, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: AppRadius.sm,
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: titleColor),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary))
          : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
      onTap: onTap,
    );
  }
}
