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

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectName': subjectName,
        'startHour': startTime.hour,
        'startMinute': startTime.minute,
        'endHour': endTime.hour,
        'endMinute': endTime.minute,
        'durationMinutes': durationMinutes,
        'isStrong': isStrong,
        'taskType': taskType,
        'isMola': isMola,
        'emoji': emoji,
      };

  factory StudyBlock.fromJson(Map<String, dynamic> json) => StudyBlock(
        id: json['id'] as String,
        subjectName: json['subjectName'] as String,
        startTime: TimeOfDay(
          hour: json['startHour'] as int,
          minute: json['startMinute'] as int,
        ),
        endTime: TimeOfDay(
          hour: json['endHour'] as int,
          minute: json['endMinute'] as int,
        ),
        durationMinutes: json['durationMinutes'] as int,
        isStrong: json['isStrong'] as bool,
        taskType: json['taskType'] as String? ?? 'konu_anlatimi',
        isMola: json['isMola'] as bool? ?? false,
        emoji: json['emoji'] as String? ?? '📚',
      );
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

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'dayName': dayName,
        'isOffDay': isOffDay,
        'blocks': blocks.map((b) => b.toJson()).toList(),
      };

  factory StudyDay.fromJson(Map<String, dynamic> json) => StudyDay(
        date: DateTime.parse(json['date'] as String),
        dayName: json['dayName'] as String,
        isOffDay: json['isOffDay'] as bool? ?? false,
        blocks: (json['blocks'] as List)
            .map((b) => StudyBlock.fromJson(b as Map<String, dynamic>))
            .toList(),
      );
}
