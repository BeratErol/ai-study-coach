import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/api_service.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'task_create_screen.dart';
import 'lesson_detail_screen.dart';
import 'pomodoro_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _storage = const FlutterSecureStorage();
  String _userName = 'Öğrenci';
  List<dynamic> _lessons = [];
  bool _isLoadingLessons = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _fetchLessons();
  }

  Future<void> _fetchLessons() async {
    setState(() {
      _isLoadingLessons = true;
    });
    try {
      final apiService = ApiService();
      final response = await apiService.dio.get('/Lesson');
      if (response.statusCode == 200) {
        setState(() {
          _lessons = response.data;
        });
      }
    } catch (e) {
      // Print error or show snackbar
      print('Failed to fetch lessons: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLessons = false;
        });
      }
    }
  }

  Future<void> _loadUserName() async {
    String? token = await _storage.read(key: 'jwt_token');
    if (token != null && JwtDecoder.isExpired(token) == false) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      // 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name' is typically the key for ClaimTypes.Name in .NET JWT
      String? name = decodedToken['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'] ?? decodedToken['name'];
      if (name != null && name.isNotEmpty) {
        setState(() {
          _userName = name;
        });
      }
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
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Merhaba, $_userName 👋',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bugün hedeflerine ulaşmak için harika bir gün!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.timer,
                          title: 'Çalışma',
                          value: '120 dk',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.check_circle_outline,
                          title: 'Görev',
                          value: '3',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Tasks Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bugünkü Çalışma Programım',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _isLoadingLessons
                          ? const Center(child: CircularProgressIndicator())
                          : RefreshIndicator(
                              onRefresh: _fetchLessons,
                              child: _lessons.isEmpty
                                  ? ListView(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      children: [
                                        // Empty State Card
                                        Container(
                                          margin: const EdgeInsets.only(top: 10),
                                          padding: const EdgeInsets.all(32),
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
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.event_busy_rounded,
                                                size: 64,
                                                color: Colors.blueAccent.withOpacity(0.5),
                                              ),
                                              const SizedBox(height: 16),
                                              const Text(
                                                'Bugün için planlanmış bir çalışmanız yok.',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Yeni bir çalışma planı ekleyerek güne başlayabilirsiniz.',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  : ListView.builder(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      itemCount: _lessons.length,
                                      itemBuilder: (context, index) {
                                        final lesson = _lessons[index];
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).cardColor,
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.02),
                                                blurRadius: 5,
                                                offset: const Offset(0, 2),
                                              )
                                            ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(12),
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) => LessonDetailScreen(lesson: lesson),
                                                  ),
                                                );
                                              },
                                              child: ListTile(
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                                leading: Container(
                                                  width: 12,
                                                  height: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: _parseColor(lesson['colorCode'] ?? '#3498db'),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                ),
                                                title: Text(
                                                  lesson['name'] ?? 'İsimsiz Ders',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                trailing: IconButton(
                                                  icon: const Icon(Icons.play_circle_fill, color: Colors.blueAccent, size: 32),
                                                  onPressed: () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (context) => PomodoroScreen(
                                                          lessonId: lesson['id'],
                                                          lessonName: lesson['name'],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const TaskCreateScreen(),
            ),
          ).then((_) => _fetchLessons());
        },
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hexCode) {
    hexCode = hexCode.replaceAll('#', '');
    if (hexCode.length == 6) {
      hexCode = 'FF$hexCode';
    }
    try {
      return Color(int.parse(hexCode, radix: 16));
    } catch (e) {
      return Colors.blueAccent;
    }
  }
}
