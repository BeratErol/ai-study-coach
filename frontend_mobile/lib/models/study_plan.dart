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
}
