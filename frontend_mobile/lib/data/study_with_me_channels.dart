class StudyChannel {
  final String name;
  final String emoji;
  final String description;
  final String url;

  const StudyChannel({
    required this.name,
    required this.emoji,
    required this.description,
    required this.url,
  });
}

// YouTube'da popüler "study with me / lofi" araması — kanalın canlı yayın
// sekmesine yönlendirir. Belirli yayın id'leri kaldırılınca ölü link olmasın
// diye /live ya da arama sonucu (canlı filtreli) açılır.
const kStudyChannels = [
  StudyChannel(
    name: 'Lofi Girl',
    emoji: '🎵',
    description: '24/7 canlı lofi hip hop radio',
    url: 'https://www.youtube.com/@LofiGirl/live',
  ),
  StudyChannel(
    name: 'Chilledcow / Lofi Cafe',
    emoji: '☕',
    description: '24/7 chill beats',
    url: 'https://www.youtube.com/results?search_query=lofi+hip+hop+radio+live&sp=EgJAAQ%253D%253D',
  ),
  StudyChannel(
    name: 'Study With Me Canlı',
    emoji: '📚',
    description: 'Gerçek öğrenci canlı çalışma yayınları',
    url: 'https://www.youtube.com/results?search_query=study+with+me+live&sp=EgJAAQ%253D%253D',
  ),
];
