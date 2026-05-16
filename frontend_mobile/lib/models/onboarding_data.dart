class OnboardingData {
  String name;
  String gender;
  String educationLevel;
  String targetExam;
  String selectedArea;
  DateTime? examDate;
  String studyType;
  bool hasWeekdaySchool;
  String weekdayStartTime;
  String weekdayEndTime;
  int weekdayStudyHours;
  bool hasWeekendCourse;
  String weekendStartTime;
  int weekendStudyHours;
  String weekdayLatestTime;
  String weekendLatestTime;
  List<int> offDays;
  List<String> strongSubjects;
  List<String> weakSubjects;
  // Kullanıcının kendi eklediği özel dersler (Okul Sınavlarım / Üniversite)
  List<String> customSubjects;

  OnboardingData({
    this.name = '',
    this.gender = '',
    this.educationLevel = '',
    this.targetExam = '',
    this.selectedArea = '',
    this.examDate,
    this.studyType = '',
    this.hasWeekdaySchool = true,
    this.weekdayStartTime = '08:00',
    this.weekdayEndTime = '15:30',
    this.weekdayStudyHours = 3,
    this.hasWeekendCourse = false,
    this.weekendStartTime = '10:00',
    this.weekendStudyHours = 4,
    this.weekdayLatestTime = '22:30',
    this.weekendLatestTime = '23:30',
    List<int>? offDays,
    List<String>? strongSubjects,
    List<String>? weakSubjects,
    List<String>? customSubjects,
  })  : offDays = offDays ?? [],
        strongSubjects = strongSubjects ?? [],
        weakSubjects = weakSubjects ?? [],
        customSubjects = customSubjects ?? [];

  OnboardingData copyWith({
    String? name,
    String? gender,
    String? educationLevel,
    String? targetExam,
    String? selectedArea,
    DateTime? examDate,
    bool clearExamDate = false,
    String? studyType,
    bool? hasWeekdaySchool,
    String? weekdayStartTime,
    String? weekdayEndTime,
    int? weekdayStudyHours,
    bool? hasWeekendCourse,
    String? weekendStartTime,
    int? weekendStudyHours,
    String? weekdayLatestTime,
    String? weekendLatestTime,
    List<int>? offDays,
    List<String>? strongSubjects,
    List<String>? weakSubjects,
    List<String>? customSubjects,
  }) {
    return OnboardingData(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      educationLevel: educationLevel ?? this.educationLevel,
      targetExam: targetExam ?? this.targetExam,
      selectedArea: selectedArea ?? this.selectedArea,
      examDate: clearExamDate ? null : (examDate ?? this.examDate),
      studyType: studyType ?? this.studyType,
      hasWeekdaySchool: hasWeekdaySchool ?? this.hasWeekdaySchool,
      weekdayStartTime: weekdayStartTime ?? this.weekdayStartTime,
      weekdayEndTime: weekdayEndTime ?? this.weekdayEndTime,
      weekdayStudyHours: weekdayStudyHours ?? this.weekdayStudyHours,
      hasWeekendCourse: hasWeekendCourse ?? this.hasWeekendCourse,
      weekendStartTime: weekendStartTime ?? this.weekendStartTime,
      weekendStudyHours: weekendStudyHours ?? this.weekendStudyHours,
      weekdayLatestTime: weekdayLatestTime ?? this.weekdayLatestTime,
      weekendLatestTime: weekendLatestTime ?? this.weekendLatestTime,
      offDays: offDays ?? List<int>.from(this.offDays),
      strongSubjects: strongSubjects ?? List<String>.from(this.strongSubjects),
      weakSubjects: weakSubjects ?? List<String>.from(this.weakSubjects),
      customSubjects: customSubjects ?? List<String>.from(this.customSubjects),
    );
  }

  factory OnboardingData.fromJson(Map<String, dynamic> json) => OnboardingData(
        name: json['name'] as String? ?? '',
        gender: json['gender'] as String? ?? '',
        educationLevel: json['educationLevel'] as String? ?? '',
        targetExam: json['targetExam'] as String? ?? '',
        selectedArea: json['selectedArea'] as String? ?? '',
        examDate: json['examDate'] != null
            ? DateTime.tryParse(json['examDate'] as String)
            : null,
        studyType: json['studyType'] as String? ?? '',
        hasWeekdaySchool: json['hasWeekdaySchool'] as bool? ?? true,
        weekdayStartTime: json['weekdayStartTime'] as String? ?? '08:00',
        weekdayEndTime: json['weekdayEndTime'] as String? ?? '15:30',
        weekdayStudyHours: json['weekdayStudyHours'] as int? ?? 3,
        hasWeekendCourse: json['hasWeekendCourse'] as bool? ?? false,
        weekendStartTime: json['weekendStartTime'] as String? ?? '10:00',
        weekendStudyHours: json['weekendStudyHours'] as int? ?? 4,
        weekdayLatestTime: json['weekdayLatestTime'] as String? ?? '22:30',
        weekendLatestTime: json['weekendLatestTime'] as String? ?? '23:30',
        offDays: (json['offDays'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            [],
        strongSubjects: (json['strongSubjects'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        weakSubjects: (json['weakSubjects'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        customSubjects: (json['customSubjects'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'gender': gender,
        'educationLevel': educationLevel,
        'targetExam': targetExam,
        'selectedArea': selectedArea,
        'examDate': examDate?.toIso8601String(),
        'studyType': studyType,
        'hasWeekdaySchool': hasWeekdaySchool,
        'weekdayStartTime': weekdayStartTime,
        'weekdayEndTime': weekdayEndTime,
        'weekdayStudyHours': weekdayStudyHours,
        'hasWeekendCourse': hasWeekendCourse,
        'weekendStartTime': weekendStartTime,
        'weekendStudyHours': weekendStudyHours,
        'weekdayLatestTime': weekdayLatestTime,
        'weekendLatestTime': weekendLatestTime,
        'offDays': offDays,
        'strongSubjects': strongSubjects,
        'weakSubjects': weakSubjects,
        'customSubjects': customSubjects,
      };
}
