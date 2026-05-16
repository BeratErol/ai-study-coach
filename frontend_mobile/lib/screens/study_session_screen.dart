import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/study_task.dart';
import '../providers/study_plan_provider.dart';
import '../painters/timer_ring_painter.dart';
import '../core/app_theme.dart';
import '../widgets/study_with_me_card.dart';

class StudySessionScreen extends ConsumerStatefulWidget {
  final StudyTask task;
  const StudySessionScreen({super.key, required this.task});

  @override
  ConsumerState<StudySessionScreen> createState() =>
      _StudySessionScreenState();
}

class _StudySessionScreenState extends ConsumerState<StudySessionScreen> {
  late int _remainingSeconds;
  late int _totalSeconds;
  Timer? _timer;
  bool _isBreak = false;
  int _breakSeconds = 300;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.task.durationMinutes * 60;
    _remainingSeconds = _totalSeconds;
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTimer());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      bool complete = false;
      setState(() {
        if (_isBreak) {
          if (_breakSeconds > 0) {
            _breakSeconds--;
          } else {
            _isBreak = false;
            _breakSeconds = 300;
          }
        } else {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _timer?.cancel();
            complete = true;
          }
        }
      });
      if (complete && mounted) _onComplete();
    });
  }

  void _onComplete() {
    ref.read(completedTaskIdsProvider.notifier).mark(widget.task.id);
    _showCompletionDialog();
  }

  double get _progress => _isBreak
      ? _breakSeconds / 300.0
      : (_totalSeconds > 0 ? _remainingSeconds / _totalSeconds : 0.0);

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static String _taskTypeLabel(String type) {
    switch (type) {
      case 'konu_anlatimi': return 'Konu Anlatımı';
      case 'soru_cozumu':   return 'Soru Çözümü';
      case 'deneme':        return 'Deneme Sınavı';
      case 'tekrar':        return 'Tekrar';
      default:              return type;
    }
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────

  void _confirmExit() {
    if (!(_timer?.isActive ?? false)) {
      context.pop();
      return;
    }
    _timer?.cancel();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Çalışmayı Bırak?'),
        content: const Text(
            'Geri dönersen timer durur. Devam etmek ister misin?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startTimer();
            },
            child: const Text('Devam Et')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Çık',
                style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
  }

  void _confirmFinish() {
    _timer?.cancel();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Çalışmayı Bitir?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'Süre dolmadan bitirirsen görev tamamlanmış sayılmaz. Emin misin?',
            style: TextStyle(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startTimer();
            },
            child: const Text('İptal',
                style: TextStyle(color: AppColors.primary))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Evet, Bitir',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Text('🎉 '),
          Text('Harika!',
              style: TextStyle(fontWeight: FontWeight.w800)),
        ]),
        content: Text(
            '${widget.task.subjectName} görevini tamamladın! Devam et! 💪',
            style: const TextStyle(height: 1.5)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: const Text('Devam',
                style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bgColor = _isBreak
        ? const Color(0xFF1B4332)
        : const Color(0xFF1A1A2E);
    const textPrimary = Colors.white;
    const textSecondary = Colors.white70;
    final pillBg = Colors.white.withValues(alpha: 0.15);
    final cardBg = Colors.white.withValues(alpha: 0.10);
    final cardBorder = Colors.white.withValues(alpha: 0.12);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Top bar ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left,
                          color: textPrimary, size: 30),
                      onPressed: _confirmExit,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: pillBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(children: [
                        Text(_isBreak ? '⏸' : '🔥',
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(_isBreak ? 'Mola' : 'Odaklanıyor',
                            style: const TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                    // Boşluk (simetri için)
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // ── Title ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.task.subjectName} — '
                        '${_taskTypeLabel(widget.task.taskType)}',
                        style: const TextStyle(
                            color: textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800),
                      ),
                      if (widget.task.topicName != null &&
                          widget.task.topicName!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            widget.task.topicName!,
                            style: const TextStyle(
                                color: textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Ortam & YouTube birleşik kart (sadece çalışma modu) ────
              if (!_isBreak)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const StudyWithMeCard(),
                ),

              // ── Timer ring ─────────────────────────────────────────────
              SizedBox(
                height: 260,
                child: Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: CustomPaint(
                      painter: TimerRingPainter(
                        progress: _progress,
                        ringColor: _isBreak
                            ? const Color(0xFF10B981)
                            : AppColors.secondary,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isBreak
                                  ? _formatTime(_breakSeconds)
                                  : _formatTime(_remainingSeconds),
                              style: const TextStyle(
                                  color: textPrimary,
                                  fontSize: 52,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 2),
                            ),
                            if (_isBreak)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('Nefes Al',
                                    style: TextStyle(
                                        color: Color(0xFF6EE7B7),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Break card (mola modunda) ──────────────────────────────
              if (_isBreak)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(children: [
                      const Icon(Icons.self_improvement,
                          color: textSecondary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Acil Durum Molası',
                                style: TextStyle(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w700)),
                            Text('Kalan: ${_formatTime(_breakSeconds)}',
                                style: const TextStyle(
                                    color: textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _isBreak = false;
                          _breakSeconds = 300;
                        }),
                        child: const Text('Atla',
                            style: TextStyle(
                                color: Color(0xFF6EE7B7),
                                fontWeight: FontWeight.w700)),
                      ),
                    ]),
                  ),
                ),

              const SizedBox(height: 24),

              // ── Mola / Bitir buttons ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(60, 0, 60, 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CircleButton(
                      icon: Icons.self_improvement,
                      label: 'Mola',
                      bgColor: Colors.white.withValues(alpha: 0.15),
                      iconColor: const Color(0xFF6EE7B7),
                      labelColor: textSecondary,
                      onTap: () => setState(() {
                        _isBreak = true;
                        _breakSeconds = 300;
                      }),
                    ),
                    _CircleButton(
                      icon: Icons.stop,
                      label: 'Bitir',
                      bgColor: Colors.white.withValues(alpha: 0.15),
                      iconColor: const Color(0xFFF87171),
                      labelColor: textSecondary,
                      onTap: _confirmFinish,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final Color labelColor;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    required this.labelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 64,
          height: 64,
          decoration:
              BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(color: labelColor, fontSize: 12)),
      ]),
    );
  }
}
