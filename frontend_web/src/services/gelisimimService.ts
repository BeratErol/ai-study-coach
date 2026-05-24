import api from './api'

// ─── Tipler (mobil ile uyumlu) ───────────────────────────────────────────────

export interface GelisimimStats {
  completedTasks: number
  totalMinutes: number
  totalQuestions: number
  restDays: number
}

export interface XpInfo {
  totalXP: number
  currentLevelXP: number
  nextLevelXP: number
  levelName: string
  levelEmoji: string
  streakDays: number
  totalQuestions: number
}

export interface LessonDistribution {
  lessonName: string
  totalQuestions: number
}

export interface DailyQuestion {
  subjectName: string
  count: number
}

export interface DailyReport {
  date: string
  questions: DailyQuestion[]
  tasks: { completed: number; missed: number; totalMinutes: number }
  isEmpty: boolean
}

// ─── XP seviye hesabı (mobildeki applyXpBoost ile aynı) ──────────────────────

export function levelFromXp(total: number): {
  levelName: string
  levelEmoji: string
  currentLevelXP: number
  nextLevelXP: number
} {
  if (total <= 2000) return { levelName: 'Çırak Öğrenci', levelEmoji: '🌱', currentLevelXP: 0, nextLevelXP: 2000 }
  if (total <= 5000) return { levelName: 'Acemi Öğrenci', levelEmoji: '📖', currentLevelXP: 2000, nextLevelXP: 5000 }
  if (total <= 10000) return { levelName: 'Gelişen Öğrenci', levelEmoji: '📚', currentLevelXP: 5000, nextLevelXP: 10000 }
  return { levelName: 'Uzman Öğrenci', levelEmoji: '🎓', currentLevelXP: 10000, nextLevelXP: 20000 }
}

export function xpProgressFraction(xp: XpInfo): number {
  const range = xp.nextLevelXP - xp.currentLevelXP
  if (range <= 0) return 1
  return Math.min(1, Math.max(0, (xp.totalXP - xp.currentLevelXP) / range))
}

/** Backend XP'sine lokal tamamlanan ders XP'sini ekleyip seviyeyi yeniden hesaplar. */
export function applyXpBoost(base: XpInfo, boost: number): XpInfo {
  const total = base.totalXP + boost
  const lvl = levelFromXp(total)
  return {
    totalXP: total,
    currentLevelXP: lvl.currentLevelXP,
    nextLevelXP: lvl.nextLevelXP,
    levelName: lvl.levelName,
    levelEmoji: lvl.levelEmoji,
    streakDays: base.streakDays,
    totalQuestions: base.totalQuestions,
  }
}

// ─── Servis ───────────────────────────────────────────────────────────────────

export const gelisimimService = {
  async getStats(filter: 'all' | 'today'): Promise<GelisimimStats> {
    const res = await api.get(`/Gelisimim/stats?filter=${filter}`)
    const d = res.data ?? {}
    return {
      completedTasks: d.completedTasks ?? 0,
      totalMinutes: d.totalMinutes ?? 0,
      totalQuestions: d.totalQuestions ?? 0,
      restDays: d.restDays ?? 0,
    }
  },

  async getXpInfo(): Promise<XpInfo> {
    const res = await api.get('/Gelisimim/xp-info')
    const d = res.data ?? {}
    return {
      totalXP: d.totalXP ?? 0,
      currentLevelXP: d.currentLevelXP ?? 0,
      nextLevelXP: d.nextLevelXP ?? 2000,
      levelName: d.levelName ?? 'Çırak Öğrenci',
      levelEmoji: d.levelEmoji ?? '🌱',
      streakDays: d.streakDays ?? 0,
      totalQuestions: d.totalQuestions ?? 0,
    }
  },

  async getLessonDistribution(filter: 'all' | 'today'): Promise<LessonDistribution[]> {
    const res = await api.get(`/Gelisimim/lesson-distribution?filter=${filter}`)
    return ((res.data ?? []) as LessonDistribution[]).map((l) => ({
      lessonName: l.lessonName ?? '',
      totalQuestions: l.totalQuestions ?? 0,
    }))
  },

  async saveQuestions(entries: { subjectKey: string; subjectName: string; count: number }[]): Promise<number> {
    const res = await api.post('/Gelisimim/save-questions', { entries })
    return res.data?.totalToday ?? 0
  },

  async getCalendarActiveDays(year: number, month: number): Promise<string[]> {
    const res = await api.get(`/Gelisimim/calendar?year=${year}&month=${month}`)
    return (res.data?.activeDays ?? []) as string[]
  },

  /**
   * Bugün her ders için girilmiş soru sayısı: { subjectName: count }.
   * Anahtar yerine ders ADI kullanılır — mobil ve web farklı subjectKey
   * üretebildiği için (ör. 'tyt_coğrafya' vs 'tyt_cografya') ada göre
   * eşleştirmek tek güvenilir yoldur.
   */
  async getTodayQuestionCounts(): Promise<Record<string, number>> {
    const today = new Date()
    const dateStr = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`
    const report = await this.getDailyReport(dateStr)
    const map: Record<string, number> = {}
    for (const q of report.questions) {
      if ((q.count ?? 0) > 0) map[q.subjectName] = q.count
    }
    return map
  },

  async getDailyReport(date: string): Promise<DailyReport> {
    const res = await api.get(`/Gelisimim/daily-report?date=${date}`)
    const d = res.data ?? {}
    return {
      date: d.date ?? date,
      questions: (d.questions ?? []) as DailyQuestion[],
      tasks: {
        completed: d.tasks?.completed ?? 0,
        missed: d.tasks?.missed ?? 0,
        totalMinutes: d.tasks?.totalMinutes ?? 0,
      },
      isEmpty: d.isEmpty ?? true,
    }
  },
}
