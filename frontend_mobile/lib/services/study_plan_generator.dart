import 'dart:math' show min, max;
import 'package:flutter/material.dart';
import '../models/onboarding_data.dart';
import '../models/study_plan.dart';

const _dayNames = [
  'Pazartesi',
  'Salı',
  'Çarşamba',
  'Perşembe',
  'Cuma',
  'Cumartesi',
  'Pazar',
];

TimeOfDay _parseTime(String s) {
  final p = s.split(':');
  return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
}

int _toMins(TimeOfDay t) => t.hour * 60 + t.minute;

TimeOfDay _fromMins(int m) =>
    TimeOfDay(hour: (m ~/ 60) % 24, minute: m % 60);

// Kullanıcının seçtiği saat = tam bütçe (okul saati start-time'da hesaplanıyor)
int _calcNetMinutes(int rawHours) => (rawHours * 60).clamp(60, 600);

TimeOfDay _roundStartTime(TimeOfDay t) {
  final m = t.minute;
  if (m <= 5) return TimeOfDay(hour: t.hour, minute: 0);
  if (m <= 20) return TimeOfDay(hour: t.hour, minute: 10);
  if (m <= 35) return TimeOfDay(hour: t.hour, minute: 30);
  if (m <= 50) return TimeOfDay(hour: t.hour, minute: 40);
  return TimeOfDay(hour: (t.hour + 1) % 24, minute: 0);
}

String _getSubjectEmoji(String name) {
  if (name.contains('Matematik') || name.contains('Geometri')) return '📐';
  if (name.contains('Fizik')) return '⚡';
  if (name.contains('Kimya')) return '🧪';
  if (name.contains('Biyoloji')) return '🧬';
  if (name.contains('Türkçe')) return '📖';
  if (name.contains('Edebiyat')) return '✏️';
  if (name.contains('Tarih') || name.contains('İnkılap')) return '🏛️';
  if (name.contains('Coğrafya')) return '🌍';
  if (name.contains('Felsefe')) return '💭';
  if (name.contains('İngilizce') ||
      name.contains('YDT') ||
      name.contains('Dil')) {
    return '🇬🇧';
  }
  if (name.contains('Din')) return '☪️';
  if (name.contains('Vatandaşlık')) return '🏛️';
  if (name.contains('Fen')) return '🔬';
  return '📚';
}

StudyBlock _proto({
  required String id,
  required String subject,
  required int dur,
  required bool isStrong,
  required String type,
  bool isMola = false,
  String? emoji,
}) =>
    StudyBlock(
      id: id,
      subjectName: subject,
      startTime: const TimeOfDay(hour: 0, minute: 0),
      endTime: const TimeOfDay(hour: 0, minute: 0),
      durationMinutes: dur,
      isStrong: isStrong,
      taskType: type,
      isMola: isMola,
      emoji: emoji ?? _getSubjectEmoji(subject),
    );

// Günün ders slotu sayısını hesapla (75% zayıf / 25% güçlü hedefi)
({int weaks, int strongs}) _slotsForDay({
  required int net,
  required int numWeak,
  required int numStrong,
}) {
  if (numWeak == 0 && numStrong == 0) return (weaks: 0, strongs: 0);

  if (numStrong == 0) {
    return (weaks: min(numWeak, net ~/ 60), strongs: 0);
  }

  // Bütçenin %25'ini güçlü dersler için ayır, min 1
  final targetStrongs = max(1, min(numStrong, ((net * 0.25) / 40).round()));
  final remainingForWeak = net - targetStrongs * 40;

  if (remainingForWeak < 60 && numWeak > 0) {
    // Çok dar bütçe: güçlü dersi bırak, zayıf dersi tercih et
    return (weaks: min(numWeak, net ~/ 60), strongs: 0);
  }

  return (
    weaks: numWeak == 0 ? 0 : min(numWeak, remainingForWeak ~/ 60),
    strongs: targetStrongs,
  );
}

// Belirli güne ait seçilmiş dersleri blok + saat olarak oluştur
List<StudyBlock> _buildDayBlocks({
  required List<String> weakSubjects,
  required List<String> strongSubjects,
  required int net,
  required bool isWeekend,
  required OnboardingData data,
  required int dayOffset,
  required Map<String, int> weakOccurrences,
  required Map<String, int> strongOccurrences,
}) {
  int counter = 0;

  final weakBlocks = weakSubjects.map((s) {
    final count = weakOccurrences[s] ?? 0;
    weakOccurrences[s] = count + 1;
    // 1. görünüm → konu_anlatimi, 2. → soru_cozumu, sonra tekrar
    final type = count.isEven ? 'konu_anlatimi' : 'soru_cozumu';
    return _proto(
      id: 'w_${dayOffset}_${counter++}',
      subject: s,
      dur: 60,
      isStrong: false,
      type: type,
    );
  }).toList();

  final strongBlocks = strongSubjects.map((s) {
    final count = strongOccurrences[s] ?? 0;
    strongOccurrences[s] = count + 1;
    // 1. görünüm → soru_cozumu, 2. → konu_anlatimi, sonra tekrar
    final type = count.isEven ? 'soru_cozumu' : 'konu_anlatimi';
    return _proto(
      id: 's_${dayOffset}_${counter++}',
      subject: s,
      dur: 40,
      isStrong: true,
      type: type,
    );
  }).toList();

  final molaDur = net >= 360 ? 60 : 30;
  final molaBlock = _proto(
    id: 'm_${dayOffset}_mola',
    subject: 'Mola',
    dur: molaDur,
    isStrong: false,
    type: 'mola',
    isMola: true,
    emoji: '☕',
  );

  // Düzen: [zayıf...] mola [güçlü...]
  // Zayıf ders varsa mola her zaman eklenir
  final fitting = <StudyBlock>[...weakBlocks];

  if (weakBlocks.isNotEmpty) {
    fitting.add(molaBlock);
  }

  fitting.addAll(strongBlocks);

  if (fitting.isEmpty) return [];

  // Başlangıç saati
  int startMins;
  if (data.studyType == 'sabah') {
    if (!isWeekend && data.hasWeekdaySchool) {
      startMins = _toMins(_parseTime(data.weekdayEndTime)) + 60;
    } else if (isWeekend && data.hasWeekendCourse) {
      startMins = _toMins(_parseTime(data.weekendStartTime)) + 180;
    } else {
      startMins = 9 * 60;
    }
  } else {
    final latestStr = isWeekend ? data.weekendLatestTime : data.weekdayLatestTime;
    final totalSched = fitting.fold<int>(0, (s, b) => s + b.durationMinutes) +
        (fitting.length > 1 ? (fitting.length - 1) * 10 : 0);
    startMins = _toMins(_parseTime(latestStr)) - totalSched;
    if (startMins < 14 * 60) startMins = 14 * 60;
  }

  // Saatleri ata — ilk başlangıç yuvarlanır, sonrakiler prevEnd + 10
  TimeOfDay current = _roundStartTime(_fromMins(startMins));
  final result = <StudyBlock>[];

  for (int i = 0; i < fitting.length; i++) {
    final b = fitting[i];
    final start = current;
    final end = _fromMins(_toMins(current) + b.durationMinutes);
    result.add(StudyBlock(
      id: b.id,
      subjectName: b.subjectName,
      startTime: start,
      endTime: end,
      durationMinutes: b.durationMinutes,
      isStrong: b.isStrong,
      taskType: b.taskType,
      isMola: b.isMola,
      emoji: b.emoji,
    ));
    if (i < fitting.length - 1) {
      current = _fromMins(_toMins(end) + 10);
    }
  }

  return result;
}

abstract final class StudyPlanGenerator {
  static List<StudyDay> generateWeeklyPlan(OnboardingData data) =>
      _generateWeeklyPlan(data);
}

List<StudyDay> _generateWeeklyPlan(OnboardingData data) {
  final now = DateTime.now();
  final days = <StudyDay>[];

  final numWeak = data.weakSubjects.length;
  final numStrong = data.strongSubjects.length;

  // Haftalık rotasyon: her gün farklı ders alt-kümesi
  int weakIdx = 0;
  int strongIdx = 0;

  // Her dersin kaçıncı kez göründüğünü izle (görev türü rotasyonu için)
  final weakOccurrences = <String, int>{};
  final strongOccurrences = <String, int>{};

  for (int offset = 0; offset < 7; offset++) {
    final date = DateTime(now.year, now.month, now.day + offset);
    final dayIdx = date.weekday - 1; // 0=Pzt … 6=Paz
    final dayName = _dayNames[dayIdx];

    if (data.offDays.contains(dayIdx)) {
      days.add(StudyDay(
        date: date,
        dayName: dayName,
        blocks: [],
        isOffDay: true,
      ));
      continue;
    }

    final isWeekend = dayIdx >= 5;
    final net =
        _calcNetMinutes(isWeekend ? data.weekendStudyHours : data.weekdayStudyHours);

    final slots = _slotsForDay(net: net, numWeak: numWeak, numStrong: numStrong);

    // Bu günün derslerini döngüsel indeksle seç
    final dayWeakSubjects = List.generate(
      slots.weaks,
      (i) => data.weakSubjects[(weakIdx + i) % numWeak],
    );
    final dayStrongSubjects = List.generate(
      slots.strongs,
      (i) => data.strongSubjects[(strongIdx + i) % numStrong],
    );

    // İndeksleri ilerlet (bir sonraki gün farklı derslerden başlasın)
    if (numWeak > 0) weakIdx = (weakIdx + slots.weaks) % numWeak;
    if (numStrong > 0) strongIdx = (strongIdx + slots.strongs) % numStrong;

    days.add(StudyDay(
      date: date,
      dayName: dayName,
      blocks: _buildDayBlocks(
        weakSubjects: dayWeakSubjects,
        strongSubjects: dayStrongSubjects,
        net: net,
        isWeekend: isWeekend,
        data: data,
        dayOffset: offset,
        weakOccurrences: weakOccurrences,
        strongOccurrences: strongOccurrences,
      ),
    ));
  }

  return days;
}
