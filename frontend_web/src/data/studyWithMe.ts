// Mobildeki study_with_me_channels.dart + ambient sesler portu.

export interface SoundEntry {
  emoji: string
  name: string
  url: string
}

export const ambientSounds: SoundEntry[] = [
  { emoji: '🌧️', name: 'Yağmur Sesi', url: 'https://www.youtube.com/watch?v=mPZkdNFkNps' },
  { emoji: '🔥', name: 'Şömine Ateşi', url: 'https://www.youtube.com/watch?v=L_LUpnjgPso' },
  { emoji: '🌲', name: 'Orman & Kuşlar', url: 'https://www.youtube.com/watch?v=xNN7iTA57jM' },
  // Calmed By Nature — 8 saatlik kafe atmosferi (kahve makinesi, fısıltı, yağmur).
  { emoji: '☕', name: 'Kafe Ortamı', url: 'https://www.youtube.com/watch?v=h2zkV-l_TbY' },
  { emoji: '🌊', name: 'Okyanus Dalgaları', url: 'https://www.youtube.com/watch?v=bn9F19Hi1Lk' },
]

export interface StudyChannel {
  name: string
  emoji: string
  description: string
  // YouTube'da popüler "study with me / lofi" araması — kanalın canlı yayın
  // sekmesine yönlendirir. Belirli yayın id'leri kaldırılınca ölü link
  // olmasın diye /live ya da arama sonucu açılır.
  url: string
}

export const studyChannels: StudyChannel[] = [
  { name: 'Lofi Girl', emoji: '🎵', description: '24/7 canlı lofi hip hop radio', url: 'https://www.youtube.com/@LofiGirl/live' },
  { name: 'Chilledcow / Lofi Cafe', emoji: '☕', description: '24/7 chill beats', url: 'https://www.youtube.com/results?search_query=lofi+hip+hop+radio+live&sp=EgJAAQ%253D%253D' },
  { name: 'Study With Me Canlı', emoji: '📚', description: 'Gerçek öğrenci canlı çalışma yayınları', url: 'https://www.youtube.com/results?search_query=study+with+me+live&sp=EgJAAQ%253D%253D' },
]
