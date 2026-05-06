import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/study_task.dart';
import '../providers/study_plan_provider.dart';
import '../painters/timer_ring_painter.dart';
import '../core/app_theme.dart';

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
  String _selectedSound = 'Hafif Yağmur'; // _soundUrlMap'teki ilk key ile eşleşmeli
  bool _isSoundPlaying = false;
  late final AudioPlayer _audioPlayer;

  static const _soundUrlMap = {
    'Hafif Yağmur':
        'https://freesound.org/data/previews/34/34065_131336-lq.mp3',
    'Sağanak Yağmur':
        'https://freesound.org/data/previews/136/136971_1661766-lq.mp3',
    'Hafif Yağmur ve Gök Gürültüsü':
        'https://freesound.org/data/previews/704/704603_14270728-lq.mp3',
    'Ateş':
        'https://freesound.org/data/previews/414/414767_5121236-lq.mp3',
    'Ateş ve Yağmur':
        'https://freesound.org/data/previews/209/209582_2211660-lq.mp3',
    'Ateş ve Rüzgar':
        'https://freesound.org/data/previews/626/626277_12517458-lq.mp3',
    'Kuş':
        'https://freesound.org/data/previews/723/723913_15574595-lq.mp3',
    'Kuş ve Su':
        'https://freesound.org/data/previews/39/39831_131336-lq.mp3',
    'Orman':
        'https://freesound.org/data/previews/427/427400_8387171-lq.mp3',
    'Doğa':
        'https://freesound.org/data/previews/266/266632_4929379-lq.mp3',
    'Doğa 2':
        'https://freesound.org/data/previews/528/528661_9498992-lq.mp3',
    'İnsan (Kafe)':
        'https://freesound.org/data/previews/482/482990_9954264-lq.mp3',
    'Yaz Gecesi':
        'https://freesound.org/data/previews/210/210540_3887148-lq.mp3',
  };

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.task.durationMinutes * 60;
    _remainingSeconds = _totalSeconds;
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isSoundPlaying = state == PlayerState.playing);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTimer());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
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
    final notifier = ref.read(completedTaskIdsProvider.notifier);
    notifier.state = {...notifier.state, widget.task.id};
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

  Future<void> _playSound() async {
    final url = _soundUrlMap[_selectedSound];
    if (url == null) return;
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(UrlSource(url));
    } catch (_) {}
  }

  Future<void> _stopSound() async {
    await _audioPlayer.stop();
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

  void _showSoundPicker() {
    final sounds = _soundUrlMap.keys.toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ListView.builder(
        itemCount: sounds.length,
        itemBuilder: (ctx, i) => ListTile(
          title: Text(sounds[i],
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 16)),
          trailing: sounds[i] == _selectedSound
              ? const Icon(Icons.check, color: AppColors.primary)
              : null,
          onTap: () {
            setState(() => _selectedSound = sounds[i]);
            Navigator.pop(ctx);
          },
        ),
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
        child: Column(children: [
          // ── Top bar ──────────────────────────────────────────────────
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
              ],
            ),
          ),

          // ── Title ────────────────────────────────────────────────────
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

          // ── Ambient sound card (study mode only) ─────────────────────
          if (!_isBreak)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(children: [
                  Row(children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.info,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.graphic_eq,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ortam Sesi',
                            style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w700)),
                        Text('Odaklanmana yardımcı olur',
                            style: TextStyle(
                                color: textSecondary, fontSize: 11)),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 10),
                  // Ses seçici dropdown
                  GestureDetector(
                    onTap: _showSoundPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Row(children: [
                        const Icon(Icons.queue_music,
                            color: textSecondary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_selectedSound,
                              style: const TextStyle(
                                  color: textPrimary, fontSize: 14)),
                        ),
                        const Icon(Icons.keyboard_arrow_down,
                            color: textSecondary, size: 18),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Başlat / Durdur butonları
                  Row(children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSoundPlaying ? null : _playSound,
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('Başlat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              const Color(0xFFF59E0B).withValues(alpha: 0.4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSoundPlaying ? _stopSound : null,
                        icon: const Icon(Icons.stop, size: 16),
                        label: const Text('Durdur'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade700,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              Colors.grey.shade700.withValues(alpha: 0.4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ]),
                ]),
              ),
            ),

          // ── Timer ring ───────────────────────────────────────────────
          Expanded(
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

          // ── Break card (break mode only) ─────────────────────────────
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

          const SizedBox(height: 16),

          // ── Mola / Bitir buttons ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(60, 0, 60, 24),
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
        ]),
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
