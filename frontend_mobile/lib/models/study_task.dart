import 'study_plan.dart';

class StudyTask {
  final String id;
  final String subjectName;
  final String emoji;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final String taskType;
  final bool isCompleted;
  final bool isMola;
  final bool isStrong;
  final String? topicName;
  final DateTime date;

  const StudyTask({
    required this.id,
    required this.subjectName,
    required this.emoji,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.taskType,
    required this.isCompleted,
    required this.isMola,
    this.isStrong = false,
    this.topicName,
    required this.date,
  });

  factory StudyTask.fromBlock(StudyBlock block, DateTime date) {
    final s = block.startTime;
    final e = block.endTime;
    return StudyTask(
      id: block.id,
      subjectName: block.subjectName,
      emoji: block.emoji,
      startTime:
          '${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')}',
      endTime:
          '${e.hour.toString().padLeft(2, '0')}:${e.minute.toString().padLeft(2, '0')}',
      durationMinutes: block.durationMinutes,
      taskType: block.taskType,
      isCompleted: false,
      isMola: block.isMola,
      isStrong: block.isStrong,
      topicName: null,
      date: date,
    );
  }

  StudyTask copyWith({
    String? id,
    String? subjectName,
    String? emoji,
    String? startTime,
    String? endTime,
    int? durationMinutes,
    String? taskType,
    bool? isCompleted,
    bool? isMola,
    bool? isStrong,
    String? topicName,
    DateTime? date,
  }) {
    return StudyTask(
      id: id ?? this.id,
      subjectName: subjectName ?? this.subjectName,
      emoji: emoji ?? this.emoji,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      taskType: taskType ?? this.taskType,
      isCompleted: isCompleted ?? this.isCompleted,
      isMola: isMola ?? this.isMola,
      isStrong: isStrong ?? this.isStrong,
      topicName: topicName ?? this.topicName,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectName': subjectName,
        'emoji': emoji,
        'startTime': startTime,
        'endTime': endTime,
        'durationMinutes': durationMinutes,
        'taskType': taskType,
        'isCompleted': isCompleted,
        'isMola': isMola,
        'isStrong': isStrong,
        'topicName': topicName,
        // Web ile ortak format: YYYY-MM-DD (web ManualTask.date bunu bekler).
        'date':
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      };

  // Web ile ortak şema toleranslı: web manuel görevi saatsiz/emojisiz yazar
  // (startTime, endTime, emoji, isCompleted, isMola eksik olabilir).
  factory StudyTask.fromJson(Map<String, dynamic> json) => StudyTask(
        id: json['id'] as String,
        subjectName: json['subjectName'] as String,
        emoji: (json['emoji'] as String?) ?? '📝',
        startTime: (json['startTime'] as String?) ?? '',
        endTime: (json['endTime'] as String?) ?? '',
        durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 60,
        taskType: (json['taskType'] as String?) ?? 'konu_anlatimi',
        isCompleted: (json['isCompleted'] as bool?) ?? false,
        isMola: (json['isMola'] as bool?) ?? false,
        isStrong: json['isStrong'] as bool? ?? false,
        topicName: json['topicName'] as String?,
        date: DateTime.parse(json['date'] as String),
      );
}
