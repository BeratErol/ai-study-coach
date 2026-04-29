import 'dart:async';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../services/api_service.dart';

class PomodoroScreen extends StatefulWidget {
  final int? lessonId;
  final String? lessonName;

  const PomodoroScreen({Key? key, this.lessonId, this.lessonName}) : super(key: key);

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  static const int workDuration = 25 * 60; // 25 minutes
  static const int breakDuration = 5 * 60; // 5 minutes

  int _timeLeft = workDuration;
  bool _isRunning = false;
  bool _isWorkSession = true;
  Timer? _timer;

  void _startTimer() {
    if (_timer != null) _timer!.cancel();
    setState(() {
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timer!.cancel();
          _isRunning = false;
          _handleSessionComplete();
        }
      });
    });
  }

  void _pauseTimer() {
    if (_timer != null) _timer!.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    if (_timer != null) _timer!.cancel();
    setState(() {
      _isRunning = false;
      _timeLeft = _isWorkSession ? workDuration : breakDuration;
    });
  }

  void _toggleSessionType() {
    setState(() {
      _isWorkSession = !_isWorkSession;
      _resetTimer();
    });
  }

  Future<void> _handleSessionComplete() async {
    // Play sound or vibrate here in a real app
    if (_isWorkSession) {
      // API Call
      try {
        final apiService = ApiService();
        // Use lessonId if provided, else use a placeholder like 1
        await apiService.dio.post('/StudySession', data: {
          'topicId': widget.lessonId ?? 1,
          'durationMinutes': 25,
          'type': 'pomodoro',
          'date': DateTime.now().toUtc().toIso8601String()
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tebrikler! Bir pomodoro tamamladınız. Veri backend’e gönderildi.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Oturum tamamlandı ancak backend’e kaydedilemedi.')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    if (_timer != null) _timer!.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    double percent = _timeLeft / (_isWorkSession ? workDuration : breakDuration);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Pomodoro Odası', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.lessonName != null) ...[
                Text(
                  'Çalışılan Ders: ${widget.lessonName}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // Session Type Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleButton('Çalışma', _isWorkSession),
                    _buildToggleButton('Mola', !_isWorkSession),
                  ],
                ),
              ),
              const SizedBox(height: 60),

              // Circular Timer
              CircularPercentIndicator(
                radius: 120.0,
                lineWidth: 15.0,
                percent: percent,
                center: Text(
                  _formatTime(_timeLeft),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                progressColor: _isWorkSession ? Colors.blueAccent : Colors.green,
                backgroundColor: Colors.grey.shade300,
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
                animateFromLastPercent: true,
              ),
              const SizedBox(height: 60),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    heroTag: 'reset',
                    onPressed: _resetTimer,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 2,
                    child: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 24),
                  FloatingActionButton.large(
                    heroTag: 'play_pause',
                    onPressed: _isRunning ? _pauseTimer : _startTimer,
                    backgroundColor: _isRunning ? Colors.orange : Colors.blueAccent,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    child: Icon(_isRunning ? Icons.pause : Icons.play_arrow, size: 36),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (!isSelected) _toggleSessionType();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? (_isWorkSession ? Colors.blueAccent : Colors.green) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
