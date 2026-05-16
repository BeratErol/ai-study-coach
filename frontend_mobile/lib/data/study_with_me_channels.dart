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

const kStudyChannels = [
  StudyChannel(
    name: 'Lofi Girl',
    emoji: '🎵',
    description: '24/7 canlı lofi müzik',
    url: 'https://www.youtube.com/watch?v=jfKfPfyJRdk',
  ),
  StudyChannel(
    name: 'Study To Success',
    emoji: '📚',
    description: 'Sessiz pomodoro oturumları',
    url: 'https://www.youtube.com/@studytosuccess',
  ),
  StudyChannel(
    name: 'The Strive Studies',
    emoji: '✏️',
    description: 'Gerçek öğrenci çalışma yayınları',
    url: 'https://www.youtube.com/@TheStriveStudies',
  ),
];
