import 'package:flutter/material.dart';

class LiveSessionsScreen extends StatelessWidget {
  const LiveSessionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final List<Map<String, dynamic>> rooms = [
      {
        'title': 'Tıp Kazanacaklar',
        'subtitle': 'Biyoloji & Kimya Odaklı',
        'participants': 24,
        'maxParticipants': 50,
        'color': Colors.redAccent,
        'icon': Icons.medical_services_rounded,
      },
      {
        'title': 'Sessiz Çalışma',
        'subtitle': 'Pomodoro 50/10',
        'participants': 12,
        'maxParticipants': 20,
        'color': Colors.blueGrey,
        'icon': Icons.headphones_rounded,
      },
      {
        'title': 'YKS 2026 Tayfa',
        'subtitle': 'Genel Tekrar',
        'participants': 45,
        'maxParticipants': 100,
        'color': Colors.orangeAccent,
        'icon': Icons.school_rounded,
      },
      {
        'title': 'Gece Kuşları',
        'subtitle': 'Sadece Matematik',
        'participants': 8,
        'maxParticipants': 15,
        'color': Colors.deepPurpleAccent,
        'icon': Icons.nights_stay_rounded,
      },
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Canlı Etüt Odaları', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Birlikte Çalış, Motive Ol!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: rooms.length,
                itemBuilder: (context, index) {
                  final room = rooms[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: room['color'].withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(room['icon'], color: room['color']),
                      ),
                      title: Text(
                        room['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Icon(Icons.people_alt_rounded, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              '${room['participants']} / ${room['maxParticipants']}',
                              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• ${room['subtitle']}',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${room['title']} odasına katılıyorsunuz... (Çok Yakında)')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: room['color'],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Katıl'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
