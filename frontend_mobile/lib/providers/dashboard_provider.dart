import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

final lessonsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiService().dio.get('/Lesson');
  return List<Map<String, dynamic>>.from(res.data as List);
});

final dashboardCoachProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final res = await ApiService().dio.get('/Ai/dashboard-coach');
    return Map<String, dynamic>.from(res.data as Map);
  } catch (_) {
    return <String, dynamic>{
      'greeting': 'Merhaba! 👋',
      'todayFocus': 'Bugün planına sadık kal.',
      'weakAreaWarning': '',
      'motivationNote': 'Her gün küçük adımlar büyük başarılar getirir! 🚀',
      'actionItems': ['Planındaki ilk dersi başlat', '25 dk odaklanarak çalış'],
    };
  }
});

final weeklySummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ApiService().dio.get('/StudySession/weekly-summary');
  return Map<String, dynamic>.from(res.data as Map);
});

final recentExamProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final res = await ApiService().dio.get('/Exam');
  final list = List<Map<String, dynamic>>.from(res.data as List);
  if (list.isEmpty) return null;
  list.sort((a, b) {
    final da = DateTime.tryParse(a['date'] as String? ?? '') ?? DateTime(2000);
    final db = DateTime.tryParse(b['date'] as String? ?? '') ?? DateTime(2000);
    return db.compareTo(da);
  });
  return list.first;
});

final monthlyHeatmapProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiService().dio.get('/StudySession/monthly-heatmap');
  return List<Map<String, dynamic>>.from(res.data as List);
});

final selectedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());
