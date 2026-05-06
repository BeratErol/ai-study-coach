import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../core/app_theme.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _lessonsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiService().dio.get('/Lesson');
  return List<Map<String, dynamic>>.from(res.data as List);
});

final _todaySessionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final res = await ApiService().dio.get('/StudySession');
    final sessions = List<Map<String, dynamic>>.from(res.data as List);
    final today = DateTime.now().toLocal();
    return sessions.where((s) {
      final d = DateTime.tryParse(s['date'] as String? ?? '')?.toLocal();
      return d != null &&
          d.year == today.year &&
          d.month == today.month &&
          d.day == today.day;
    }).toList()
      ..sort((a, b) {
        final da = DateTime.tryParse(a['date'] as String? ?? '') ?? DateTime(2000);
        final db = DateTime.tryParse(b['date'] as String? ?? '') ?? DateTime(2000);
        return db.compareTo(da);
      });
  } catch (_) {
    return [];
  }
});

final _weeklyPomodoroProvider = FutureProvider<int>((ref) async {
  try {
    final res = await ApiService().dio.get('/StudySession');
    final sessions = List<Map<String, dynamic>>.from(res.data as List);
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return sessions.where((s) {
      final d = DateTime.tryParse(s['date'] as String? ?? '');
      return d != null &&
          d.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
          (s['type'] as String?) == 'pomodoro';
    }).length;
  } catch (_) {
    return 0;
  }
});

// ── Screen ────────────────────────────────────────────────────────────────────

class PomodoroScreen extends ConsumerStatefulWidget {
  const PomodoroScreen({super.key});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen>
    with TickerProviderStateMixin {
  // Timer state
  static const _defaultWork  = 25;
  static const _defaultBreak = 5;

  late int _workMinutes  = _defaultWork;
  late int _breakMinutes = _defaultBreak;

  late int _timeLeft;
  bool _isRunning     = false;
  bool _isWorkSession = true;
  int  _completedToday = 0;
  Timer? _timer;

  // Selection
  Map<String, dynamic>? _selectedLesson;
  Map<String, dynamic>? _selectedTopic;

  // Animation
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _timeLeft = _workMinutes * 60;
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _pulseCtrl.stop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Timer controls ──────────────────────────────────────────────────────────

  void _start() {
    setState(() => _isRunning = true);
    _pulseCtrl.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timer?.cancel();
          _isRunning = false;
          _pulseCtrl.stop();
          _onSessionComplete();
        }
      });
    });
  }

  void _pause() {
    _timer?.cancel();
    _pulseCtrl.stop();
    setState(() => _isRunning = false);
  }

  void _reset() {
    _timer?.cancel();
    _pulseCtrl.stop();
    setState(() {
      _isRunning = false;
      _timeLeft  = (_isWorkSession ? _workMinutes : _breakMinutes) * 60;
    });
  }

  void _switchMode(bool toWork) {
    _timer?.cancel();
    _pulseCtrl.stop();
    setState(() {
      _isWorkSession = toWork;
      _isRunning     = false;
      _timeLeft      = (toWork ? _workMinutes : _breakMinutes) * 60;
    });
  }

  // ── Session complete ────────────────────────────────────────────────────────

  Future<void> _onSessionComplete() async {
    if (!_isWorkSession) {
      showBreakDoneNotification();
      _showSnack('Mola bitti! Çalışmaya devam et. 💪');
      _switchMode(true);
      return;
    }

    setState(() => _completedToday++);
    showWorkDoneNotification(_workMinutes);

    if (_selectedTopic != null) {
      try {
        await ApiService().dio.post('/StudySession', data: {
          'topicId':         _selectedTopic!['id'],
          'durationMinutes': _workMinutes,
          'type':            'pomodoro',
          'date':            DateTime.now().toUtc().toIso8601String(),
        });
        ref.invalidate(_weeklyPomodoroProvider);
        ref.invalidate(_todaySessionsProvider);
        _showSnack('Tebrikler! Pomodoro tamamlandı ve kaydedildi. 🎉');
      } catch (_) {
        _showSnack('Pomodoro tamamlandı, ancak kaydedilemedi.');
      }
    } else {
      _showSnack('Tebrikler! Pomodoro tamamlandı. Konu seçersen otomatik kaydederim. 🎉');
    }

    _switchMode(false);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
      ),
    );
  }

  // ── Settings bottom sheet ───────────────────────────────────────────────────

  void _openSettings() {
    int tmpWork  = _workMinutes;
    int tmpBreak = _breakMinutes;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: AppRadius.full,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Zamanlayıcı Ayarları',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              _DurationPicker(
                label: 'Çalışma süresi',
                value: tmpWork,
                min: 5, max: 60,
                onChanged: (v) => setModal(() => tmpWork = v),
              ),
              const SizedBox(height: 16),
              _DurationPicker(
                label: 'Mola süresi',
                value: tmpBreak,
                min: 1, max: 30,
                onChanged: (v) => setModal(() => tmpBreak = v),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _workMinutes  = tmpWork;
                      _breakMinutes = tmpBreak;
                      _reset();
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Kaydet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Lesson/Topic selector ───────────────────────────────────────────────────

  void _openLessonPicker(List<Map<String, dynamic>> lessons) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LessonPickerSheet(
        lessons: lessons,
        selectedLesson: _selectedLesson,
        selectedTopic:  _selectedTopic,
        onSelect: (lesson, topic) {
          setState(() {
            _selectedLesson = lesson;
            _selectedTopic  = topic;
          });
        },
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  String _fmt(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final total       = (_isWorkSession ? _workMinutes : _breakMinutes) * 60;
    final percent     = _timeLeft / total;
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final lessons     = ref.watch(_lessonsProvider);
    final weeklyPm    = ref.watch(_weeklyPomodoroProvider);
    final todaySessions = ref.watch(_todaySessionsProvider);

    final activeColor = _isWorkSession ? AppColors.primary : AppColors.success;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: _isRunning ? null : _openSettings,
            tooltip: 'Ayarlar',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),

              // ── Weekly badge ──────────────────────────────────────────────
              weeklyPm.when(
                data: (count) => _WeeklyBadge(count: count + _completedToday),
                loading: () => const SizedBox(height: 36),
                error: (e, s) => const SizedBox(height: 36),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Mode toggle ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.borderLight,
                  borderRadius: AppRadius.full,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ModeChip(
                      label: 'Çalışma',
                      selected: _isWorkSession,
                      color: AppColors.primary,
                      onTap: () => _switchMode(true),
                    ),
                    _ModeChip(
                      label: 'Mola',
                      selected: !_isWorkSession,
                      color: AppColors.success,
                      onTap: () => _switchMode(false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Circular timer ────────────────────────────────────────────
              ScaleTransition(
                scale: _isRunning ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
                child: CircularPercentIndicator(
                  radius: 130,
                  lineWidth: 14,
                  percent: percent.clamp(0.0, 1.0),
                  backgroundColor: activeColor.withValues(alpha: 0.12),
                  progressColor: activeColor,
                  circularStrokeCap: CircularStrokeCap.round,
                  animation: false,
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _fmt(_timeLeft),
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w800,
                          color: activeColor,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        _isWorkSession ? 'Çalışma' : 'Mola',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Controls ──────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CircleBtn(
                    icon: Icons.refresh_rounded,
                    onTap: _reset,
                    bg: isDark ? AppColors.cardDark : AppColors.borderLight,
                    fg: AppColors.textSecondary,
                    size: 52,
                  ),
                  const SizedBox(width: 24),
                  _CircleBtn(
                    icon: _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    onTap: _isRunning ? _pause : _start,
                    bg: activeColor,
                    fg: Colors.white,
                    size: 72,
                    iconSize: 36,
                  ),
                  const SizedBox(width: 24),
                  _CircleBtn(
                    icon: Icons.skip_next_rounded,
                    onTap: () => _switchMode(!_isWorkSession),
                    bg: isDark ? AppColors.cardDark : AppColors.borderLight,
                    fg: AppColors.textSecondary,
                    size: 52,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Lesson/Topic selector ─────────────────────────────────────
              lessons.when(
                data: (data) => _SubjectCard(
                  selectedLesson: _selectedLesson,
                  selectedTopic:  _selectedTopic,
                  onTap: () => _openLessonPicker(data),
                ),
                loading: () => const _SubjectCardSkeleton(),
                error: (e, s) => const SizedBox.shrink(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Today's sessions ──────────────────────────────────────────
              _TodaySessionsSection(sessions: todaySessions),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _WeeklyBadge extends StatelessWidget {
  final int count;
  const _WeeklyBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.12),
        borderRadius: AppRadius.full,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded,
              color: AppColors.secondary, size: 18),
          const SizedBox(width: 6),
          Text(
            'Bu hafta $count pomodoro',
            style: const TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: AppRadius.full,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color bg;
  final Color fg;
  final double size;
  final double iconSize;
  const _CircleBtn({
    required this.icon,
    required this.onTap,
    required this.bg,
    required this.fg,
    required this.size,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: fg, size: iconSize),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final Map<String, dynamic>? selectedLesson;
  final Map<String, dynamic>? selectedTopic;
  final VoidCallback onTap;
  const _SubjectCard({
    required this.selectedLesson,
    required this.selectedTopic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedLesson != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hasSelection
              ? AppColors.primary.withValues(alpha: 0.06)
              : Theme.of(context).cardColor,
          borderRadius: AppRadius.lg,
          border: Border.all(
            color: hasSelection ? AppColors.primary.withValues(alpha: 0.3) : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: AppRadius.sm,
              ),
              child: const Icon(Icons.menu_book_rounded,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasSelection ? (selectedLesson!['name'] as String? ?? '') : 'Konu seç',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: hasSelection ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                  if (selectedTopic != null)
                    Text(
                      selectedTopic!['name'] as String? ?? '',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    )
                  else
                    const Text('Çalıştığın konuyu seçerek oturumu otomatik kaydet',
                        style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _SubjectCardSkeleton extends StatelessWidget {
  const _SubjectCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: AppRadius.lg,
      ),
    );
  }
}

class _DurationPicker extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const _DurationPicker({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: value > min ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove_circle_outline_rounded),
              color: AppColors.primary,
            ),
            Expanded(
              child: Center(
                child: Text('$value dk',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800)),
              ),
            ),
            IconButton(
              onPressed: value < max ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add_circle_outline_rounded),
              color: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }
}

// ── Lesson picker bottom sheet ────────────────────────────────────────────────

class _LessonPickerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> lessons;
  final Map<String, dynamic>? selectedLesson;
  final Map<String, dynamic>? selectedTopic;
  final void Function(Map<String, dynamic> lesson, Map<String, dynamic>? topic) onSelect;

  const _LessonPickerSheet({
    required this.lessons,
    required this.selectedLesson,
    required this.selectedTopic,
    required this.onSelect,
  });

  @override
  State<_LessonPickerSheet> createState() => _LessonPickerSheetState();
}

class _LessonPickerSheetState extends State<_LessonPickerSheet> {
  Map<String, dynamic>? _lesson;
  Map<String, dynamic>? _topic;

  @override
  void initState() {
    super.initState();
    _lesson = widget.selectedLesson;
    _topic  = widget.selectedTopic;
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.primary;
    try { return Color(int.parse(hex.replaceAll('#', '0xFF'))); }
    catch (_) { return AppColors.primary; }
  }

  @override
  Widget build(BuildContext context) {
    final topics = (_lesson?['topics'] as List?)
        ?.map((t) => t as Map<String, dynamic>)
        .toList() ?? [];

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight, borderRadius: AppRadius.full),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Ders & Konu Seç',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),

          // Lesson list
          if (widget.lessons.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Henüz ders eklenmedi.',
                  style: TextStyle(color: AppColors.textSecondary)),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.lessons.length,
                itemBuilder: (_, i) {
                  final l = widget.lessons[i];
                  final color = _parseColor(l['colorCode'] as String?);
                  final isSelected = _lesson?['id'] == l['id'];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.15),
                          child: Icon(Icons.menu_book_rounded, color: color, size: 18),
                        ),
                        title: Text(l['name'] as String? ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppColors.primary : null,
                            )),
                        trailing: isSelected
                            ? const Icon(Icons.keyboard_arrow_up_rounded,
                                color: AppColors.primary)
                            : const Icon(Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textHint),
                        onTap: () => setState(() {
                          _lesson = isSelected ? null : l;
                          _topic  = null;
                        }),
                      ),
                      if (isSelected) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 8),
                          child: Wrap(
                            spacing: 8, runSpacing: 8,
                            children: [
                              _TopicChip(
                                label: 'Genel',
                                selected: _topic == null,
                                onTap: () => setState(() => _topic = null),
                              ),
                              ...topics.map((t) => _TopicChip(
                                label: t['name'] as String? ?? '',
                                selected: _topic?['id'] == t['id'],
                                onTap: () => setState(() => _topic = t),
                              )),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _lesson == null
                  ? null
                  : () {
                      widget.onSelect(_lesson!, _topic);
                      Navigator.pop(context);
                    },
              child: const Text('Seç'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TopicChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: AppRadius.full,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// ── Today's Sessions ──────────────────────────────────────────────────────────
class _TodaySessionsSection extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> sessions;
  const _TodaySessionsSection({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final data = sessions.valueOrNull;
    if (sessions.isLoading || data == null || data.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalMin = data.fold<int>(0, (s, e) => s + ((e['durationMinutes'] as int?) ?? 0));
    final pomCount = data.where((e) => (e['type'] as String?) == 'pomodoro').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Bugünkü Oturumlar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text('$pomCount pomodoro · $totalMin dk',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 10),
        ...data.take(5).map((s) {
          final dt = DateTime.tryParse(s['date'] as String? ?? '')?.toLocal();
          final timeStr = dt != null
              ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
              : '';
          final dur = (s['durationMinutes'] as int?) ?? 0;
          final type = (s['type'] as String?) ?? 'pomodoro';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryO07,
              borderRadius: AppRadius.md,
            ),
            child: Row(children: [
              Icon(
                type == 'pomodoro'
                    ? Icons.timer_rounded
                    : Icons.coffee_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  type == 'pomodoro' ? 'Pomodoro' : 'Mola',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              Text('$dur dk',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              Text(timeStr,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint)),
            ]),
          );
        }),
      ],
    );
  }
}
