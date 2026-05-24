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

// Kullanıcının seçtiği saat = tam bütçe
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

// Belirli güne ait blokları döngüsel dolgu mantığıyla oluştur.
// Güçlü blok: 30 dk. Zayıf blok: 60 dk.
// Sıra: zayıf, zayıf, güçlü, zayıf, zayıf, güçlü … (yaklaşık 75/25)
// Bütçe dolana kadar döngü devam eder. Mola sadece bir kez, yaklaşık ortaya eklenir.
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
  const weakDur = 60;
  const strongDur = 30;

  final hasWeak = weakSubjects.isNotEmpty;
  final hasStrong = strongSubjects.isNotEmpty;

  if (!hasWeak && !hasStrong) return [];

  // Mola süresi (bütçeden DÜŞÜLMEZ — ders saati bütçesi tam korunur)
  final molaDur = net >= 360 ? 60 : 30;

  // Yeterince bütçe var mı kontrol et (en az 1 blok sığmalı)
  final minBlock = hasWeak ? weakDur : strongDur;
  if (net < minBlock) return [];

  // Ders bloklarına ayrılan bütçe = tam net (mola ek olarak gelir)
  final budgetForStudy = net;
  if (budgetForStudy <= 0) return [];

  // Sıra: zayıf bloklar → mola (zayıfların ortasına) → güçlü bloklar
  // Zayıf bloklar önce bütçeyi doldurur, kalan bütçeye güçlü bloklar eklenir.
  // Güçlü sayısı zayıf sayısını geçemez.
  final weakBlocks = <StudyBlock>[];
  final strongBlocks = <StudyBlock>[];
  int weakCursor = 0;
  int strongCursor = 0;
  int counter = 0;

  // w×60 + s×30 = net, s ≤ w olacak şekilde w ve s'yi bul.
  // En fazla güçlü dersi alacak şekilde çöz (tam doldurma öncelikli).
  int targetWeak = 0;
  int targetStrong = 0;

  if (!hasWeak) {
    // Sadece güçlü ders varsa tümünü doldur
    targetStrong = budgetForStudy ~/ strongDur;
  } else if (!hasStrong) {
    targetWeak = budgetForStudy ~/ weakDur;
  } else {
    // Her iki tür de var: w×60 + s×30 = net, s ≤ w
    // w=1'den başlayarak artır, her w için max s hesapla, tam dolduranı seç.
    // Tam doldurulamazsa en yakını al.
    int bestW = 0, bestS = 0, bestRemainder = budgetForStudy;
    for (int w = 1; w * weakDur <= budgetForStudy; w++) {
      final remaining = budgetForStudy - w * weakDur;
      final s = (remaining ~/ strongDur).clamp(0, w);
      final remainder = remaining - s * strongDur;
      if (remainder < bestRemainder) {
        bestRemainder = remainder;
        bestW = w;
        bestS = s;
      }
      if (remainder == 0) break; // tam dolduruldu, daha fazla aramanın gereği yok
    }
    targetWeak = bestW;
    targetStrong = bestS;
  }

  // Determine starting cursor positions based on total occurrences so far,
  // so consecutive days cycle through subjects fairly rather than restarting.
  final totalWeakSoFar =
      weakOccurrences.values.fold(0, (s, v) => s + v);
  final totalStrongSoFar =
      strongOccurrences.values.fold(0, (s, v) => s + v);
  weakCursor = weakSubjects.isNotEmpty ? totalWeakSoFar % weakSubjects.length : 0;
  strongCursor = strongSubjects.isNotEmpty ? totalStrongSoFar % strongSubjects.length : 0;

  for (int i = 0; i < targetWeak; i++) {
    final subject = weakSubjects[weakCursor % weakSubjects.length];
    weakCursor++;
    final count = weakOccurrences[subject] ?? 0;
    weakOccurrences[subject] = count + 1;
    weakBlocks.add(_proto(
      id: 'w_${dayOffset}_${counter++}',
      subject: subject,
      dur: weakDur,
      isStrong: false,
      type: count.isEven ? 'konu_anlatimi' : 'soru_cozumu',
    ));
  }

  for (int i = 0; i < targetStrong; i++) {
    final subject = strongSubjects[strongCursor % strongSubjects.length];
    strongCursor++;
    final count = strongOccurrences[subject] ?? 0;
    strongOccurrences[subject] = count + 1;
    strongBlocks.add(_proto(
      id: 's_${dayOffset}_${counter++}',
      subject: subject,
      dur: strongDur,
      isStrong: true,
      type: count.isEven ? 'soru_cozumu' : 'konu_anlatimi',
    ));
  }

  final weakBlockCount = weakBlocks.length;
  final rawBlocks = [...weakBlocks, ...strongBlocks];

  if (rawBlocks.isEmpty) return [];

  // Mola bloğunu oluştur
  final molaBlock = _proto(
    id: 'm_${dayOffset}_mola',
    subject: 'Mola',
    dur: molaDur,
    isStrong: false,
    type: 'mola',
    isMola: true,
    emoji: '☕',
  );

  // Mola zayıf blokların tam ortasına girer (ceil(weakCount/2). zayıftan sonra)
  final molaAfterWeakN = (weakBlockCount / 2).ceil().clamp(1, weakBlockCount);
  final insertIdx = molaAfterWeakN; // rawBlocks'ta ilk weakBlockCount eleman zayıf

  final fitting = <StudyBlock>[...rawBlocks];
  fitting.insert(insertIdx, molaBlock);

  // Başlangıç saatini hesapla
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
    final latestStr =
        isWeekend ? data.weekendLatestTime : data.weekdayLatestTime;
    final totalSched = fitting.fold<int>(0, (s, b) => s + b.durationMinutes) +
        (fitting.length > 1 ? (fitting.length - 1) * 10 : 0);
    // Gece kuşu: "en geç" 00:00–04:00 arası seçildiyse ertesi günün saati
    // anlamına gelir (örn. "01:00" = bugün 25:00). +24 saat ekle.
    int latestMins = _toMins(_parseTime(latestStr));
    if (latestMins < 4 * 60) latestMins += 24 * 60;
    startMins = latestMins - totalSched;
    if (startMins < 14 * 60) startMins = 14 * 60;
  }

  // Saatleri ata
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
    final net = _calcNetMinutes(
        isWeekend ? data.weekendStudyHours : data.weekdayStudyHours);

    days.add(StudyDay(
      date: date,
      dayName: dayName,
      blocks: _buildDayBlocks(
        weakSubjects: data.weakSubjects,
        strongSubjects: data.strongSubjects,
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
