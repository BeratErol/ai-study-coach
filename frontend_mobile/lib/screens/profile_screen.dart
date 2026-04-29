import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storage = const FlutterSecureStorage();
  String _userName = 'Yükleniyor...';
  String _userEmail = 'Yükleniyor...';
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
    setState(() {
      _isDarkMode = value;
    });
  }

  Future<void> _loadUserProfile() async {
    String? token = await _storage.read(key: 'jwt_token');
    if (token != null && JwtDecoder.isExpired(token) == false) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      
      String? name = decodedToken['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'] ?? decodedToken['name'];
      String? email = decodedToken['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'] ?? decodedToken['email'];
      
      setState(() {
        _userName = name ?? 'İsimsiz Kullanıcı';
        _userEmail = email ?? 'E-posta bulunamadı';
      });
    }
  }

  void _logout() async {
    await _storage.delete(key: 'jwt_token');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Profilim', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              // Profile Avatar
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blueAccent, width: 3),
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_rounded,
                    size: 64,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Name and Email
              Text(
                _userName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _userEmail,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 48),

              // Settings Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.flag_rounded, color: Colors.orange),
                      ),
                      title: const Text('Hedef Sınav', style: TextStyle(fontWeight: FontWeight.w600)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('YKS 2026', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                        ],
                      ),
                      onTap: () {
                        // TODO: Implement Goal Setting
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Hedef sınav belirleme yakında eklenecek!')),
                        );
                      },
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    SwitchListTile(
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.dark_mode_rounded, color: Colors.blueGrey),
                      ),
                      title: const Text('Karanlık Mod', style: TextStyle(fontWeight: FontWeight.w600)),
                      value: _isDarkMode,
                      onChanged: _toggleDarkMode,
                      activeColor: Colors.blueAccent,
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.logout_rounded, color: Colors.red),
                      ),
                      title: const Text('Çıkış Yap', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                      onTap: _logout,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
