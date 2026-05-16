import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/study_with_me_channels.dart';

const _ambientSounds = [
  _SoundEntry('🌧️', 'Yağmur Sesi', 'https://www.youtube.com/watch?v=mPZkdNFkNps'),
  _SoundEntry('🔥', 'Şömine Ateşi', 'https://www.youtube.com/watch?v=L_LUpnjgPso'),
  _SoundEntry('🌲', 'Orman & Kuşlar', 'https://www.youtube.com/watch?v=xNN7iTA57jM'),
  _SoundEntry('☕', 'Kafe Ortamı', 'https://www.youtube.com/watch?v=gaGrHCGGODo'),
  _SoundEntry('🌊', 'Okyanus Dalgaları', 'https://www.youtube.com/watch?v=bn9F19Hi1Lk'),
];

class _SoundEntry {
  final String emoji;
  final String name;
  final String url;
  const _SoundEntry(this.emoji, this.name, this.url);
}

class StudyWithMeCard extends StatefulWidget {
  const StudyWithMeCard({super.key});

  @override
  State<StudyWithMeCard> createState() => _StudyWithMeCardState();
}

class _StudyWithMeCardState extends State<StudyWithMeCard> {
  bool _expanded = false;
  int _tab = 0; // 0 = ortam sesi, 1 = çalışma yayınları

  final _customCtrl = TextEditingController();

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  Future<void> _launchYoutube(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('YouTube açılamadı.')),
        );
      }
    }
  }

  void _openCustomYoutube() {
    final raw = _customCtrl.text.trim();
    if (raw.isEmpty) return;
    final url = raw.startsWith('http')
        ? raw
        : 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(raw)}';
    _launchYoutube(url);
  }

  @override
  Widget build(BuildContext context) {
    const cardBg = Color(0xFF1E2433);
    const cardBorder = Color(0xFF2A3350);
    const textPrimary = Color(0xFFE2E8F0);
    const textSecondary = Color(0xFF94A3B8);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ────────────────────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.headphones_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ortam Sesleri & Çalışma Yayınları',
                            style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                        Text('Odaklanmana yardımcı olur',
                            style: TextStyle(
                                color: textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded içerik ───────────────────────────────────────────
          if (_expanded) ...[
            const Divider(color: cardBorder, height: 1),

            // Sekme seçici
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  _TabChip(
                    label: '🎵 Ortam Sesleri',
                    selected: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                  const SizedBox(width: 8),
                  _TabChip(
                    label: '▶️ Çalışma Yayınları',
                    selected: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: _tab == 0 ? _buildAmbientTab() : _buildYoutubeTab(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAmbientTab() {
    const textPrimary = Color(0xFFE2E8F0);
    const textSecondary = Color(0xFF94A3B8);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._ambientSounds.map((s) => InkWell(
              onTap: () => _launchYoutube(s.url),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(s.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(s.name,
                          style: const TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                    const Icon(Icons.open_in_new_rounded,
                        color: textSecondary, size: 14),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 8),
        _buildSearchRow(),
        const SizedBox(height: 6),
        const Text(
          '💡 Sayaç arka planda çalışmaya devam eder.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildYoutubeTab() {
    const textPrimary = Color(0xFFE2E8F0);
    const textSecondary = Color(0xFF94A3B8);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...kStudyChannels.map((ch) => InkWell(
              onTap: () => _launchYoutube(ch.url),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(ch.emoji,
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ch.name,
                              style: const TextStyle(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          Text(ch.description,
                              style: const TextStyle(
                                  color: textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    const Icon(Icons.open_in_new_rounded,
                        color: textSecondary, size: 14),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 8),
        _buildSearchRow(),
        const SizedBox(height: 6),
        const Text(
          '💡 Sayaç arka planda çalışmaya devam eder.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildSearchRow() {
    const textPrimary = Color(0xFFE2E8F0);
    const textSecondary = Color(0xFF94A3B8);

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _customCtrl,
            style: const TextStyle(color: textPrimary, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'YouTube linki veya arama...',
              hintStyle:
                  const TextStyle(color: textSecondary, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF252D40),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _openCustomYoutube,
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFFF0000),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.open_in_new_rounded,
                color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF4F46E5)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
