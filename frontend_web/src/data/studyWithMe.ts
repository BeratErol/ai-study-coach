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
  { emoji: '☕', name: 'Kafe Ortamı', url: 'https://www.youtube.com/watch?v=gaGrHCGGODo' },
  { emoji: '🌊', name: 'Okyanus Dalgaları', url: 'https://www.youtube.com/watch?v=bn9F19Hi1Lk' },
]

export interface StudyChannel {
  name: string
  emoji: string
  description: string
  url: string
}

export const studyChannels: StudyChannel[] = [
  { name: 'Lofi Girl', emoji: '🎵', description: '24/7 canlı lofi müzik', url: 'https://www.youtube.com/watch?v=jfKfPfyJRdk' },
  { name: 'Study To Success', emoji: '📚', description: 'Sessiz pomodoro oturumları', url: 'https://www.youtube.com/@studytosuccess' },
  { name: 'The Strive Studies', emoji: '✏️', description: 'Gerçek öğrenci çalışma yayınları', url: 'https://www.youtube.com/@TheStriveStudies' },
]
