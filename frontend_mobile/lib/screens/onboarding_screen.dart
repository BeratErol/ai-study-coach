import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_theme.dart';
import '../providers/onboarding_provider.dart';
import '../providers/study_plan_provider.dart';
import 'onboarding/step1_name_gender.dart';
import 'onboarding/step2_education.dart';
import 'onboarding/step3_target_exam.dart';
import 'onboarding/step4_exam_date.dart';
import 'onboarding/step5_study_type.dart';
import 'onboarding/step6_daily_routine.dart';
import 'onboarding/step7_sleep_time.dart';
import 'onboarding/step8_subjects.dart';
import 'onboarding/step_area_selection.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _hasAreaStep(String targetExam) =>
      targetExam == 'YKS' || targetExam == 'KPSS' || targetExam == 'OkulSinavi';

  List<String> _buildStepNames(bool hasArea) => [
        'İsim',
        'Kademe',
        'Hedef Sınav',
        if (hasArea) 'Alan Seçimi',
        'Sınav Tarihi',
        'Biyoritim',
        'Günlük Rutin',
        'Uyku Saati',
        'Dersler',
      ];

  bool _isStepValid(int step, dynamic data, bool hasArea) {
    if (step == 0) return data.name.trim().isNotEmpty && data.gender.isNotEmpty;
    if (step == 1) return data.educationLevel.isNotEmpty;
    if (step == 2) return data.targetExam.isNotEmpty;
    // uni_diger: user adds all subjects manually (customSubjects); for all other
    // OkulSinavi areas the base pool provides subjects so weakSubjects suffices.
    final isOkulDiger = data.targetExam == 'OkulSinavi' &&
        data.selectedArea == 'uni_diger';
    if (hasArea) {
      if (step == 3) return data.selectedArea.isNotEmpty;
      if (step == 5) return data.studyType.isNotEmpty;
      if (step == 8) {
        if (isOkulDiger) return data.customSubjects.isNotEmpty;
        return data.weakSubjects.isNotEmpty;
      }
    } else {
      if (step == 4) return data.studyType.isNotEmpty;
      if (step == 7) return data.weakSubjects.isNotEmpty;
    }
    return true;
  }

  void _next(int totalSteps) {
    if (_currentPage == totalSteps - 1) {
      _finish();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prev() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish() async {
    try {
      await ref.read(onboardingProvider.notifier).completeOnboarding();
    } catch (_) {
      // Backend'e profil yazılamadı → onboarding tamamlanmış sayılmaz.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Profilin kaydedilemedi. İnternet bağlantını kontrol edip tekrar dene.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }
    if (!mounted) return;
    ref.invalidate(studyPlanProvider);
    ref.invalidate(todayTasksProvider);
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingProvider);
    final hasArea = _hasAreaStep(data.targetExam);
    final stepNames = _buildStepNames(hasArea);
    final totalSteps = stepNames.length;
    final valid = _isStepValid(_currentPage, data, hasArea);
    final isLast = _currentPage == totalSteps - 1;

    final pages = [
      const Step1NameGender(),
      const Step2Education(),
      const Step3TargetExam(),
      if (hasArea) const StepAreaSelection(),
      Step4ExamDate(onSkip: () => _next(totalSteps)),
      const Step5StudyType(),
      const Step6DailyRoutine(),
      const Step7SleepTime(),
      const Step8Subjects(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentPage + 1) / totalSteps,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 4,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Adım ${_currentPage + 1}/$totalSteps',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    stepNames[_currentPage],
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: pages,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ContinueButton(
                    valid: valid,
                    isLast: isLast,
                    onTap: valid ? () => _next(totalSteps) : null,
                  ),
                  if (_currentPage > 0) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _prev,
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Geri'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final bool valid;
  final bool isLast;
  final VoidCallback? onTap;

  const _ContinueButton({
    required this.valid,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        decoration: BoxDecoration(
          gradient: valid
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                )
              : null,
          color: valid ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: AppRadius.md,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLast ? 'Programımı Oluştur 🚀' : 'Devam Et',
              style: TextStyle(
                color: valid ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            if (!isLast) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                color: valid ? Colors.white : Colors.grey.shade600,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
