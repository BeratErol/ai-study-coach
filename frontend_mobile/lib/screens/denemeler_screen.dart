import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../data/exam_type_data.dart';
import '../models/subject_data.dart';
import '../providers/study_plan_provider.dart';
import '../services/api_service.dart';
import '../widgets/quick_note_sheet.dart';

// ── Provider ─────────────────────────────────────────────────────────────────

final examsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiService().dio.get('/Exam');
  return List<Map<String, dynamic>>.from(res.data as List);
});

// ── Palette ──────────────────────────────────────────────────────────────────

const _kRed1 = Color(0xFFC0392B);
const _kRed2 = Color(0xFFE74C3C);
const _kChartColors = [
  Color(0xFF5B5FC7),
  Color(0xFF10B981),
  Color(0xFFEF4444),
  Color(0xFFF59E0B),
  Color(0xFF8B5CF6),
];

// ── Helpers ──────────────────────────────────────────────────────────────────

List<Map<String, dynamic>> _sortByDate(List<Map<String, dynamic>> exams) {
  final copy = [...exams];
  copy.sort((a, b) {
    final da = DateTime.tryParse(a['date'] as String? ?? '') ?? DateTime(0);
    final db = DateTime.tryParse(b['date'] as String? ?? '') ?? DateTime(0);
    return da.compareTo(db);
  });
  return copy;
}

double _getDetailNet(Map<String, dynamic> exam, String lessonName) {
  final details = exam['details'] as List<dynamic>? ?? [];
  for (final d in details) {
    if ((d['lessonName'] as String?) == lessonName) {
      return (d['net'] as num?)?.toDouble() ?? 0.0;
    }
  }
  return 0.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class DenemeScreen extends ConsumerStatefulWidget {
  const DenemeScreen({super.key});

  @override
  ConsumerState<DenemeScreen> createState() => _DenemeScreenState();
}

class _DenemeScreenState extends ConsumerState<DenemeScreen> {
  // null → ilk tür otomatik seçili (Tümü yok)
  String? _filterType;

  void _openNote() {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => QuickNoteSheet(messenger: messenger),
    );
  }

  // Computed in build() via ref.watch, cached here for callbacks
  List<ExamTypeInfo> _cachedAvailableTypes = kExamTypes;
  List<LessonSlot> _cachedBransBranchLessons = [];

  List<ExamTypeInfo> _computeAvailableTypes(String exam, String area) {
    if (exam == 'OKUL_SINAVI' || exam == 'OKULSINAVI') {
      // OkulSinavi: single dynamic type built from user's subjects
      return [_okulSinaviType];
    }
    List<String> allowed;
    if (exam == 'YKS') {
      if (area.contains('SAYISAL')) {
        allowed = ['TYT', 'AYT_SAYISAL', 'BRANS'];
      } else if (area.contains('EŞİT') || area.contains('ESIT') || area.contains('EA')) {
        allowed = ['TYT', 'AYT_EA', 'BRANS'];
      } else if (area.contains('SÖZEL') || area.contains('SOZEL')) {
        allowed = ['TYT', 'AYT_SOZEL', 'BRANS'];
      } else if (area.contains('DİL') || area.contains('DIL')) {
        allowed = ['TYT', 'AYT_DIL', 'BRANS'];
      } else {
        allowed = ['TYT', 'AYT_SAYISAL', 'AYT_EA', 'AYT_SOZEL', 'AYT_DIL', 'BRANS'];
      }
    } else if (exam == 'TYT') {
      allowed = ['TYT'];
    } else if (exam == 'AYT') {
      allowed = ['AYT_SAYISAL', 'AYT_EA', 'AYT_SOZEL', 'AYT_DIL', 'BRANS'];
    } else if (exam == 'YDT') {
      allowed = ['AYT_DIL'];
    } else if (exam == 'KPSS') {
      allowed = ['KPSS_LISANS', 'BRANS'];
    } else if (exam == 'LGS') {
      allowed = ['LGS', 'BRANS'];
    } else if (exam == 'ALES') {
      allowed = ['ALES'];
    } else if (exam == 'YDS') {
      allowed = ['YDS'];
    } else if (exam == 'ÖĞRETMENLIK' || exam == 'OGRETMENLIK' || exam == 'ÖĞRETMENLİK') {
      allowed = ['AGS', 'OABT'];
    } else {
      // Bilinmeyen sınav — "tüm türleri göster" fallback'i yok.
      return const [];
    }
    return kExamTypes.where((t) => allowed.contains(t.apiType)).toList();
  }

  // Placeholder — rebuilt from onboarding data in build()
  ExamTypeInfo _okulSinaviType = const ExamTypeInfo(
    displayName: 'Sınav Denemesi',
    apiType: 'OKUL_SINAVI',
    lessons: [],
  );

  List<LessonSlot> _computeBransBranchLessons(List<ExamTypeInfo> types) {
    final seen = <String>{};
    final lessons = <LessonSlot>[];
    for (final t in types) {
      if (t.apiType == 'BRANS') continue;
      for (final l in t.lessons) {
        if (seen.add(l.name)) lessons.add(l);
      }
    }
    if (lessons.isEmpty) {
      return kExamTypes
          .firstWhere((t) => t.apiType == 'BRANS',
              orElse: () => kExamTypes.first)
          .lessons;
    }
    return lessons;
  }

  void _showAddModal() {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExamFormSheet(
        messenger: messenger,
        availableTypes: _cachedAvailableTypes,
        bransBranchLessons: _cachedBransBranchLessons,
        onSaved: () => ref.invalidate(examsProvider),
      ),
    );
  }

  void _showEditModal(Map<String, dynamic> exam) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExamFormSheet(
        existing: exam,
        messenger: messenger,
        availableTypes: _cachedAvailableTypes,
        bransBranchLessons: _cachedBransBranchLessons,
        onSaved: () => ref.invalidate(examsProvider),
      ),
    );
  }

  void _showComparisonModal(
      List<Map<String, dynamic>> exams, ExamTypeInfo? typeInfo) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ComparisonSheet(exams: exams, typeInfo: typeInfo),
    );
  }

  Future<void> _deleteExam(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Denemeyi Sil'),
        content: const Text('Bu deneme sonucunu silmek istediğinden emin misin?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService().dio.delete('/Exam/$id');
      ref.invalidate(examsProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silme işlemi başarısız.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final examsAsync = ref.watch(examsProvider);

    // Onboarding verisini watch ile al → her zaman güncel tür listesi
    final onboarding = ref.watch(onboardingDataProvider).value;
    final exam = onboarding?.targetExam.toUpperCase() ?? '';
    final area = onboarding?.selectedArea ?? '';

    // OkulSinavi: kullanıcının derslerinden dinamik tür oluştur
    if (onboarding != null && onboarding.targetExam == 'OkulSinavi') {
      final baseSubjects = area == 'uni_diger'
          ? <SubjectData>[]
          : getSubjectsForExam(onboarding.targetExam, onboarding.selectedArea);
      final baseNames = baseSubjects.map((s) => s.name).toSet();
      final extras = onboarding.customSubjects.where((n) => !baseNames.contains(n));
      final allSubjects = [...baseSubjects.map((s) => s.name), ...extras];
      _okulSinaviType = ExamTypeInfo(
        displayName: 'Sınav/Çıkmış Denemesi',
        apiType: 'OKUL_SINAVI',
        lessons: allSubjects.map((n) => LessonSlot(n, 20)).toList(),
      );
    }

    _cachedAvailableTypes = _computeAvailableTypes(exam.toUpperCase(), area.toUpperCase());
    _cachedBransBranchLessons = _computeBransBranchLessons(_cachedAvailableTypes);

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: GestureDetector(
        onTap: _openNote,
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: Color(0xFFF97316),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
          ),
          child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
        ),
      ),
      body: examsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (rawExams) {
          // Sınava ait olmayan eski deneme kayıtlarını gizle.
          final allowedApi = _cachedAvailableTypes.map((t) => t.apiType).toSet();
          final allExams = rawExams
              .where((e) => allowedApi.contains(e['type'] as String? ?? ''))
              .toList();
          if (allExams.isEmpty) return _EmptyBody(onAdd: _showAddModal);

          // Mevcut türler (sadece gerçekte var olanlar)
          final types = allExams
              .map((e) => e['type'] as String? ?? '')
              .where((t) => t.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

          // İlk yüklemede ilk türü otomatik seç. Önceki seçim bu sınava ait
          // değilse de düşür.
          if (_filterType == null || !types.contains(_filterType)) {
            _filterType = types.isNotEmpty ? types.first : null;
          }

          // Filtre uygula
          final filtered = _filterType == null
              ? <Map<String, dynamic>>[]
              : allExams.where((e) => (e['type'] as String?) == _filterType).toList();

          final isBrans = _filterType == 'BRANS';

          // Seçili tür için ExamTypeInfo bul (radar için — BRANS'ta kullanılmaz)
          final selectedTypeInfo = (!isBrans && _filterType != null)
              ? kExamTypes.where((t) => t.apiType == _filterType).firstOrNull
              : null;

          // BRANS: ders adına göre grupla
          final Map<String, List<Map<String, dynamic>>> bransGroups = {};
          if (isBrans) {
            for (final exam in filtered) {
              final details = exam['details'] as List<dynamic>? ?? [];
              final lessonName = details.isNotEmpty
                  ? (details.first['lessonName'] as String? ?? 'Diğer')
                  : 'Diğer';
              bransGroups.putIfAbsent(lessonName, () => []).add(exam);
            }
          }

          return CustomScrollView(
            slivers: [
              // ── Header ──
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_kRed1, _kRed2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('📝 Denemelerim',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text('${allExams.length} deneme sonucu',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showAddModal,
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text('Deneme Sonucu Ekle',
                                style: TextStyle(fontSize: 15)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 13),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Filtre chipları (Tümü yok, sadece mevcut türler) ──
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    children: types.map((t) {
                      final displayName = kExamTypes
                          .where((x) => x.apiType == t)
                          .map((x) => x.displayName)
                          .firstOrNull ?? t;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: displayName,
                          selected: _filterType == t,
                          onTap: () => setState(() => _filterType = t),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // ── BRANS: ders grupları ──
              if (isBrans)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final lessonName = bransGroups.keys.elementAt(i);
                      final groupExams = bransGroups[lessonName]!;
                      return _BransLessonSection(
                        lessonName: lessonName,
                        exams: groupExams,
                        onEdit: _showEditModal,
                        onDelete: _deleteExam,
                        onCompare: _showComparisonModal,
                      );
                    },
                    childCount: bransGroups.length,
                  ),
                ),

              // ── Normal türler: istatistik + trend + radar + koç + karşılaştırma ──
              if (!isBrans) ...[
                // İstatistik kartı
                if (filtered.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _NetSummaryCard(exams: filtered, filterType: _filterType),
                  ),

                // Trend grafiği veya uyarı
                SliverToBoxAdapter(
                  child: filtered.length >= 2
                      ? _TrendChart(exams: filtered)
                      : Builder(builder: (ctx) => Container(
                          margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Theme.of(ctx).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  color: Color(0xFF9CA3AF), size: 22),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Net Trend grafiği için en az 2 deneme gerekli.',
                                  style: TextStyle(
                                      color: Color(0xFF6B7280), fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        )),
                ),

                // Radar
                if (filtered.isNotEmpty && selectedTypeInfo != null &&
                    selectedTypeInfo.lessons.length >= 3)
                  SliverToBoxAdapter(
                    child: _RadarCard(
                      exams: _sortByDate(filtered).reversed
                          .take(3)
                          .toList()
                          .reversed
                          .toList(),
                      typeInfo: selectedTypeInfo,
                    ),
                  ),

                // Koç analizi
                if (filtered.length >= 3)
                  SliverToBoxAdapter(
                    child: _CoachCard(exams: filtered),
                  ),

                // Karşılaştırma butonu
                if (filtered.length >= 2)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showComparisonModal(filtered, selectedTypeInfo),
                        icon: const Icon(Icons.compare_arrows_rounded, size: 22),
                        label: const Text('Deneme Karşılaştırması Yap',
                            style: TextStyle(fontSize: 15)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),

                // Liste başlığı
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 22, 16, 10),
                    child: Text('Geçmiş Denemeler',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 18)),
                  ),
                ),

                // Deneme kartları
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final exam = filtered[i];
                      return _ExamListCard(
                        exam: exam,
                        onEdit: () => _showEditModal(exam),
                        onDelete: () => _deleteExam(exam['id'] as int),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// BRANS LESSON SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _BransLessonSection extends StatelessWidget {
  final String lessonName;
  final List<Map<String, dynamic>> exams;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(int) onDelete;
  final void Function(List<Map<String, dynamic>>, ExamTypeInfo?) onCompare;

  const _BransLessonSection({
    required this.lessonName,
    required this.exams,
    required this.onEdit,
    required this.onDelete,
    required this.onCompare,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = _sortByDate(exams);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Bölüm başlığı ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Branş — $lessonName',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 17),
                ),
              ),
              Text('${exams.length} deneme',
                  style: const TextStyle(
                      color: Color(0xFF9CA3AF), fontSize: 13)),
            ],
          ),
        ),

        // ── Özet kartı ──
        _NetSummaryCard(exams: exams, filterType: null, labelOverride: lessonName),

        // ── Trend grafiği ──
        if (sorted.length >= 2)
          _TrendChart(exams: sorted)
        else
          Builder(builder: (ctx) => Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(ctx).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: Color(0xFF9CA3AF), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Net Trend için en az 2 deneme gerekli.',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                  ),
                ),
              ],
            ),
          )),

        // ── Koç analizi ──
        if (sorted.length >= 3) _CoachCard(exams: sorted),

        // ── Karşılaştırma butonu ──
        if (sorted.length >= 2)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => onCompare(sorted, null),
                icon: const Icon(Icons.compare_arrows_rounded, size: 22),
                label: const Text('Deneme Karşılaştırması Yap',
                    style: TextStyle(fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),

        // ── Deneme kartları ──
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Text('Geçmiş Denemeler',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ),
        ...sorted.map((exam) => _ExamListCard(
              exam: exam,
              onEdit: () => onEdit(exam),
              onDelete: () => onDelete(exam['id'] as int),
            )),

        // ── Ayraç ──
        const Divider(
            height: 32, thickness: 1, indent: 16, endIndent: 16,
            color: Color(0xFFE5E7EB)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY BODY
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyBody extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyBody({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [_kRed1, _kRed2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Column(
                children: [
                  const Text('📝', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 8),
                  const Text('Denemelerim',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Henüz deneme sonucu eklenmedi',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 14)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Deneme Sonucu Ekle',
                        style: TextStyle(fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.help_outline_rounded,
                    size: 72, color: Color(0xFFD1D5DB)),
                SizedBox(height: 14),
                Text(
                  'Deneme sonuçlarını ekleyerek\ngelişimini takip et!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER CHIP
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.primary : Theme.of(context).dividerColor),
        ),
        child: Text(
          selected ? '✓ $label' : label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NET SUMMARY CARD
// ─────────────────────────────────────────────────────────────────────────────

class _NetSummaryCard extends StatelessWidget {
  final List<Map<String, dynamic>> exams;
  final String? filterType;
  final String? labelOverride;
  const _NetSummaryCard({required this.exams, this.filterType, this.labelOverride});

  @override
  Widget build(BuildContext context) {
    final nets = exams
        .map((e) => (e['totalNet'] as num?)?.toDouble() ?? 0.0)
        .toList();
    final maxNet = nets.reduce((a, b) => a > b ? a : b);
    final minNet = nets.reduce((a, b) => a < b ? a : b);
    final avg = nets.reduce((a, b) => a + b) / nets.length;
    final isOkul = filterType == 'OKUL_SINAVI';
    final displayName = labelOverride ??
        (filterType != null
            ? (kExamTypes.where((t) => t.apiType == filterType).firstOrNull?.displayName ?? filterType!)
            : 'Genel');
    final scoreLabel = isOkul ? 'Puan' : 'Net';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📊 $displayName — $scoreLabel Özeti',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatBox(
                  value: maxNet.toStringAsFixed(isOkul ? 0 : 1),
                  label: 'En Yüksek',
                  arrow: '↑',
                  color: const Color(0xFF10B981)),
              const SizedBox(width: 10),
              _StatBox(
                  value: minNet.toStringAsFixed(isOkul ? 0 : 1),
                  label: 'En Düşük',
                  arrow: '↓',
                  color: const Color(0xFFEF4444)),
              const SizedBox(width: 10),
              _StatBox(
                  value: avg.toStringAsFixed(isOkul ? 0 : 1),
                  label: 'Ortalama',
                  arrow: '→',
                  color: const Color(0xFF3B82F6)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final String arrow;
  final Color color;
  const _StatBox(
      {required this.value,
      required this.label,
      required this.arrow,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text('$arrow $value',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 17)),
            const SizedBox(height: 3),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF6B7280), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TREND CHART
// ─────────────────────────────────────────────────────────────────────────────

class _TrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> exams;
  const _TrendChart({required this.exams});

  @override
  Widget build(BuildContext context) {
    final sorted = _sortByDate(exams);
    final nets = sorted
        .map((e) => (e['totalNet'] as num?)?.toDouble() ?? 0.0)
        .toList();
    final n = nets.length;

    // Gerçek net çizgisi
    final spots = nets.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    // Kayan ortalama seviye çizgisi:
    // i. noktadaki seviye = nets[0..i] ortalaması
    final levelSpots = <FlSpot>[];
    double runningSum = 0;
    for (var i = 0; i < n; i++) {
      runningSum += nets[i];
      levelSpots.add(FlSpot(i.toDouble(), runningSum / (i + 1)));
    }

    final allValues = [...nets, ...levelSpots.map((s) => s.y)];
    final minY = (allValues.reduce((a, b) => a < b ? a : b) - 5).clamp(0, 999).toDouble();
    final maxY = allValues.reduce((a, b) => a > b ? a : b) + 5;

    // Ortalama net (summary card ile aynı)
    final avgNet = nets.reduce((a, b) => a + b) / n;


    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📈 Net Trend',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(width: 18, height: 3, color: AppColors.primary),
              const SizedBox(width: 5),
              const Text('Gerçek Net',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              const SizedBox(width: 14),
              Container(width: 18, height: 2, color: const Color(0xFF9CA3AF)),
              const SizedBox(width: 5),
              const Text('Kayan Ortalama',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                clipData: FlClipData.none(),
                minX: -0.2,
                maxX: n - 1 + 0.2,
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                      color: const Color(0xFFF3F4F6), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, _) => Text(
                        v.toStringAsFixed(0),
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9CA3AF)),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        // Only show at integer positions
                        if (v != i.toDouble()) return const SizedBox.shrink();
                        if (i < 0 || i >= sorted.length) {
                          return const SizedBox.shrink();
                        }
                        final dt = DateTime.tryParse(
                            sorted[i]['date'] as String? ?? '');
                        if (dt == null) return const SizedBox.shrink();
                        final label = DateFormat('dd/MM').format(dt);
                        // Hide if same date as previous point
                        // but always show the last point when there are only 2
                        final isLast = i == sorted.length - 1;
                        if (i > 0 && !isLast) {
                          final prev = DateTime.tryParse(
                              sorted[i - 1]['date'] as String? ?? '');
                          if (prev != null &&
                              DateFormat('dd/MM').format(prev) == label) {
                            return const SizedBox.shrink();
                          }
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Transform.rotate(
                            angle: -0.5,
                            child: Text(
                              label,
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xFF9CA3AF)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, xPerc, yPerc, idx) =>
                          FlDotCirclePainter(
                              radius: 5,
                              color: AppColors.primary,
                              strokeWidth: 2,
                              strokeColor: Colors.white),
                    ),
                  ),
                  LineChartBarData(
                    spots: levelSpots,
                    isCurved: true,
                    color: const Color(0xFF9CA3AF),
                    barWidth: 2,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    maxContentWidth: 180,
                    getTooltipColor: (_) => const Color(0xFF1F2937),
                    getTooltipItems: (touchedSpots) {
                      // Sadece birinci çizginin tooltip'ini göster
                      final realSpot = touchedSpots
                          .where((s) => s.barIndex == 0)
                          .firstOrNull;
                      if (realSpot == null) return touchedSpots.map((_) => null).toList();

                      final idx = realSpot.x.toInt();
                      final exam = sorted[idx];
                      final title = (exam['title'] as String?)?.isNotEmpty == true
                          ? exam['title'] as String
                          : DateFormat('dd.MM.yyyy').format(
                              DateTime.tryParse(exam['date'] as String? ?? '') ??
                                  DateTime.now());
                      final realNet = realSpot.y;
                      final levelNet = levelSpots[idx].y;

                      return touchedSpots.map((s) {
                        if (s.barIndex != 0) return null;
                        return LineTooltipItem(
                          '$title\nGerçek Net: ${realNet.toStringAsFixed(1)}\nSeviye: ${levelNet.toStringAsFixed(1)}',
                          const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              height: 1.5),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Genel ortalama: ${avgNet.toStringAsFixed(1)} Net',
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RADAR CARD — her deneme türü için, ders listesi ExamTypeInfo'dan
// ─────────────────────────────────────────────────────────────────────────────

class _RadarCard extends StatefulWidget {
  final List<Map<String, dynamic>> exams;
  final ExamTypeInfo typeInfo;
  const _RadarCard({required this.exams, required this.typeInfo});

  @override
  State<_RadarCard> createState() => _RadarCardState();
}

class _RadarCardState extends State<_RadarCard> {
  int _selectedLessonIdx = 0;

  String _examTitle(Map<String, dynamic> exam, int idx) {
    final t = (exam['title'] as String?)?.trim() ?? '';
    return t.isNotEmpty ? t : 'Deneme ${idx + 1}';
  }

  String _shortLesson(String name) {
    final prefix = '${widget.typeInfo.displayName.split(' ').first} ';
    return name.replaceAll(prefix, '');
  }

  @override
  Widget build(BuildContext context) {
    final lessons = widget.typeInfo.lessons;
    final exams = widget.exams;

    // Legend row — deneme adı + renk + tarih
    Widget legendRow = Wrap(
      spacing: 14,
      runSpacing: 6,
      children: exams.asMap().entries.map((entry) {
        final color = _kChartColors[entry.key % _kChartColors.length];
        final title = _examTitle(entry.value, entry.key);
        final date = DateTime.tryParse(entry.value['date'] as String? ?? '');
        final dateStr = date != null ? DateFormat('dd.MM').format(date) : '';
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 12,
                height: 12,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(
              '$title${dateStr.isNotEmpty ? " ($dateStr)" : ""}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Text('🎯 ${widget.typeInfo.displayName} Denge Radarı',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 10),

          // Legend grafiğin ÜSTÜNDE
          legendRow,
          const SizedBox(height: 22),

          // Radar — ders etiketleri Stack ile köşelere manuel yerleştirilir
          _RadarWithLabels(
            lessons: lessons,
            exams: exams,
            shortLesson: _shortLesson,
          ),

          const SizedBox(height: 28),

          // Tıklanabilir ders chip'leri
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: lessons.asMap().entries.map((entry) {
              final i = entry.key;
              final isSelected = _selectedLessonIdx == i;
              final shortName = _shortLesson(entry.value.name);
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedLessonIdx = i;
                }),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1F2937)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    shortName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF374151),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // Seçili derse ait denemeler — renkli satırlar
          ...[
            const SizedBox(height: 18),
            ...exams.asMap().entries.map((entry) {
              final examIdx = entry.key;
              final exam = entry.value;
              final color = _kChartColors[examIdx % _kChartColors.length];
              final lesson = lessons[_selectedLessonIdx];
              final net = _getDetailNet(exam, lesson.name);
              final title = _examTitle(exam, examIdx);
              final date =
                  DateTime.tryParse(exam['date'] as String? ?? '');
              final dateStr =
                  date != null ? DateFormat('dd.MM').format(date) : '';
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: color.withValues(alpha: 0.35), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$title${dateStr.isNotEmpty ? " ($dateStr)" : ""}',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: color),
                      ),
                    ),
                    Text(
                      '${net.toStringAsFixed(1)} net',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// RADAR WITH LABELS — köşelere manuel etiket yerleştirme
// ─────────────────────────────────────────────────────────────────────────────

class _RadarWithLabels extends StatelessWidget {
  final List<LessonSlot> lessons;
  final List<Map<String, dynamic>> exams;
  final String Function(String) shortLesson;

  const _RadarWithLabels({
    required this.lessons,
    required this.exams,
    required this.shortLesson,
  });

  // Etiket widget'ı — max 1 satır, sığmazsa ...
  Widget _label(BuildContext context, String text, {TextAlign align = TextAlign.center}) => Text(
        text,
        textAlign: align,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      );

  @override
  Widget build(BuildContext context) {
    // fl_chart: radius = min(w,h)/2 * 0.8
    // Grafik alanı etrafına etiket için padding bırakıyoruz.
    // Üst/alt: vPad, Sağ/Sol: hPad
    const double vPad = 18.0; // üst ve alt etiket için
    const double hPad = 48.0; // sağ ve sol etiket için (daha geniş metin)
    const double chartH = 240.0; // grafik yüksekliği (etiket padding hariç)
    const double totalH = chartH + vPad * 2;

    final int n = lessons.length;
    // Açı: angle[i] = 2π/n * i − π/2
    // Her ders için yön belirle: top/bottom/left/right ya da köşe
    // Yön threshold: |sin| > 0.7 → üst/alt, |cos| > 0.7 → sağ/sol, diğer → köşe

    // Etiketleri yönlerine göre konumlandır
    final labels = List.generate(n, (i) {
      final double angle = (2 * math.pi / n) * i - math.pi / 2;
      final double cosA = math.cos(angle);
      final double sinA = math.sin(angle);
      return (angle: angle, cosA: cosA, sinA: sinA, name: shortLesson(lessons[i].name));
    });

    return SizedBox(
      height: totalH,
      child: Stack(
        children: [
          // Radar grafiği — vPad boşluklu, tam genişlik
          Positioned(
            top: vPad,
            left: hPad,
            right: hPad,
            height: chartH,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                tickCount: 4,
                ticksTextStyle: const TextStyle(fontSize: 0),
                radarBorderData:
                    const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                gridBorderData:
                    const BorderSide(color: Color(0xFFF3F4F6), width: 1),
                getTitle: (i, _) => const RadarChartTitle(text: ''),
                radarTouchData: RadarTouchData(enabled: false),
                dataSets: exams.asMap().entries.map((entry) {
                  final color =
                      _kChartColors[entry.key % _kChartColors.length];
                  final values = lessons
                      .map((l) => _getDetailNet(entry.value, l.name))
                      .toList();
                  return RadarDataSet(
                    fillColor: color.withValues(alpha: 0.15),
                    borderColor: color,
                    borderWidth: 2.5,
                    entryRadius: 5,
                    dataEntries:
                        values.map((v) => RadarEntry(value: v)).toList(),
                  );
                }).toList(),
              ),
              duration: Duration.zero,
            ),
          ),

          // Etiketler: her köşe için ayrı bir konum hesaplanır.
          // fl_chart radar polygon vertex'leri ile aynı açılarda; merkez
          // (W/2, vPad + chartH/2), yarıçap min((W-2*hPad)/2, chartH/2)*0.8.
          // LayoutBuilder ile gerçek genişliği alıp her etiketi vertex'in
          // yanına yerleştiriyoruz, böylece çakışma olmuyor.
          LayoutBuilder(builder: (ctx, c) {
            final double w = c.maxWidth;
            final double cx = w / 2;
            final double cy = vPad + chartH / 2;
            // fl_chart polygon radar etkili yarıçap (~0.85 deneysel).
            final double r = math.min((w - 2 * hPad) / 2, chartH / 2) * 0.92;
            const double labelW = 90;
            const double labelH = 22;
            return Stack(
              children: labels.map((l) {
                final double vx = cx + r * l.cosA;
                final double vy = cy + r * l.sinA;
                // Etiket merkezini vertex'in biraz dışına it: yatay offset
                // cos*8, dikey offset sin*10 piksel.
                final double tx = vx + l.cosA * 4;
                final double ty = vy + l.sinA * 6;
                // Pozitif left/top hesabı için merkezden offset
                final double left = (tx - labelW / 2).clamp(0.0, w - labelW);
                final double top = (ty - labelH / 2).clamp(0.0, totalH - labelH);
                // Yatay hizalama: sağdaki vertex'ler sol-hizalı, sol vertex'ler sağ-hizalı,
                // üst/alt orta vertex'ler centered.
                TextAlign align = TextAlign.center;
                if (l.cosA > 0.3) {
                  align = TextAlign.left;
                } else if (l.cosA < -0.3) {
                  align = TextAlign.right;
                }
                return Positioned(
                  left: left,
                  top: top,
                  width: labelW,
                  height: labelH,
                  child: Align(
                    alignment: align == TextAlign.left
                        ? Alignment.centerLeft
                        : align == TextAlign.right
                            ? Alignment.centerRight
                            : Alignment.center,
                    child: _label(context, l.name, align: align),
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}

// COACH CARD — tarih sırasına göre
// ─────────────────────────────────────────────────────────────────────────────

class _CoachCard extends StatelessWidget {
  final List<Map<String, dynamic>> exams;
  const _CoachCard({required this.exams});

  @override
  Widget build(BuildContext context) {
    final sorted = _sortByDate(exams);
    final last3 = sorted.length > 3 ? sorted.sublist(sorted.length - 3) : sorted;

    final lessons = <String>{};
    for (final e in last3) {
      for (final d in (e['details'] as List<dynamic>? ?? [])) {
        lessons.add(d['lessonName'] as String? ?? '');
      }
    }
    lessons.remove('');

    final insights = <_Insight>[];
    for (final lesson in lessons) {
      final nets = last3.map((e) {
        final details = e['details'] as List<dynamic>? ?? [];
        for (final d in details) {
          if ((d['lessonName'] as String?) == lesson) {
            return (d['net'] as num?)?.toDouble() ?? 0.0;
          }
        }
        return 0.0;
      }).toList();

      if (nets.length < 2) continue;
      final netStr = nets.map((n) => n.toStringAsFixed(1)).join(' → ');

      if (nets.length >= 3 && nets[0] < nets[1] && nets[1] < nets[2]) {
        insights.add(_Insight(
          lesson: lesson,
          text: '🎉 $lesson netiniz son 3 denemede sürekli artıyor ($netStr). Harika ilerleme, böyle devam!',
          isPositive: true,
          isGreat: true,
        ));
      } else if (nets.last > nets.first) {
        insights.add(_Insight(
          lesson: lesson,
          text: '📈 $lesson netiniz artış gösterdi ($netStr). İyi gidiyorsunuz, devam et!',
          isPositive: true,
          isGreat: false,
        ));
      } else if (nets.last < nets.first) {
        insights.add(_Insight(
          lesson: lesson,
          text: '📉 $lesson netiniz düşüş gösterdi ($netStr). Bu derse daha fazla vakit ayırmanı öneririz.',
          isPositive: false,
          isGreat: false,
        ));
      }
    }

    if (insights.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.school_rounded, color: Color(0xFF3B82F6), size: 22),
              SizedBox(width: 8),
              Text('Koç Analizi',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 17)),
            ],
          ),
          const SizedBox(height: 12),
          ...insights.map((ins) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ins.isPositive
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  ins.text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: ins.isPositive
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC62828),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _Insight {
  final String lesson;
  final String text;
  final bool isPositive;
  final bool isGreat;
  const _Insight(
      {required this.lesson,
      required this.text,
      required this.isPositive,
      required this.isGreat});
}

// ─────────────────────────────────────────────────────────────────────────────
// EXAM LIST CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ExamListCard extends StatelessWidget {
  final Map<String, dynamic> exam;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ExamListCard(
      {required this.exam, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final title = (exam['title'] as String?)?.isNotEmpty == true
        ? exam['title'] as String
        : exam['type'] as String? ?? 'Deneme';
    final date = DateTime.tryParse(exam['date'] as String? ?? '');
    final dateStr = date != null ? DateFormat('dd.MM.yyyy').format(date) : '-';
    final net = (exam['totalNet'] as num?)?.toDouble() ?? 0.0;
    final isOkul = (exam['type'] as String?) == 'OKUL_SINAVI';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(dateStr,
                    style: const TextStyle(
                        color: Color(0xFF9CA3AF), fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isOkul ? '${net.toStringAsFixed(0)} Puan' : '${net.toStringAsFixed(1)} Net',
              style: const TextStyle(
                  color: Color(0xFF166534),
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.edit_rounded,
                color: Color(0xFF3B82F6), size: 22),
            onPressed: onEdit,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error, size: 22),
            onPressed: onDelete,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXAM FORM SHEET (Ekle / Düzenle)
// ─────────────────────────────────────────────────────────────────────────────

class _ExamFormSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;
  final ScaffoldMessengerState messenger;
  final List<ExamTypeInfo> availableTypes;
  final List<LessonSlot> bransBranchLessons;
  const _ExamFormSheet({
    this.existing,
    required this.onSaved,
    required this.messenger,
    required this.availableTypes,
    required this.bransBranchLessons,
  });

  @override
  ConsumerState<_ExamFormSheet> createState() => _ExamFormSheetState();
}

class _ExamFormSheetState extends ConsumerState<_ExamFormSheet> {
  final _titleCtrl = TextEditingController();
  ExamTypeInfo? _selectedType;
  LessonSlot? _selectedBransLesson;
  DateTime _date = DateTime.now();
  final Map<String, TextEditingController> _correctCtrls = {};
  final Map<String, TextEditingController> _wrongCtrls = {};
  final Map<String, TextEditingController> _maxQCtrls = {};
  bool _saving = false;

  LessonSlot? _selectedOkulLesson;

  bool get _isBrans => _selectedType?.apiType == 'BRANS';
  bool get _isOkulSinavi => _selectedType?.apiType == 'OKUL_SINAVI';

  // Deneme adı için sınav türüne göre örnek placeholder (web ile aynı)
  String _examNamePlaceholder(String? apiType) {
    switch (apiType) {
      case 'TYT':              return '3D Yayınları TYT Genel';
      case 'AYT_SAYISAL':      return 'Karekök AYT Sayısal';
      case 'AYT_EA':           return 'Limit AYT Eşit Ağırlık';
      case 'AYT_SOZEL':        return 'Palme AYT Sözel';
      case 'AYT_DIL':          return 'Pelikan YDT İngilizce';
      case 'BRANS':            return 'Bilfen Matematik Branş Denemesi';
      case 'LGS':              return 'Çağdaş Eğitim LGS Genel';
      case 'KPSS_LISANS':      return '2024 KPSS Çıkmış Sorular';
      case 'KPSS_ONLISANS':    return 'Yargı KPSS Ön Lisans';
      case 'KPSS_ORTAOGRETIM': return 'Yediiklim KPSS Ortaöğretim';
      case 'ALES':             return 'Pegem ALES Genel — 50+50 soru';
      case 'YDS':              return 'ÖSYM YDS Çıkmış Sorular — 80 soru';
      case 'OABT':             return 'Pegem ÖABT — 40+10 soru';
      case 'AGS':              return 'MEB AGS Denemesi — 80 soru';
      case 'OKUL_SINAVI':      return '2024 Okul Sınavı';
      default:                 return 'Deneme adı';
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _titleCtrl.text = widget.existing!['title'] as String? ?? '';
      final typeStr = widget.existing!['type'] as String? ?? '';
      _selectedType = widget.availableTypes.firstWhere(
          (t) => t.apiType == typeStr,
          orElse: () => widget.availableTypes.first);
      _date = DateTime.tryParse(widget.existing!['date'] as String? ?? '') ??
          DateTime.now();
      final details = widget.existing!['details'] as List<dynamic>? ?? [];
      if (typeStr == 'BRANS' && details.isNotEmpty) {
        final lessonName = details.first['lessonName'] as String? ?? '';
        _selectedBransLesson = widget.bransBranchLessons
            .where((l) => l.name == lessonName)
            .firstOrNull;
      }
      _buildControllers();
      for (final d in details) {
        final name = d['lessonName'] as String? ?? '';
        _correctCtrls[name]?.text = (d['correct'] as int?)?.toString() ?? '';
        _wrongCtrls[name]?.text = (d['incorrect'] as int?)?.toString() ?? '';
      }
    } else {
      _selectedType = widget.availableTypes.first;
      _buildControllers();
    }
  }

  List<LessonSlot> get _activeLessons {
    if (_isBrans) {
      return _selectedBransLesson != null ? [_selectedBransLesson!] : [];
    }
    if (_isOkulSinavi) {
      return _selectedOkulLesson != null ? [_selectedOkulLesson!] : [];
    }
    return _selectedType?.lessons ?? [];
  }

  void _buildControllers() {
    for (final c in _maxQCtrls.values) { c.dispose(); }
    _correctCtrls.clear();
    _wrongCtrls.clear();
    _maxQCtrls.clear();
    // For OkulSinavi we build controllers for all lessons upfront (selected one shown at a time)
    final lessons = _isBrans
        ? widget.bransBranchLessons
        : (_selectedType?.lessons ?? []);
    for (final lesson in lessons) {
      _correctCtrls[lesson.name] = TextEditingController();
      _wrongCtrls[lesson.name] = TextEditingController();
      if (_isOkulSinavi) {
        _maxQCtrls[lesson.name] = TextEditingController(text: lesson.maxQuestions.toString());
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    for (final c in _correctCtrls.values) { c.dispose(); }
    for (final c in _wrongCtrls.values) { c.dispose(); }
    for (final c in _maxQCtrls.values) { c.dispose(); }
    super.dispose();
  }

  double get _totalNet {
    double total = 0;
    for (final lesson in _activeLessons) {
      final c = int.tryParse(_correctCtrls[lesson.name]?.text ?? '') ?? 0;
      final w = int.tryParse(_wrongCtrls[lesson.name]?.text ?? '') ?? 0;
      total += _isOkulSinavi ? c.toDouble() : c - (w / 4.0);
    }
    return total;
  }

  Future<void> _save() async {
    if (_selectedType == null) return;
    if (_isBrans && _selectedBransLesson == null) return;
    setState(() => _saving = true);
    try {
      final details = _activeLessons.map((lesson) {
        final c = int.tryParse(_correctCtrls[lesson.name]?.text ?? '') ?? 0;
        final w = int.tryParse(_wrongCtrls[lesson.name]?.text ?? '') ?? 0;
        final maxQ = _isOkulSinavi
            ? (int.tryParse(_maxQCtrls[lesson.name]?.text ?? '') ?? lesson.maxQuestions)
            : lesson.maxQuestions;
        // For OkulSinavi: net = doğru soru sayısı → send incorrect=0 so backend net = correct
        return {
          'lessonName': lesson.name,
          'correct': c,
          'incorrect': _isOkulSinavi ? 0 : w,
          'maxQuestions': maxQ,
        };
      }).toList();

      final body = {
        'title': _titleCtrl.text.trim(),
        'date': DateTime(_date.year, _date.month, _date.day, 12, 0, 0)
            .toUtc()
            .toIso8601String(),
        'type': _selectedType!.apiType,
        'details': details,
      };

      if (widget.existing != null) {
        await ApiService().dio.put('/Exam/${widget.existing!['id']}', data: body);
      } else {
        await ApiService().dio.post('/Exam', data: body);
      }
      widget.onSaved();
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      widget.messenger.showSnackBar(
        const SnackBar(content: Text('Deneme sonucu kaydedildi.')),
      );
    } catch (e) {
      widget.messenger.showSnackBar(
        SnackBar(content: Text('Sunucu hatası: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildDropdown<T>({
    required IconData icon,
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value != null ? AppColors.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          hint: Row(children: [
            Icon(icon, size: 20, color: const Color(0xFF6B7280)),
            const SizedBox(width: 10),
            Text(hint, style: const TextStyle(color: Color(0xFF9CA3AF))),
          ]),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final net = _totalNet;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (ctx, ctrl) => Padding(
        // Klavye açıkken liste yukarı kayabilsin — DraggableScrollableSheet
        // viewInsets'i otomatik almıyor.
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Text('📝 ', style: TextStyle(fontSize: 22)),
                  Text(
                    isEdit ? 'Deneme Sonucunu Düzenle' : 'Deneme Sonucu Ekle',
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(20),
                children: [
                  // Deneme adı — placeholder seçili sınava göre örnek verir
                  TextField(
                    controller: _titleCtrl,
                    decoration: InputDecoration(
                      hintText:
                          'örn. ${_examNamePlaceholder(_selectedType?.apiType)}',
                      prefixIcon: const Icon(Icons.label_outline),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tür
                  _buildDropdown<ExamTypeInfo>(
                    icon: Icons.assignment_outlined,
                    hint: 'Deneme Türü',
                    value: _selectedType,
                    items: widget.availableTypes
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.displayName),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _selectedType = v;
                        _selectedBransLesson = null;
                        _selectedOkulLesson = null;
                        _buildControllers();
                      });
                    },
                  ),
                  // BRANS → ders seçimi
                  if (_isBrans) ...[
                    const SizedBox(height: 12),
                    _buildDropdown<LessonSlot>(
                      icon: Icons.menu_book_rounded,
                      hint: 'Ders Seçin',
                      value: _selectedBransLesson,
                      items: widget.bransBranchLessons
                          .map((l) => DropdownMenuItem(
                                value: l,
                                child: Text(l.name),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedBransLesson = v),
                    ),
                  ],
                  // OKUL_SINAVI → ders seçimi (tek ders)
                  if (_isOkulSinavi) ...[
                    const SizedBox(height: 12),
                    _buildDropdown<LessonSlot>(
                      icon: Icons.menu_book_rounded,
                      hint: 'Sınav Dersi Seçin',
                      value: _selectedOkulLesson,
                      items: (_selectedType?.lessons ?? [])
                          .map((l) => DropdownMenuItem(
                                value: l,
                                child: Text(l.name),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedOkulLesson = v),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Tarih
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 15),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 18, color: Color(0xFF6B7280)),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('dd.MM.yyyy').format(_date),
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Toplam net — belirgin kutucuk
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _isOkulSinavi
                              ? 'Toplam: ${net.toStringAsFixed(0)}'
                              : 'Toplam Net: ${net.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 20),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isOkulSinavi
                              ? 'Net = Doğru Soru Sayısı'
                              : 'Net = Doğru − (Yanlış ÷ 4)',
                          style: const TextStyle(
                              color: Color(0xFF9CA3AF), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Ders Bazlı Doğru / Yanlış',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 10),
                  if ((_isBrans && _selectedBransLesson == null) ||
                      (_isOkulSinavi && _selectedOkulLesson == null))
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Ders seçtikten sonra doğru/yanlış girebilirsin.',
                        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                      ),
                    )
                  else if (_activeLessons.isNotEmpty)
                    ...(_activeLessons.map((lesson) => _LessonRow(
                          lesson: lesson,
                          correctCtrl: _correctCtrls[lesson.name]!,
                          wrongCtrl: _wrongCtrls[lesson.name]!,
                          maxQCtrl: _isOkulSinavi ? _maxQCtrls[lesson.name] : null,
                          onChanged: () => setState(() {}),
                        ))),
                  const SizedBox(height: 20),
                  // Kaydet butonu — tek ikon
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded, size: 20),
                      label: const Text('Deneme Sonucunu Kaydet',
                          style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  SizedBox(height: 24 + MediaQuery.of(context).padding.bottom),
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

class _LessonRow extends StatelessWidget {
  final LessonSlot lesson;
  final TextEditingController correctCtrl;
  final TextEditingController wrongCtrl;
  final TextEditingController? maxQCtrl;
  final VoidCallback onChanged;
  const _LessonRow({
    required this.lesson,
    required this.correctCtrl,
    required this.wrongCtrl,
    required this.onChanged,
    this.maxQCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final editable = maxQCtrl != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (editable) ...[
            // Ders adı + düzenlenebilir soru sayısı
            Row(
              children: [
                Expanded(
                  child: Text(
                    lesson.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: maxQCtrl,
                    onChanged: (_) => onChanged(),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Soru sayısı',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          // Doğru / Yanlış satırı
          Row(
            children: [
              if (!editable)
                Expanded(
                  flex: 3,
                  child: Text(
                    '${lesson.name} (${lesson.maxQuestions})',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              if (!editable) const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: correctCtrl,
                  onChanged: (_) => onChanged(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'D',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF10B981)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: wrongCtrl,
                  onChanged: (_) => onChanged(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Y',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFEF4444)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPARISON SHEET — tarih sıralı diff, uzun trend metni, tarih göster
// ─────────────────────────────────────────────────────────────────────────────

class _ComparisonSheet extends StatefulWidget {
  final List<Map<String, dynamic>> exams;
  final ExamTypeInfo? typeInfo;
  const _ComparisonSheet({required this.exams, this.typeInfo});

  @override
  State<_ComparisonSheet> createState() => _ComparisonSheetState();
}

class _ComparisonSheetState extends State<_ComparisonSheet> {
  final List<int> _selectedIds = [];

  List<Map<String, dynamic>> get _selected {
    final sel = widget.exams
        .where((e) => _selectedIds.contains(e['id'] as int?))
        .toList();
    return _sortByDate(sel);
  }

  void _toggle(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else if (_selectedIds.length < 3) {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final nets = selected
        .map((e) => (e['totalNet'] as num?)?.toDouble() ?? 0.0)
        .toList();

    String? trendText;
    bool trendUp = true;
    if (nets.length >= 2) {
      final diff = nets.last - nets.first;
      trendUp = diff >= 0;
      final sign = diff >= 0 ? '+' : '';
      if (trendUp) {
        trendText =
            'Seçtiğin denemeler arasında toplam netinde $sign${diff.toStringAsFixed(1)} artış var. '
            'Harika gidiyorsun, bu ivmeyi koru! 🚀';
      } else {
        trendText =
            'Seçtiğin denemeler arasında toplam netinde ${diff.toStringAsFixed(1)} düşüş var. '
            'Daha çok çalış ve konuları tekrar et. 💪';
      }
    }

    // Tüm sınavları tarih sırasına göre göster
    final sortedAll = _sortByDate(widget.exams);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (ctx, ctrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('📊 ', style: TextStyle(fontSize: 22)),
                      Text('Deneme Karşılaştırması',
                          style: TextStyle(
                              fontSize: 19, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Karşılaştırmak istediğin max 3 denemeyi seç',
                      style: TextStyle(
                          color: Color(0xFF9CA3AF), fontSize: 13)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(20),
                children: [
                  // Deneme seçim kartları — tarih sıralı, tarih gösterimli
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: sortedAll.map((exam) {
                        final id = exam['id'] as int? ?? 0;
                        final idx = _selectedIds.indexOf(id);
                        final isSelected = idx != -1;
                        final title =
                            (exam['title'] as String?)?.isNotEmpty == true
                                ? exam['title'] as String
                                : exam['type'] as String? ?? 'Deneme';
                        final date = DateTime.tryParse(
                            exam['date'] as String? ?? '');
                        final dateStr = date != null
                            ? DateFormat('dd.MM.yyyy').format(date)
                            : '';
                        return GestureDetector(
                          onTap: () => _toggle(id),
                          child: Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (isSelected)
                                  Text(
                                    '${idx + 1}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18),
                                  ),
                                Text(
                                  title,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF374151),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (dateStr.isNotEmpty)
                                  Text(
                                    dateStr,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.8)
                                          : const Color(0xFF9CA3AF),
                                      fontSize: 11,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (trendText != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: trendUp
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        trendText,
                        style: TextStyle(
                          color: trendUp
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFC62828),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                  if (selected.length >= 2) ...[
                    const SizedBox(height: 18),
                    const Text('Net Gelişimi',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 10),
                    _TrendChart(exams: selected),
                  ],
                  if (selected.length >= 2 &&
                      widget.typeInfo != null &&
                      widget.typeInfo!.lessons.length >= 3) ...[
                    const SizedBox(height: 8),
                    _RadarCard(exams: selected, typeInfo: widget.typeInfo!),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
