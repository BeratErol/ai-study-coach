import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_theme.dart';
import '../services/api_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  // Exam data
  List<Map<String, dynamic>> _exams           = [];
  List<Map<String, dynamic>> _lessonAverages  = [];
  bool _loadingExams = true;

  // Study session data
  int  _totalPomodoros = 0;
  int  _totalMinutes   = 0;
  List<double> _weeklyHours = List.filled(7, 0);
  bool _loadingSessions = true;

  // AI recommendation
  String _aiRec        = '';
  bool   _loadingAi    = true;

  // Date filter: null=all, 7=last week, 30=last month
  int? _filterDays;

  List<Map<String, dynamic>> get _filteredExams {
    if (_filterDays == null) return _exams;
    final cutoff = DateTime.now().subtract(Duration(days: _filterDays!));
    return _exams.where((e) {
      final d = DateTime.tryParse(e['date'] as String? ?? '');
      return d != null && d.isAfter(cutoff);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadExams(), _loadSessions(), _loadAiRec()]);
  }

  Future<void> _loadExams() async {
    try {
      final api = ApiService();
      final examsRes    = await api.dio.get('/Exam');
      final analysisRes = await api.dio.get('/Exam/analysis');

      final exams    = List<Map<String, dynamic>>.from(examsRes.data as List);
      final analysis = analysisRes.data as Map<String, dynamic>;
      final avgs     = List<Map<String, dynamic>>.from(
          analysis['lessonAverages'] as List? ?? []);

      if (mounted) setState(() { _exams = exams; _lessonAverages = avgs; _loadingExams = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingExams = false);
    }
  }

  Future<void> _loadSessions() async {
    try {
      final api = ApiService();
      final summaryRes  = await api.dio.get('/StudySession/summary');
      final sessionsRes = await api.dio.get('/StudySession');

      final totalMin  = (summaryRes.data['totalDurationMinutes'] as num?)?.toInt() ?? 0;
      final sessions  = List<Map<String, dynamic>>.from(sessionsRes.data as List);

      // Haftalık breakdown
      final weekly = List<double>.filled(7, 0);
      final now    = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      for (final s in sessions) {
        final d = DateTime.tryParse(s['date'] as String? ?? '');
        if (d != null && d.isAfter(weekStart)) {
          final idx = d.weekday - 1; // 0=Pzt
          weekly[idx] += ((s['durationMinutes'] as num?)?.toDouble() ?? 0) / 60;
        }
      }

      final pomodoroCount = sessions
          .where((s) => (s['type'] as String?) == 'pomodoro')
          .length;

      if (mounted) {
        setState(() {
          _totalMinutes    = totalMin;
          _totalPomodoros  = pomodoroCount;
          _weeklyHours     = weekly;
          _loadingSessions = false;
        });
      }
    } catch (_) {
      if (mounted) { setState(() => _loadingSessions = false); }
    }
  }

  Future<void> _loadAiRec() async {
    try {
      final res = await ApiService().dio.get('/Exam/recommendation');
      final rec = res.data['recommendation'] as String? ?? '';
      if (mounted) { setState(() { _aiRec = rec; _loadingAi = false; }); }
    } catch (_) {
      if (mounted) {
        setState(() {
          _aiRec = 'Deneme sonuçlarını girdikten sonra AI önerileri burada görünür.';
          _loadingAi = false;
        });
      }
    }
  }

  String _fmtHours(int minutes) {
    if (minutes < 60) return '${minutes}dk';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}s ${m}dk' : '${h}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İstatistikler')),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          setState(() {
            _loadingExams = _loadingSessions = _loadingAi = true;
          });
          await _loadAll();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Summary Cards ────────────────────────────────────────────
              Row(children: [
                Expanded(
                  child: _StatCard(
                    title: 'Toplam Pomodoro',
                    value: _loadingSessions ? '—' : '$_totalPomodoros',
                    icon: Icons.timer_rounded,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Toplam Çalışma',
                    value: _loadingSessions ? '—' : _fmtHours(_totalMinutes),
                    icon: Icons.trending_up_rounded,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Deneme Sayısı',
                    value: _loadingExams ? '—' : '${_exams.length}',
                    icon: Icons.assignment_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ]),
              const SizedBox(height: 28),

              // ── Weekly Bar Chart ─────────────────────────────────────────
              const Text('Haftalık Çalışma (saat)',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                  child: SizedBox(
                    height: 180,
                    child: _loadingSessions
                        ? const Center(child: CircularProgressIndicator())
                        : _WeeklyBarChart(weeklyHours: _weeklyHours),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Lesson Averages ──────────────────────────────────────────
              if (_lessonAverages.isNotEmpty) ...[
                const Text('Ders Ort. Netleri',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: _lessonAverages.map((a) {
                        final name = a['lessonName'] as String? ?? '';
                        final avg  = (a['averageNet'] as num?)?.toDouble() ?? 0;
                        final max  = 40.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  Text(avg.toStringAsFixed(1),
                                      style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: AppRadius.full,
                                child: LinearProgressIndicator(
                                  value: (avg / max).clamp(0.0, 1.0),
                                  minHeight: 7,
                                  backgroundColor:
                                      AppColors.primaryO10,
                                  color: avg < 10
                                      ? AppColors.error
                                      : avg < 20
                                          ? AppColors.warning
                                          : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // ── Date Filter Chips ────────────────────────────────────────
              Row(children: [
                _FilterChip(label: 'Tümü',     selected: _filterDays == null, onTap: () => setState(() => _filterDays = null)),
                const SizedBox(width: 8),
                _FilterChip(label: 'Son 30 gün', selected: _filterDays == 30, onTap: () => setState(() => _filterDays = 30)),
                const SizedBox(width: 8),
                _FilterChip(label: 'Son 7 gün', selected: _filterDays == 7,  onTap: () => setState(() => _filterDays = 7)),
              ]),
              const SizedBox(height: 24),

              // ── Pie Chart (lesson net distribution) ──────────────────────
              if (_lessonAverages.isNotEmpty) ...[
                const Text('Ders Net Dağılımı',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: SizedBox(
                      height: 200,
                      child: _LessonPieChart(lessonAverages: _lessonAverages),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // ── Trend Line Chart ─────────────────────────────────────────
              if (_filteredExams.length >= 2) ...[
                const Text('Net Trendi',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                    child: SizedBox(
                      height: 160,
                      child: _NetTrendChart(exams: _filteredExams),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // ── Recent Exams ─────────────────────────────────────────────
              const Text('Son Denemeler',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _loadingExams
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredExams.isEmpty
                      ? _EmptyExams()
                      : Column(
                          children: _filteredExams.take(5).map((e) {
                            final title   = e['title'] as String? ?? '';
                            final type    = e['type'] as String? ?? '';
                            final net     = (e['totalNet'] as num?)?.toDouble() ?? 0;
                            final dateStr = e['date'] as String? ?? '';
                            final date    = DateTime.tryParse(dateStr);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryO10,
                                    borderRadius: AppRadius.sm,
                                  ),
                                  child: const Icon(
                                      Icons.assignment_outlined,
                                      color: AppColors.primary,
                                      size: 20),
                                ),
                                title: Text(title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                subtitle: Text(
                                  '$type  •  ${date != null ? '${date.day}.${date.month}.${date.year}' : ''}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(net.toStringAsFixed(1),
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: net >= 20
                                                ? AppColors.success
                                                : net >= 10
                                                    ? AppColors.warning
                                                    : AppColors.error)),
                                    const Text('net',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textHint)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
              const SizedBox(height: 28),

              // ── AI Recommendation ────────────────────────────────────────
              const Text('AI Koç Önerisi',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4338CA), Color(0xFF6D28D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppRadius.lg,
                ),
                child: _loadingAi
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(children: [
                            Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Kişisel Öneri',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ]),
                          const SizedBox(height: 10),
                          Text(
                            _aiRec,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.5),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/exam/result'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_chart_rounded),
        label: const Text('Deneme Gir',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Weekly Bar Chart ──────────────────────────────────────────────────────────
class _WeeklyBarChart extends StatelessWidget {
  final List<double> weeklyHours;
  const _WeeklyBarChart({required this.weeklyHours});

  static const _days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  @override
  Widget build(BuildContext context) {
    final maxY = weeklyHours.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity) + 1;

    return BarChart(BarChartData(
      maxY: maxY,
      alignment: BarChartAlignment.spaceAround,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, a, rod, b) => BarTooltipItem(
            '${rod.toY.toStringAsFixed(1)}s',
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, meta) => SideTitleWidget(
              meta: meta,
              space: 6,
              child: Text(_days[v.toInt()],
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ),
        leftTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: AppColors.borderLight, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      barGroups: List.generate(7, (i) {
        final isToday = i == DateTime.now().weekday - 1;
        return BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: weeklyHours[i],
            color: isToday ? AppColors.secondary : AppColors.primary,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ]);
      }),
    ));
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: AppRadius.sm,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(title,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
                maxLines: 2),
          ],
        ),
      ),
    );
  }
}

// ── Filter Chip ───────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.primaryO10,
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

// ── Lesson Pie Chart ──────────────────────────────────────────────────────────
class _LessonPieChart extends StatelessWidget {
  final List<Map<String, dynamic>> lessonAverages;
  const _LessonPieChart({required this.lessonAverages});

  @override
  Widget build(BuildContext context) {
    final total = lessonAverages.fold<double>(
        0, (s, e) => s + ((e['averageNet'] as num?)?.toDouble() ?? 0));

    final sections = lessonAverages.asMap().entries.map((entry) {
      final i     = entry.key;
      final a     = entry.value;
      final net   = (a['averageNet'] as num?)?.toDouble() ?? 0;
      final color = AppColors.lessonColors[i % AppColors.lessonColors.length];
      return PieChartSectionData(
        value: net.clamp(0.1, double.infinity),
        color: color,
        radius: 60,
        title: net > 0 ? net.toStringAsFixed(0) : '',
        titleStyle: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
      );
    }).toList();

    return Row(children: [
      Expanded(
        flex: 3,
        child: PieChart(PieChartData(
          sections: sections,
          centerSpaceRadius: 36,
          sectionsSpace: 2,
        )),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Toplam',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text(total.toStringAsFixed(1),
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
            const SizedBox(height: 8),
            ...lessonAverages.asMap().entries.take(4).map((entry) {
              final i     = entry.key;
              final a     = entry.value;
              final name  = a['lessonName'] as String? ?? '';
              final color = AppColors.lessonColors[i % AppColors.lessonColors.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(name,
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              );
            }),
          ],
        ),
      ),
    ]);
  }
}

// ── Net Trend Line Chart ──────────────────────────────────────────────────────
class _NetTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> exams;
  const _NetTrendChart({required this.exams});

  @override
  Widget build(BuildContext context) {
    final sorted = [...exams]
      ..sort((a, b) {
        final da = DateTime.tryParse(a['date'] as String? ?? '') ?? DateTime(2000);
        final db = DateTime.tryParse(b['date'] as String? ?? '') ?? DateTime(2000);
        return da.compareTo(db);
      });
    final last5 = sorted.length > 5 ? sorted.sublist(sorted.length - 5) : sorted;
    final spots = last5.asMap().entries.map((e) {
      final net = (e.value['totalNet'] as num?)?.toDouble() ?? 0;
      return FlSpot(e.key.toDouble(), net);
    }).toList();

    final isImproving = spots.last.y >= spots.first.y;
    final lineColor   = isImproving ? AppColors.success : AppColors.error;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 10;

    return LineChart(LineChartData(
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: lineColor,
          barWidth: 3,
          dotData: FlDotData(
            getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
              radius: 5,
              color: lineColor,
              strokeWidth: 2,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: lineColor.withValues(alpha: 0.1),
          ),
        ),
      ],
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, meta) {
              final i = v.toInt();
              if (i < 0 || i >= last5.length) return const SizedBox.shrink();
              final d = DateTime.tryParse(last5[i]['date'] as String? ?? '');
              final label = d != null ? '${d.day}/${d.month}' : '';
              return SideTitleWidget(
                meta: meta,
                space: 6,
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary)),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            getTitlesWidget: (v, meta) => Text(v.toStringAsFixed(0),
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ),
        ),
        topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: AppColors.borderLight, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
            s.y.toStringAsFixed(1),
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          )).toList(),
        ),
      ),
    ));
  }
}

// ── Empty Exams ───────────────────────────────────────────────────────────────
class _EmptyExams extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryO05,
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.primaryO15),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.assignment_outlined,
            size: 40, color: AppColors.primaryO50),
        const SizedBox(height: 10),
        const Text('Henüz deneme girilmedi',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text(
          'Sağ alttaki butonu kullanarak deneme sonuçlarını ekle.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }
}
