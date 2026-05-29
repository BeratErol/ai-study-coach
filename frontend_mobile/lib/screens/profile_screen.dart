import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_theme.dart';
import '../main.dart';
import '../models/onboarding_data.dart';
import '../models/quick_note.dart';
import '../models/study_plan.dart';
import '../models/subject_data.dart';
import '../providers/study_plan_provider.dart';
import '../services/api_service.dart';
import '../services/app_state_service.dart';
import '../services/token_service.dart';
import '../services/user_prefs_service.dart';
import '../widgets/quick_note_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _storage = const FlutterSecureStorage();
  String _userName = '';
  final String _educationLevel = '';
  final _dersProfilimKey = GlobalKey<_DersProfilimSectionState>();

  String _educationLabel(String level) {
    switch (level) {
      case 'ortaokul':  return 'Ortaokul';
      case 'lise':      return 'Lise';
      case 'universite': return 'Üniversite / Mezun';
      default:          return level;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null && !JwtDecoder.isExpired(token)) {
      final payload = JwtDecoder.decode(token);
      final name = payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name']
              as String? ??
          payload['name'] as String? ??
          '';
      if (mounted) setState(() => _userName = name);
    }
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    ref.read(themeModeProvider.notifier).state =
        value ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> _logout() async {
    await _storage.delete(key: 'jwt_token');
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final onboardingAsync = ref.watch(onboardingDataProvider);

    final educationLevel = onboardingAsync.value?.educationLevel ?? _educationLevel;
    final targetExam = onboardingAsync.value?.targetExam ?? '';
    // Onboarding'de girilen tam ad — JWT'deki kısaltılmış ad değil.
    final onboardingName = (onboardingAsync.value?.name ?? '').trim();
    final displayName = onboardingName.isNotEmpty ? onboardingName : _userName;

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: GestureDetector(
        onTap: () {
          final messenger = ScaffoldMessenger.of(context);
          showModalBottomSheet(
            context: context,
            useRootNavigator: true,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            builder: (_) => QuickNoteSheet(messenger: messenger),
          );
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: Color(0xFFF97316),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
          ),
          child: const Icon(Icons.edit_note_rounded,
              color: Colors.white, size: 28),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Koyu gradient header ─────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF1A1A2E),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A1A2E), Color(0xFF2D1B69)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1.5),
                        ),
                        child: const Center(
                          child: Text('🎓',
                              style: TextStyle(fontSize: 34)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        (displayName.isNotEmpty ? displayName : 'Kullanıcı').toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800),
                      ),
                      if (educationLevel.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _educationLabel(educationLevel),
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 15,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Bölümler ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 12),
                _NotlarimSection(),
                _AkademikHedefSection(dersProfilimKey: _dersProfilimKey),
                _DersProfilimSection(key: _dersProfilimKey),
                _ZamanBiyoritimSection(),
                _SinavTarihiSection(),
                // ── Ayarlar ─────────────────────────────────────────────
                _sectionCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryO10,
                            borderRadius: AppRadius.sm,
                          ),
                          child: const Icon(Icons.dark_mode_rounded,
                              color: AppColors.primary),
                        ),
                        title: const Text('Karanlık Mod',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        value: isDark,
                        onChanged: _toggleDarkMode,
                        activeThumbColor: AppColors.primary,
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: AppRadius.sm,
                          ),
                          child: const Icon(Icons.logout_rounded,
                              color: AppColors.error),
                        ),
                        title: const Text('Çıkış Yap',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.error)),
                        trailing: const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textHint),
                        onTap: _logout,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'AI Study Coach v1.0.0  •  Hedef Sınav: $targetExam',
                  style: const TextStyle(
                      color: AppColors.textHint, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

Widget _sectionCard({required Widget child, EdgeInsets? margin}) {
  return Builder(
    builder: (context) => Container(
      margin: margin ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
      child: child,
    ),
  );
}

Widget _sectionHeader(
    {required String title,
    required IconData icon,
    required Color color}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
      ],
    ),
  );
}

Future<bool> _showRebuildDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Text('Program Yenilecek'),
          ]),
          content: const Text(
              'Bu değişiklik haftalık programını yeniden oluşturacak.\nMevcut program güncellenecek.\n\nDevam etmek istiyor musun?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('İptal')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                child: const Text('Evet, Yenile')),
          ],
        ),
      ) ??
      false;
}

void _showSnack(BuildContext context, String msg,
    {Color bg = const Color(0xFF1F2937)}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: bg,
    behavior: SnackBarBehavior.floating,
    shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. NOTLARIM
// ─────────────────────────────────────────────────────────────────────────────

class _NotlarimSection extends ConsumerStatefulWidget {
  @override
  ConsumerState<_NotlarimSection> createState() => _NotlarimSectionState();
}

class _NotlarimSectionState extends ConsumerState<_NotlarimSection> {
  int _page = 0;

  void _openNoteDetail(BuildContext context, QuickNote note,
      List<QuickNote> allNotes) {
    const months = [
      '',
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    final dt = note.createdAt;
    final dateStr =
        '${dt.day} ${months[dt.month]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        builder: (ctx, ctrl) => Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
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
                    Expanded(
                      child: Text(
                        note.title?.isNotEmpty == true
                            ? note.title!
                            : 'Not',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: Colors.grey.shade400),
                        onPressed: () => Navigator.of(ctx).pop()),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(dateStr,
                      style: const TextStyle(
                          color: Color(0xFF9CA3AF), fontSize: 12)),
                ),
              ),
              const Divider(height: 20),
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    Text(note.content,
                        style: TextStyle(
                            fontSize: 15,
                            color: Theme.of(ctx).textTheme.bodyMedium?.color))
                  ],
                ),
              ),
              Padding(
                // Alt safe area + nav bar boşluğu — Sil/Kapat butonları kapanmasın
                padding: EdgeInsets.fromLTRB(
                    16, 8, 16, 20 + MediaQuery.of(ctx).padding.bottom),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.error, size: 18),
                        label: const Text('Sil',
                            style:
                                TextStyle(color: AppColors.error)),
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: AppColors.error)),
                        onPressed: () {
                          ref
                              .read(quickNotesProvider.notifier)
                              .removeNote(note.id);
                          Navigator.of(ctx).pop();
                          final idx = allNotes.indexOf(note);
                          if (_page >= idx && _page > 0) {
                            setState(() => _page--);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Kapat'),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(quickNotesProvider);

    return _sectionCard(
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(16))),
        collapsedShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
        title: _sectionHeader(
          title: 'Notlarım',
          icon: Icons.bolt_rounded,
          color: const Color(0xFFF59E0B),
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Builder(builder: (context) {
                if (notes.isEmpty) {
                  return Column(
                    children: [
                      const Text('🗒️',
                          style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text('Henüz not eklemedin.',
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        'Sol alttaki ✏️ butonuyla\nhızlı not ekle!',
                        style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                }

                final page = _page.clamp(0, notes.length - 1);
                final note = notes[page];

                return Column(
                  children: [
                    Text('${page + 1}/${notes.length}',
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 12)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _openNoteDetail(
                          context, note, notes),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            if (note.title?.isNotEmpty == true)
                              Text(note.title!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                            if (note.title?.isNotEmpty == true)
                              const SizedBox(height: 4),
                            Text(note.content,
                                style: TextStyle(
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                    fontSize: 13),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: page > 0
                              ? () => setState(() => _page--)
                              : null,
                        ),
                        const Spacer(),
                        IconButton(
                          icon:
                              const Icon(Icons.chevron_right_rounded),
                          onPressed: page < notes.length - 1
                              ? () => setState(() => _page++)
                              : null,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. AKADEMİK HEDEF
// ─────────────────────────────────────────────────────────────────────────────

class _AkademikHedefSection extends ConsumerStatefulWidget {
  final GlobalKey<_DersProfilimSectionState> dersProfilimKey;
  const _AkademikHedefSection({required this.dersProfilimKey});

  @override
  ConsumerState<_AkademikHedefSection> createState() =>
      _AkademikHedefSectionState();
}

class _AkademikHedefSectionState
    extends ConsumerState<_AkademikHedefSection> {
  String? _pendingExam;
  String? _pendingArea;

  // Eğitim düzeyine göre sınav seçenekleri
  // (emoji, displayName, internalValue)
  static const _examsByLevel = {
    'ortaokul': [('📋', 'LGS', 'LGS'), ('🏫', 'Okul Sınavlarım', 'OkulSinavi')],
    'lise': [('🎓', 'YKS', 'YKS'), ('🏫', 'Okul Sınavlarım', 'OkulSinavi')],
    'universite': [
      ('🏢', 'KPSS', 'KPSS'),
      ('📐', 'ALES', 'ALES'),
      ('🌐', 'YDS', 'YDS'),
      ('👩‍🏫', 'Öğretmenlik', 'Öğretmenlik'),
      ('🏛️', 'Okul Sınavlarım', 'OkulSinavi'),
    ],
  };

  // Sınava göre alan seçenekleri (statik sınavlar için)
  static const _alanlarByExam = {
    'YKS': [
      ('Sayısal (MF)', 'sayisal'),
      ('Eşit Ağırlık (TM)', 'esit_agirlik'),
      ('Sözel (TS)', 'sozel'),
      ('Dil', 'dil'),
      ('Sadece TYT', 'sadece_tyt'),
    ],
    'KPSS': [
      ('KPSS Lisans', 'kpss_lisans'),
      ('KPSS Önlisans', 'kpss_onlisans'),
    ],
  };

  // OkulSinavi için eğitim düzeyine göre alan seçenekleri
  static List<(String, String)> _okulSinaviAlanlar(String educationLevel) {
    if (educationLevel == 'ortaokul') {
      return const [
        ('5. Sınıf', 'sinif_5'),
        ('6. Sınıf', 'sinif_6'),
        ('7. Sınıf', 'sinif_7'),
        ('8. Sınıf', 'sinif_8'),
      ];
    } else if (educationLevel == 'lise') {
      return const [
        ('9. Sınıf', 'lise_9'),
        ('10. Sınıf', 'lise_10'),
        ('11-12 Sayısal (MF)', 'lise_1112_sayisal'),
        ('11-12 Eşit Ağırlık (EA)', 'lise_1112_ea'),
        ('11-12 Sözel (TS)', 'lise_1112_sozel'),
        ('11-12 Dil (YDT)', 'lise_1112_dil'),
      ];
    } else {
      return const [
        ('Yazılım / Bilgisayar', 'uni_yazilim'),
        ('Tıp', 'uni_tip'),
        ('Hukuk', 'uni_hukuk'),
        ('Psikoloji', 'uni_psikoloji'),
        ('İşletme / Ekonomi', 'uni_isletme'),
        ('Mühendislik', 'uni_muhendislik'),
        ('Eğitim / Öğretmenlik', 'uni_egitim'),
        ('Diğer / Kendi Ekle', 'uni_diger'),
      ];
    }
  }

  Future<void> _confirm(OnboardingData data) async {
    final userId = await TokenService.getUserId();
    if (userId == null) return;
    final newExam = _pendingExam ?? data.targetExam;
    final newArea = _pendingArea ?? data.selectedArea;
    final newData = data.copyWith(
      targetExam: newExam,
      selectedArea: newArea,
      strongSubjects: [],
      weakSubjects: [],
      customSubjects: [],
    );
    await UserPrefsService.saveOnboardingData(userId, newData.toJson());
    // Sınav/alan değişince hedefler de sıfırlanır
    await UserPrefsService.saveExamGoal(userId,
        tytHedef: '', tytNet: null, aytHedef: '', aytNet: null);
    ref.invalidate(onboardingDataProvider);
    ref.invalidate(studyPlanProvider);
    ref.invalidate(todayTasksProvider);
    ref.invalidate(examGoalProvider);
    if (mounted) {
      setState(() { _pendingExam = null; _pendingArea = null; });
      widget.dersProfilimKey.currentState?.expandAndReset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingAsync = ref.watch(onboardingDataProvider);

    return _sectionCard(
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
        collapsedShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
        title: _sectionHeader(
          title: 'Akademik Hedef',
          icon: Icons.school_rounded,
          color: const Color(0xFF7C3AED),
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: onboardingAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Text('Veri yüklenemedi.'),
              data: (data) {
                if (data == null) return const Text('Onboarding verisi bulunamadı.');
                final currentExam = _pendingExam ?? data.targetExam;
                final currentArea = _pendingArea ?? data.selectedArea;
                final exams = _examsByLevel[data.educationLevel] ??
                    _examsByLevel['lise']!;
                final alanlar = currentExam == 'OkulSinavi'
                    ? _okulSinaviAlanlar(data.educationLevel)
                    : _alanlarByExam[currentExam];
                final hasChanges = (_pendingExam != null && _pendingExam != data.targetExam) ||
                    (_pendingArea != null && _pendingArea != data.selectedArea);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hedef Sınav',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: exams.map((e) {
                        final selected = currentExam == e.$3;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _pendingExam = e.$3;
                            _pendingArea = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (selected) ...[
                                  const Icon(Icons.check,
                                      size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                ],
                                Text('${e.$1} ${e.$2}',
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    )),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (alanlar != null) ...[
                      const SizedBox(height: 16),
                      const Text('Alanınız Nedir?',
                          style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: alanlar
                            .map((a) => _AreaChip(
                                  label: a.$1,
                                  value: a.$2,
                                  selected: currentArea == a.$2,
                                  onTap: () => setState(() => _pendingArea = a.$2),
                                ))
                            .toList(),
                      ),
                    ],
                    if (hasChanges) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _confirm(data),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14))),
                          child: const Text('✅ Onayla'),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _AreaChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.secondary
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppColors.secondary
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check,
                  size: 14, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. DERS PROFİLİM
// ─────────────────────────────────────────────────────────────────────────────

class _DersProfilimSection extends ConsumerStatefulWidget {
  const _DersProfilimSection({super.key});

  @override
  ConsumerState<_DersProfilimSection> createState() =>
      _DersProfilimSectionState();
}

class _DersProfilimSectionState
    extends ConsumerState<_DersProfilimSection> {
  List<String>? _pendingStrong;
  List<String>? _pendingWeak;
  List<String>? _pendingCustom;
  bool _hasChanges = false;
  final _tileCtrl = ExpansibleController();
  final _subjectAddCtrl = TextEditingController();

  @override
  void dispose() {
    _subjectAddCtrl.dispose();
    super.dispose();
  }

  void expandAndReset() {
    setState(() {
      _pendingStrong = [];
      _pendingWeak = [];
      _pendingCustom = null;
      _hasChanges = false;
    });
    try { _tileCtrl.expand(); } catch (_) {}
  }

  void _toggleStrong(String name, List<String> strongBase, List<String> weakBase) {
    final strong = List<String>.from(_pendingStrong ?? strongBase);
    final weak = List<String>.from(_pendingWeak ?? weakBase);
    strong.contains(name) ? strong.remove(name) : strong.add(name);
    weak.remove(name);
    setState(() {
      _pendingStrong = strong;
      _pendingWeak = weak;
      _hasChanges = true;
    });
  }

  void _toggleWeak(String name, List<String> strongBase, List<String> weakBase) {
    final strong = List<String>.from(_pendingStrong ?? strongBase);
    final weak = List<String>.from(_pendingWeak ?? weakBase);
    weak.contains(name) ? weak.remove(name) : weak.add(name);
    strong.remove(name);
    setState(() {
      _pendingStrong = strong;
      _pendingWeak = weak;
      _hasChanges = true;
    });
  }

  void _addCustomSubject(String name, OnboardingData data) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final custom = List<String>.from(_pendingCustom ?? data.customSubjects);
    if (custom.contains(trimmed)) return;
    custom.add(trimmed);
    setState(() {
      _pendingCustom = custom;
      _hasChanges = true;
    });
    _subjectAddCtrl.clear();
  }

  void _removeCustomSubject(String name, OnboardingData data) {
    final custom = List<String>.from(_pendingCustom ?? data.customSubjects)..remove(name);
    final strong = List<String>.from(_pendingStrong ?? data.strongSubjects)..remove(name);
    final weak = List<String>.from(_pendingWeak ?? data.weakSubjects)..remove(name);
    setState(() {
      _pendingCustom = custom;
      _pendingStrong = strong;
      _pendingWeak = weak;
      _hasChanges = true;
    });
  }

  Widget _buildOkulSinaviContent(OnboardingData data) {
    final isFullyManual = data.selectedArea == 'uni_diger';
    final baseSubjects = isFullyManual
        ? <SubjectData>[]
        : getSubjectsForExam(data.targetExam, data.selectedArea);
    final baseNames = baseSubjects.map((s) => s.name).toSet();
    final customList = _pendingCustom ?? data.customSubjects;
    final extraNames = customList.where((n) => !baseNames.contains(n)).toList();
    final allSubjects = [
      ...baseSubjects,
      ...extraNames.map((n) => SubjectData(name: n, emoji: '📝')),
    ];
    final strong = _pendingStrong ?? data.strongSubjects;
    final weak = _pendingWeak ?? data.weakSubjects;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _subjectAddCtrl,
                decoration: InputDecoration(
                  hintText: 'Ders adı ekle (örn. Fizik)',
                  hintStyle: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 13),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                ),
                onSubmitted: (v) => _addCustomSubject(v, data),
                textInputAction: TextInputAction.done,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _addCustomSubject(_subjectAddCtrl.text, data),
              child: Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (allSubjects.isNotEmpty) ...[
          Text(
            isFullyManual ? 'Eklenen Dersler' : 'Ders Havuzu',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allSubjects.map((s) {
              final canRemove = isFullyManual || !baseNames.contains(s.name);
              return Container(
                padding: EdgeInsets.only(
                    left: 10, right: canRemove ? 4 : 10, top: 6, bottom: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.emoji, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(s.name,
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodyLarge?.color)),
                    if (canRemove) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _removeCustomSubject(s.name, data),
                        child: Icon(Icons.close_rounded,
                            size: 15,
                            color: Theme.of(context).textTheme.bodySmall?.color),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Center(
              child: Text(
                'Henüz ders eklenmedi. Yukarıdan ders ekle.',
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        if (allSubjects.isNotEmpty) ...[
          _infoBox(
            '💪 Güçlü Dersler / Az çalışmak istediğin dersler.\nBu dersler 30 dakikalıktır.',
            bgColor: const Color(0xFFFFF7ED),
            borderColor: const Color(0xFFFED7AA),
            textColor: const Color(0xFF92400E),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allSubjects
                .map((s) => _SubjectChip(
                      name: s.name,
                      emoji: s.emoji,
                      isSelected: strong.contains(s.name),
                      onTap: () => _toggleStrong(
                          s.name, data.strongSubjects, data.weakSubjects),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          _infoBox(
            '🎯 Zayıf Dersler / Çok çalışmak istediğin dersler.\nBu dersler 60 dakikalıktır.',
            bgColor: const Color(0xFFFFF3E0),
            borderColor: const Color(0xFFFFCC80),
            textColor: const Color(0xFFE65100),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allSubjects
                .map((s) => _SubjectChip(
                      name: s.name,
                      emoji: s.emoji,
                      isSelected: weak.contains(s.name),
                      selectedColor: AppColors.secondary,
                      onTap: () => _toggleWeak(
                          s.name, data.strongSubjects, data.weakSubjects),
                    ))
                .toList(),
          ),
        ],

        if (_hasChanges) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _save(data),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: const Text('💾 Değişiklikleri Kaydet'),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _save(OnboardingData data) async {
    final newDataWeak = _pendingWeak ?? data.weakSubjects;
    final newDataCustom = _pendingCustom ?? data.customSubjects;
    final isOkulDiger = data.targetExam == 'OkulSinavi' &&
        data.selectedArea == 'uni_diger';
    // Zayıf ders seçilmeden program üretilemez (uni_diger: customSubjects).
    final hasMinimumSubjects = isOkulDiger
        ? newDataCustom.isNotEmpty
        : newDataWeak.isNotEmpty;
    if (!hasMinimumSubjects) {
      _showSnack(
        context,
        'Program oluşturmak için en az 1 zayıf ders seçmelisin.',
        bg: AppColors.error,
      );
      return;
    }

    final confirm = await _showRebuildDialog(context);
    if (!confirm) return;

    final userId = await TokenService.getUserId();
    if (userId == null) return;

    final newData = data.copyWith(
      strongSubjects: _pendingStrong ?? data.strongSubjects,
      weakSubjects: newDataWeak,
      customSubjects: newDataCustom,
    );

    // Ders havuzu değişti mi? (sınav türü/alan veya güçlü/zayıf/custom listeleri)
    final shapeChanged =
        data.targetExam != newData.targetExam ||
        data.selectedArea != newData.selectedArea ||
        !_sameSet(data.strongSubjects, newData.strongSubjects) ||
        !_sameSet(data.weakSubjects, newData.weakSubjects) ||
        !_sameSet(data.customSubjects, newData.customSubjects);

    await UserPrefsService.saveOnboardingData(userId, newData.toJson());
    // Profil değişikliğini backend'e de yaz — web aynı hesabı açtığında
    // güncel profili ve yeni planı görsün.
    try {
      await ApiService().dio.post('/UserProfile', data: newData.toJson());
    } catch (_) {}
    await resetStudyPlan(ref, userId);
    ref.read(manualTasksProvider.notifier).clearForDate(DateTime.now());

    if (shapeChanged) {
      // Yeni planın id'leri eski atamalar/tamamlamalarla eşleşmez — sıfırla.
      ref.read(topicAssignmentsProvider.notifier).clearAll();
      await ref.read(completedTaskIdsProvider.notifier).clearToday();
    }

    ref.invalidate(onboardingDataProvider);
    ref.invalidate(todayTasksProvider);

    if (mounted) {
      setState(() => _hasChanges = false);
      _showSnack(context, 'Programın yenilendi! 🎉',
          bg: AppColors.success);
    }
  }

  // İki listenin sıra bağımsız eşit olup olmadığını kontrol eder.
  static bool _sameSet(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final sa = a.toSet();
    for (final x in b) {
      if (!sa.contains(x)) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final onboardingAsync = ref.watch(onboardingDataProvider);

    return _sectionCard(
      child: ExpansionTile(
        controller: _tileCtrl,
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(16))),
        collapsedShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
        title: _sectionHeader(
          title: 'Ders Profilim',
          icon: Icons.menu_book_rounded,
          color: const Color(0xFF2563EB),
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: onboardingAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  const Text('Veri yüklenemedi.'),
              data: (data) {
                if (data == null) {
                  return const Text('Onboarding verisi bulunamadı.');
                }

                // OkulSinavi: show editable subject pool + strong/weak toggles
                if (data.targetExam == 'OkulSinavi') {
                  return _buildOkulSinaviContent(data);
                }

                // Standard exams
                final allSubjects = getSubjectsForExam(
                    data.targetExam, data.selectedArea);
                final tyt = allSubjects
                    .where((s) => s.group == 'tyt' || s.group == 'default')
                    .toList();
                final ayt = allSubjects
                    .where((s) => s.group == 'ayt')
                    .toList();
                final strong = _pendingStrong ?? data.strongSubjects;
                final weak = _pendingWeak ?? data.weakSubjects;
                final tytLabel = _tytGroupLabel(data.targetExam);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoBox(
                      '💪 Güçlü Dersler / Az çalışmak istediğin dersler.\nBu dersler 30 dakikalıktır.',
                      bgColor: const Color(0xFFFFF7ED),
                      borderColor: const Color(0xFFFED7AA),
                      textColor: const Color(0xFF92400E),
                    ),
                    const SizedBox(height: 12),
                    if (tyt.isNotEmpty) ...[
                      Text(tytLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tyt
                            .map((s) => _SubjectChip(
                                  name: s.name,
                                  emoji: s.emoji,
                                  isSelected: strong.contains(s.name),
                                  onTap: () => _toggleStrong(
                                      s.name, data.strongSubjects, data.weakSubjects),
                                ))
                            .toList(),
                      ),
                    ],
                    if (ayt.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('📗 AYT / YDT Dersleri',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ayt
                            .map((s) => _SubjectChip(
                                  name: s.name,
                                  emoji: s.emoji,
                                  isSelected: strong.contains(s.name),
                                  onTap: () => _toggleStrong(
                                      s.name, data.strongSubjects, data.weakSubjects),
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _infoBox(
                      '🎯 Zayıf Dersler / Çok çalışmak istediğin dersler.\nBu dersler 60 dakikalıktır.',
                      bgColor: const Color(0xFFFFF3E0),
                      borderColor: const Color(0xFFFFCC80),
                      textColor: const Color(0xFFE65100),
                    ),
                    const SizedBox(height: 12),
                    if (tyt.isNotEmpty) ...[
                      Text(tytLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tyt
                            .map((s) => _SubjectChip(
                                  name: s.name,
                                  emoji: s.emoji,
                                  isSelected: weak.contains(s.name),
                                  selectedColor: AppColors.secondary,
                                  onTap: () => _toggleWeak(
                                      s.name, data.strongSubjects, data.weakSubjects),
                                ))
                            .toList(),
                      ),
                    ],
                    if (ayt.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('📗 AYT / YDT Dersleri',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ayt
                            .map((s) => _SubjectChip(
                                  name: s.name,
                                  emoji: s.emoji,
                                  isSelected: weak.contains(s.name),
                                  selectedColor: AppColors.secondary,
                                  onTap: () => _toggleWeak(
                                      s.name, data.strongSubjects, data.weakSubjects),
                                ))
                            .toList(),
                      ),
                    ],
                    if (_hasChanges) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _save(data),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14))),
                          child: const Text(
                              '💾 Değişiklikleri Kaydet'),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  final String name;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? selectedColor;

  const _SubjectChip({
    required this.name,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final base = selectedColor ?? const Color(0xFF16A34A);
    final bgColor = isSelected
        ? Color.fromARGB(
            30, base.r.toInt(), base.g.toInt(), base.b.toInt())
        : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? base : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.check, size: 13, color: base),
              const SizedBox(width: 4),
            ],
            Text(
              '$emoji $name',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? base : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _tytGroupLabel(String targetExam) {
  switch (targetExam) {
    case 'YKS': return '📘 TYT Dersleri';
    case 'KPSS': return '📘 KPSS Dersleri';
    case 'LGS': return '📘 LGS Dersleri';
    case 'ALES': return '📘 ALES Dersleri';
    case 'YDS': return '📘 YDS Dersleri';
    case 'Öğretmenlik': return '📘 Öğretmenlik Dersleri';
    default: return '📘 Dersler';
  }
}

Widget _infoBox(String text,
    {required Color bgColor,
    required Color borderColor,
    required Color textColor}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: borderColor),
    ),
    child: Text(text, style: TextStyle(color: textColor, fontSize: 12)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. ZAMAN VE BİYORİTİM
// ─────────────────────────────────────────────────────────────────────────────

class _ZamanBiyoritimSection extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ZamanBiyoritimSection> createState() =>
      _ZamanBiyoritimSectionState();
}

class _ZamanBiyoritimSectionState
    extends ConsumerState<_ZamanBiyoritimSection> {
  bool _initialized = false;
  bool _hasChanges = false;

  String _studyType = 'sabah';
  List<int> _offDays = [];
  bool _hasWeekdaySchool = false;
  String _weekdayStart = '08:00';
  String _weekdayEnd = '15:30';
  int _weekdayHours = 3;
  int _weekendHours = 4;
  String _weekdayStartTime = '16:00';
  String _weekendStartTime = '10:00';
  String _weekdayLatest = '22:30';
  String _weekendLatest = '23:30';

  void _init(OnboardingData d) {
    if (_initialized) return;
    _initialized = true;
    _studyType = d.studyType.isNotEmpty ? d.studyType : 'sabah';
    _offDays = List<int>.from(d.offDays);
    _hasWeekdaySchool = d.hasWeekdaySchool;
    _weekdayStart = d.weekdayStartTime;
    _weekdayEnd = d.weekdayEndTime;
    _weekdayHours = d.weekdayStudyHours;
    _weekendHours = d.weekendStudyHours;
    _weekdayStartTime = d.weekdayStartTime;
    _weekendStartTime = d.weekendStartTime;
    _weekdayLatest = d.weekdayLatestTime;
    _weekendLatest = d.weekendLatestTime;
  }

  void _mark() => setState(() => _hasChanges = true);

  Future<void> _pickTime(String current, void Function(String) onPick) async {
    final parts = current.split(':');
    final initial = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 8,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0);
    final picked =
        await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      onPick(
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
      _mark();
    }
  }

  Future<void> _save(OnboardingData data) async {
    final confirm = await _showRebuildDialog(context);
    if (!confirm) return;

    final userId = await TokenService.getUserId();
    if (userId == null) return;

    final newData = data.copyWith(
      studyType: _studyType,
      offDays: _offDays,
      hasWeekdaySchool: _hasWeekdaySchool,
      weekdayStartTime: _weekdayStartTime,
      weekdayEndTime: _weekdayEnd,
      weekdayStudyHours: _weekdayHours,
      weekendStudyHours: _weekendHours,
      weekendStartTime: _weekendStartTime,
      weekdayLatestTime: _weekdayLatest,
      weekendLatestTime: _weekendLatest,
    );
    await UserPrefsService.saveOnboardingData(userId, newData.toJson());
    // Profil değişikliğini backend'e de yaz — web senkron olsun.
    try {
      await ApiService().dio.post('/UserProfile', data: newData.toJson());
    } catch (_) {}
    await resetStudyPlan(ref, userId);
    ref.read(manualTasksProvider.notifier).clearForDate(DateTime.now());
    ref.invalidate(onboardingDataProvider);
    ref.invalidate(todayTasksProvider);

    // Saat değişti — ders havuzu aynı ama yeni planda bazı bloklar kaybolmuş
    // olabilir (program kısalmış). Bugünün completed_tasks/lessons
    // kayıtlarını mevcut plan id'leriyle filtrele ki "ders detayı kaydedilmemiş"
    // hayalet kayıt olmasın.
    try {
      final newPlan = await ref.read(studyPlanProvider.future);
      final today = DateTime.now();
      final todayDay = newPlan.firstWhere(
        (d) =>
            d.date.year == today.year &&
            d.date.month == today.month &&
            d.date.day == today.day,
        orElse: StudyDay.empty,
      );
      final validIds = todayDay.blocks.map((b) => b.id).toSet();
      await _trimCompletedToValidIds(userId, validIds);
    } catch (_) {}

    if (mounted) {
      setState(() => _hasChanges = false);
      _showSnack(context, 'Programın yenilendi! 🎉',
          bg: AppColors.success);
    }
  }

  /// Bugünün completed_tasks + completed_lessons kayıtlarından mevcut plan'da
  /// bulunmayan id'leri çıkarır. Hem SharedPreferences hem backend'e senkron.
  Future<void> _trimCompletedToValidIds(
      String userId, Set<String> validIds) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // completed_tasks_{today}
    final taskKey = 'user_${userId}_completed_tasks_$today';
    final rawTasks = prefs.getString(taskKey);
    if (rawTasks != null) {
      try {
        final ids = (jsonDecode(rawTasks) as List).cast<String>();
        final trimmed = ids
            .where((id) => validIds.contains(id) || id.startsWith('manual-'))
            .toList();
        if (trimmed.length != ids.length) {
          await prefs.setString(taskKey, jsonEncode(trimmed));
          await AppStateService.pushAppState(
              'completed_tasks_$today', trimmed);
          ref.read(completedTaskIdsProvider.notifier).markAll(trimmed.toSet());
        }
      } catch (_) {}
    }

    // completed_lessons_{today}
    final lessonKey = 'user_${userId}_completed_lessons_$today';
    final rawLessons = prefs.getString(lessonKey);
    if (rawLessons != null) {
      try {
        final list = (jsonDecode(rawLessons) as List)
            .cast<Map<String, dynamic>>();
        final trimmed = list
            .where((l) =>
                validIds.contains(l['id']) ||
                (l['id'] as String).startsWith('manual-'))
            .toList();
        if (trimmed.length != list.length) {
          await prefs.setString(lessonKey, jsonEncode(trimmed));
          await AppStateService.pushAppState(
              'completed_lessons_$today', trimmed);
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingAsync = ref.watch(onboardingDataProvider);
    const gunler = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cts', 'Paz'];

    return _sectionCard(
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(16))),
        collapsedShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
        title: _sectionHeader(
          title: 'Zaman ve Biyoritim',
          icon: Icons.access_time_rounded,
          color: const Color(0xFFDB2777),
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: onboardingAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  const Text('Veri yüklenemedi.'),
              data: (data) {
                if (data == null) {
                  return const Text('Onboarding verisi bulunamadı.');
                }
                _init(data);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Biyoritim
                    const Text('Biyoritim',
                        style: TextStyle(
                            color: Color(0xFF6B7280), fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _BioChip(
                            label: '☀️ Sabahçı',
                            selected: _studyType == 'sabah',
                            onTap: () => setState(() {
                              _studyType = 'sabah';
                              _hasChanges = true;
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _BioChip(
                            label: '🌙 Gececi',
                            selected: _studyType == 'gece',
                            onTap: () => setState(() {
                              _studyType = 'gece';
                              _hasChanges = true;
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Tatil günleri
                    const Text('Ders Olmasını İstemediğin Günler',
                        style: TextStyle(
                            color: Color(0xFF6B7280), fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(7, (i) {
                        final selected = _offDays.contains(i);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selected
                                  ? _offDays.remove(i)
                                  : _offDays.add(i);
                              _hasChanges = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : Colors.grey.shade300),
                            ),
                            child: Text(gunler[i],
                                style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    // Hafta içi
                    const Text('Hafta İçi Programım',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Okulum / İşim Var'),
                        Switch(
                          value: _hasWeekdaySchool,
                          onChanged: (v) => setState(() {
                            _hasWeekdaySchool = v;
                            _hasChanges = true;
                          }),
                          activeThumbColor: AppColors.primary,
                        ),
                      ],
                    ),
                    if (_hasWeekdaySchool) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _TimeBox(
                              label: 'Başlangıç',
                              time: _weekdayStart,
                              onTap: () => _pickTime(_weekdayStart,
                                  (v) => setState(() => _weekdayStart = v)),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.arrow_forward,
                                color: Colors.grey),
                          ),
                          Expanded(
                            child: _TimeBox(
                              label: 'Bitiş',
                              time: _weekdayEnd,
                              onTap: () => _pickTime(_weekdayEnd,
                                  (v) => setState(() => _weekdayEnd = v)),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Çalışma saatleri
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Hafta İçi Çalışma Saati',
                            style: TextStyle(fontSize: 13)),
                        Text('$_weekdayHours saat',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                      ],
                    ),
                    Slider(
                      min: 1,
                      max: 12,
                      divisions: 11,
                      value: _weekdayHours.toDouble(),
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() {
                        _weekdayHours = v.round();
                        _hasChanges = true;
                      }),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Hafta Sonu Çalışma Saati',
                            style: TextStyle(fontSize: 13)),
                        Text('$_weekendHours saat',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                      ],
                    ),
                    Slider(
                      min: 1,
                      max: 12,
                      divisions: 11,
                      value: _weekendHours.toDouble(),
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() {
                        _weekendHours = v.round();
                        _hasChanges = true;
                      }),
                    ),
                    const SizedBox(height: 8),
                    // Başlama saatleri
                    const Text('Derse Başlama Saati',
                        style: TextStyle(
                            color: Color(0xFF6B7280), fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _TimeBox(
                            label: 'Hafta İçi',
                            time: _weekdayStartTime,
                            onTap: () => _pickTime(
                                _weekdayStartTime,
                                (v) => setState(
                                    () => _weekdayStartTime = v)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TimeBox(
                            label: 'Hafta Sonu',
                            time: _weekendStartTime,
                            onTap: () => _pickTime(
                                _weekendStartTime,
                                (v) => setState(
                                    () => _weekendStartTime = v)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // En geç saatler
                    const Text('En Geç Saat',
                        style: TextStyle(
                            color: Color(0xFF6B7280), fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _TimeBox(
                            label: 'Hafta İçi',
                            time: _weekdayLatest,
                            onTap: () => _pickTime(_weekdayLatest,
                                (v) => setState(() => _weekdayLatest = v)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TimeBox(
                            label: 'Hafta Sonu',
                            time: _weekendLatest,
                            onTap: () => _pickTime(_weekendLatest,
                                (v) => setState(() => _weekendLatest = v)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Koç notu
                    _infoBox(
                      '💡 Koç Notu: Biyoritmine uygun çalışmak verimliliğini artırır! Doğru saatlerde çalışmak, aynı sürede çok daha fazla verim almanı sağlar.',
                      bgColor: const Color(0xFFFFFBEB),
                      borderColor: const Color(0xFFFDE68A),
                      textColor: const Color(0xFF92400E),
                    ),
                    if (_hasChanges) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _save(data),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14))),
                          child: const Text(
                              '💾 Değişiklikleri Kaydet'),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BioChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _BioChip(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey.shade600,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;
  const _TimeBox(
      {required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 10)),
            const SizedBox(height: 2),
            Text(time,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. SINAV TARİHİ VE HEDEF
// ─────────────────────────────────────────────────────────────────────────────

class _SinavTarihiSection extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SinavTarihiSection> createState() =>
      _SinavTarihiSectionState();
}

class _SinavTarihiSectionState
    extends ConsumerState<_SinavTarihiSection> {
  final _tytHedefCtrl = TextEditingController();
  final _tytNetCtrl = TextEditingController();
  final _aytHedefCtrl = TextEditingController();
  final _aytNetCtrl = TextEditingController();

  DateTime? _selectedDate;
  bool _goalDirty = false;
  bool _dateDirty = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _tytHedefCtrl.dispose();
    _tytNetCtrl.dispose();
    _aytHedefCtrl.dispose();
    _aytNetCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId = await TokenService.getUserId();
    if (userId == null) return;

    final goal = await UserPrefsService.getExamGoal(userId);
    final date = await UserPrefsService.getExamDate(userId);

    if (mounted) {
      setState(() {
        _tytHedefCtrl.text = goal['tytHedef'] as String? ?? '';
        _tytNetCtrl.text =
            (goal['tytNet'] as double?)?.toStringAsFixed(1) ?? '';
        _aytHedefCtrl.text = goal['aytHedef'] as String? ?? '';
        _aytNetCtrl.text =
            (goal['aytNet'] as double?)?.toStringAsFixed(1) ?? '';
        _selectedDate = date;
        _loaded = true;
      });
    }
  }

  // (goalTitle, goalHint, goalSubtitle, aytTitle, aytHint, netHint)
  (String, String, String, String, String, String) _goalLabels(String exam, String area, String educationLevel) {
    switch (exam) {
      case 'LGS':
        return (
          '🎓 LGS Hedefi Belirle',
          'Örn: Galatasaray Lisesi',
          'Hayalindeki liseyi ve gereken puanı gir.',
          '🎓 LGS Hedefi',
          'Örn: Kabataş Erkek Lisesi',
          'Gereken Net / Puan',
        );
      case 'KPSS':
        return (
          '🎓 KPSS Hedefi Belirle',
          'Örn: Ankara İl Müdürlüğü Memur',
          'Hayalindeki kadroyu ve gereken neti gir.',
          '🎓 KPSS Hedefi',
          'Örn: Ankara İl Müdürlüğü Memur',
          'Gereken Net / Puan',
        );
      case 'ALES':
        return (
          '🎓 ALES Hedefi Belirle',
          'Örn: İTÜ Yüksek Lisans',
          'Başvurmak istediğin programı gir.',
          '🎓 ALES Hedefi',
          'Örn: İTÜ Yüksek Lisans',
          'Gereken Net / Puan',
        );
      case 'YDS':
        return (
          '🎓 YDS Hedefi Belirle',
          'Örn: 90+ puan, akademik başvuru',
          'Hedefin puanı ve amacını gir.',
          '🎓 YDS Hedefi',
          'Örn: 90+ puan',
          'Gereken Net / Puan',
        );
      case 'Öğretmenlik':
        return (
          '🎓 AGS/ÖABT Hedefi Belirle',
          'Örn: Matematik Öğretmenliği — İstanbul',
          'Hayalindeki branş ve il tercihini gir.',
          '🎓 ÖABT Hedefi',
          'Örn: Matematik branşı',
          'Gereken Net / Puan',
        );
      case 'OkulSinavi': {
        final String goalHint;
        final String subtitle;
        if (educationLevel == 'ortaokul') {
          goalHint = 'Örn: Kabataş Erkek Lisesi';
          subtitle = 'Hedef liseni ve gereken ortalamayı gir.';
        } else if (educationLevel == 'lise') {
          goalHint = 'Örn: ODTÜ Bilgisayar Mühendisliği';
          subtitle = 'Hedef üniversiteni ve gereken ortalamayı gir.';
        } else {
          goalHint = 'Örn: Google, Yazılım Geliştirici';
          subtitle = 'Hedef iş yerini ve gereken ortalamayı gir.';
        }
        return (
          '🏫 Not Ortalaması Hedefi',
          goalHint,
          subtitle,
          '',
          '',
          'Gereken Ortalama',
        );
      }
      case 'YKS':
      default:
        final aytLabel = area == 'dil' ? '🎓 YDT Hedefi Belirle' : '🎓 AYT Hedefi Belirle';
        final aytHint = area == 'dil' ? 'Örn: Boğaziçi Mütercim-Tercümanlık' : 'Örn: ODTÜ Bilgisayar';
        return (
          '🎓 TYT Hedefi Belirle',
          'Örn: Boğaziçi Üniversitesi',
          'Hayalindeki üniversite ve bölümü gir.',
          aytLabel,
          aytHint,
          'Gereken Net / Puan',
        );
    }
  }

  Future<void> _saveGoal() async {
    final userId = await TokenService.getUserId();
    if (userId == null) return;
    await UserPrefsService.saveExamGoal(
      userId,
      tytHedef: _tytHedefCtrl.text,
      tytNet: double.tryParse(_tytNetCtrl.text),
      aytHedef: _aytHedefCtrl.text,
      aytNet: double.tryParse(_aytNetCtrl.text),
    );
    ref.invalidate(examGoalProvider);
    if (mounted) {
      setState(() => _goalDirty = false);
      _showSnack(context, 'Hedef kaydedildi ✨');
    }
  }

  Future<void> _saveDate() async {
    if (_selectedDate == null) return;
    final userId = await TokenService.getUserId();
    if (userId == null) return;

    // 1) Eski local key (geriye dönük cache)
    await UserPrefsService.saveExamDate(userId, _selectedDate!);

    // 2) onboarding_data.examDate'i de güncelle — web bu alanı okur.
    final currentMap = await UserPrefsService.getOnboardingData(userId);
    if (currentMap != null) {
      final updated = OnboardingData.fromJson(currentMap)
          .copyWith(examDate: _selectedDate);
      await UserPrefsService.saveOnboardingData(userId, updated.toJson());
      // 3) Backend'e profil POST — web hydrate'te güncel veriyi alsın.
      try {
        await ApiService().dio.post('/UserProfile', data: updated.toJson());
      } catch (_) {}
      ref.invalidate(onboardingDataProvider);
    }

    ref.invalidate(examCountdownProvider);
    ref.invalidate(examStatusProvider);
    if (mounted) {
      setState(() => _dateDirty = false);
      _showSnack(context, 'Sınav tarihi güncellendi! ✅',
          bg: AppColors.success);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateDirty = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingAsync = ref.watch(onboardingDataProvider);

    // examGoalProvider sıfırlanınca controller'ları temizle
    ref.listen(examGoalProvider, (_, next) {
      next.whenData((goal) {
        final tytH = goal['tytHedef'] as String? ?? '';
        final aytH = goal['aytHedef'] as String? ?? '';
        if (tytH.isEmpty && aytH.isEmpty && mounted) {
          setState(() {
            _tytHedefCtrl.text = '';
            _tytNetCtrl.text = '';
            _aytHedefCtrl.text = '';
            _aytNetCtrl.text = '';
            _goalDirty = false;
          });
        }
      });
    });

    return _sectionCard(
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(16))),
        collapsedShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
        title: _sectionHeader(
          title: 'Sınav Tarihi ve Hedef',
          icon: Icons.calendar_month_rounded,
          color: const Color(0xFF16A34A),
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: !_loaded
                ? const Center(child: CircularProgressIndicator())
                : onboardingAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator()),
                    error: (_, _) => const Text('Veri yüklenemedi.'),
                    data: (data) {
                      final area = data?.selectedArea ?? '';
                      final hasAyt = area == 'sayisal' ||
                          area == 'esit_agirlik' ||
                          area == 'sozel' ||
                          area == 'dil';

                      // Anasayfa ile aynı: midnight-to-midnight farkı
                      // (şu anki saatten değil), web ile uyumlu.
                      int? computeDaysLeft(DateTime? d) {
                        if (d == null) return null;
                        final now = DateTime.now();
                        final today =
                            DateTime(now.year, now.month, now.day);
                        final exam = DateTime(d.year, d.month, d.day);
                        return exam.difference(today).inDays;
                      }
                      final daysLeft = computeDaysLeft(
                          _selectedDate ?? data?.examDate);

                      const months = [
                        '',
                        'Ocak',
                        'Şubat',
                        'Mart',
                        'Nisan',
                        'Mayıs',
                        'Haziran',
                        'Temmuz',
                        'Ağustos',
                        'Eylül',
                        'Ekim',
                        'Kasım',
                        'Aralık'
                      ];
                      final dt = _selectedDate ?? data?.examDate;
                      final dateLabel = dt != null
                          ? '${dt.day} ${months[dt.month]} ${dt.year}'
                          : 'Tarih seçilmedi';

                      // Sınava göre dinamik etiketler
                      final exam = data?.targetExam ?? 'YKS';
                      final educationLevel = data?.educationLevel ?? '';
                      final (goalTitle, goalHint, goalSubtitle, aytTitle, aytHint, netHint) =
                          _goalLabels(exam, area, educationLevel);
                      final isOkulSinavi = exam == 'OkulSinavi';

                      return Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          _GoalCard(
                            title: goalTitle,
                            hedefCtrl: _tytHedefCtrl,
                            netCtrl: _tytNetCtrl,
                            isDirty: _goalDirty,
                            onChanged: () =>
                                setState(() => _goalDirty = true),
                            onSave: _saveGoal,
                            hedefHint: goalHint,
                            subtitle: goalSubtitle,
                            netHint: netHint,
                          ),
                          if (hasAyt && !isOkulSinavi) ...[
                            const SizedBox(height: 12),
                            _GoalCard(
                              title: aytTitle,
                              hedefCtrl: _aytHedefCtrl,
                              netCtrl: _aytNetCtrl,
                              isDirty: _goalDirty,
                              onChanged: () =>
                                  setState(() => _goalDirty = true),
                              onSave: _saveGoal,
                              hedefHint: aytHint,
                              subtitle: goalSubtitle,
                              netHint: netHint,
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Sınav tarihi
                          Row(
                            children: [
                              const Text('📅 Sınav Tarihi',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              const Spacer(),
                              if (daysLeft != null && daysLeft > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C3AED),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Text('$daysLeft gün',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F3FF),
                                borderRadius:
                                    BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFDDD6FE)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month,
                                      color: Color(0xFF7C3AED)),
                                  const SizedBox(width: 8),
                                  Text(dateLabel,
                                      style: const TextStyle(
                                          color: Color(0xFF7C3AED),
                                          fontWeight:
                                              FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                          if (_dateDirty) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saveDate,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF16A34A),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                                12))),
                                child: const Text('Tarihi Kaydet'),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final String title;
  final TextEditingController hedefCtrl;
  final TextEditingController netCtrl;
  final bool isDirty;
  final VoidCallback onChanged;
  final VoidCallback onSave;
  final String hedefHint;
  final String subtitle;
  final String netHint;

  const _GoalCard({
    required this.title,
    required this.hedefCtrl,
    required this.netCtrl,
    required this.isDirty,
    required this.onChanged,
    required this.onSave,
    this.hedefHint = 'Örn: ODTÜ Bilgisayar',
    this.subtitle = 'Hayalindeki üniversite ve bölümü gir.',
    this.netHint = 'Gereken Net / Puan',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Color(0xFF7C3AED),
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              const Spacer(),
              if (isDirty)
                TextButton(
                  onPressed: onSave,
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize:
                          MaterialTapTargetSize.shrinkWrap),
                  child: const Text('Kaydet',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 12)),
          const SizedBox(height: 10),
          TextField(
            controller: hedefCtrl,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              hintText: hedefHint,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: netCtrl,
            onChanged: (_) => onChanged(),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: netHint,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}
