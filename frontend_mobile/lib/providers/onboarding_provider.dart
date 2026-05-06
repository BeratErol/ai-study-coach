import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/onboarding_data.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import '../services/user_prefs_service.dart';

class OnboardingNotifier extends StateNotifier<OnboardingData> {
  OnboardingNotifier() : super(OnboardingData());

  void updateName(String v) => state = state.copyWith(name: v);
  void updateGender(String v) => state = state.copyWith(gender: v);
  void updateEducationLevel(String v) => state = state.copyWith(educationLevel: v);
  void updateTargetExam(String v) => state = state.copyWith(targetExam: v);
  void updateExamDate(DateTime? v) =>
      state = v == null ? state.copyWith(clearExamDate: true) : state.copyWith(examDate: v);
  void updateStudyType(String v) => state = state.copyWith(studyType: v);
  void updateHasWeekdaySchool(bool v) => state = state.copyWith(hasWeekdaySchool: v);
  void updateWeekdayStartTime(String v) => state = state.copyWith(weekdayStartTime: v);
  void updateWeekdayEndTime(String v) => state = state.copyWith(weekdayEndTime: v);
  void updateWeekdayStudyHours(int v) => state = state.copyWith(weekdayStudyHours: v);
  void updateHasWeekendCourse(bool v) => state = state.copyWith(hasWeekendCourse: v);
  void updateWeekendStartTime(String v) => state = state.copyWith(weekendStartTime: v);
  void updateWeekendStudyHours(int v) => state = state.copyWith(weekendStudyHours: v);
  void updateWeekdayLatestTime(String v) => state = state.copyWith(weekdayLatestTime: v);
  void updateWeekendLatestTime(String v) => state = state.copyWith(weekendLatestTime: v);
  void updateOffDays(List<int> v) => state = state.copyWith(offDays: v);
  void updateStrongSubjects(List<String> v) => state = state.copyWith(strongSubjects: v);
  void updateWeakSubjects(List<String> v) => state = state.copyWith(weakSubjects: v);
  void updateSelectedArea(String v) => state = state.copyWith(selectedArea: v);

  Future<void> completeOnboarding() async {
    final userId = await TokenService.getUserId();
    if (userId == null) return;

    await UserPrefsService.setOnboardingCompleted(userId, true);
    await UserPrefsService.saveOnboardingData(userId, state.toJson());

    try {
      await ApiService().dio.post('/UserProfile', data: state.toJson());
    } catch (e) {
      debugPrint('UserProfile sync failed: $e');
    }
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingData>(
  (ref) => OnboardingNotifier(),
);
