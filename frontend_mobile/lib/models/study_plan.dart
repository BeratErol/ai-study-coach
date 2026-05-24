import 'package:flutter/material.dart';

class StudyBlock {
  final String id;
  final String subjectName;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int durationMinutes;
  final bool isStrong;
  final String taskType; // 'konu_anlatimi' | 'tekrar' | 'mola'
  final bool isMola;
  final String emoji;

  const StudyBlock({
    required this.id,
    required this.subjectName,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.isStrong,
    this.taskType = 'konu_anlatimi',
    this.isMola = false,
    this.emoji = '📚',
  });

  static String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static TimeOfDay _parseTime(String s) {
    final parts = s.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: parts.length > 1 ? int.parse(parts[1]) : 0,
    );
  }

  // Web ile ortak format: startTime/endTime "HH:MM" string.
  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectName': subjectName,
        'startTime': _fmtTime(startTime),
        'endTime': _fmtTime(endTime),
        'durationMinutes': durationMinutes,
        'isStrong': isStrong,
        'taskType': taskType,
        'isMola': isMola,
        'emoji': emoji,
      };

  // Hem yeni (startTime: "HH:MM") hem eski (startHour/startMinute) formatları okur.
  factory StudyBlock.fromJson(Map<String, dynamic> json) {
    TimeOfDay readTime(String prefix) {
      final s = json['${prefix}Time'];
      if (s is String && s.isNotEmpty) return _parseTime(s);
      final h = json['${prefix}Hour'];
      final m = json['${prefix}Minute'];
      if (h is num) {
        return TimeOfDay(hour: h.toInt(), minute: (m is num ? m.toInt() : 0));
      }
      return const TimeOfDay(hour: 0, minute: 0);
    }

    return StudyBlock(
      id: json['id'] as String,
      subjectName: json['subjectName'] as String,
      startTime: readTime('start'),
      endTime: readTime('end'),
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      isStrong: (json['isStrong'] as bool?) ?? false,
      taskType: json['taskType'] as String? ?? 'konu_anlatimi',
      isMola: json['isMola'] as bool? ?? false,
      emoji: json['emoji'] as String? ?? '📚',
    );
  }
}

class StudyDay {
  final DateTime date;
  final String dayName;
  final List<StudyBlock> blocks;
  final bool isOffDay;

  const StudyDay({
    required this.date,
    required this.dayName,
    required this.blocks,
    this.isOffDay = false,
  });

  factory StudyDay.empty() => StudyDay(
        date: DateTime.now(),
        dayName: '',
        blocks: [],
      );

  int get totalMinutes => blocks.fold(0, (s, b) => s + b.durationMinutes);

  // Web ile ortak format: date = "YYYY-MM-DD" (UTC kayması yok).
  Map<String, dynamic> toJson() => {
        'date':
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'dayName': dayName,
        'isOffDay': isOffDay,
        'blocks': blocks.map((b) => b.toJson()).toList(),
      };

  // Hem "YYYY-MM-DD" hem tam ISO timestamp formatlarını okur.
  factory StudyDay.fromJson(Map<String, dynamic> json) {
    final raw = json['date'] as String;
    DateTime parsed;
    if (raw.length == 10) {
      // "YYYY-MM-DD" — yerel midnight olarak oku (UTC kayması olmaz)
      final p = raw.split('-').map(int.parse).toList();
      parsed = DateTime(p[0], p[1], p[2]);
    } else {
      // Tam ISO — yerel timezone'a çevir
      parsed = DateTime.parse(raw).toLocal();
    }
    return StudyDay(
      date: parsed,
      dayName: json['dayName'] as String,
      isOffDay: json['isOffDay'] as bool? ?? false,
      blocks: (json['blocks'] as List)
          .map((b) => StudyBlock.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }
}
