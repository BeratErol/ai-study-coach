import api from './api'

export interface GelisimimStats {
  totalCompletedTasks: number
  totalStudyMinutes: number
  totalQuestions: number
  totalPomodoros: number
}

export interface XpInfo {
  currentXp: number
  xpForNextLevel: number
  level: number
  levelName: string
  levelEmoji: string
  streakDays: number
}

export interface ActivityDay {
  date: string
  totalMinutes: number
}

export interface LessonDist {
  lessonName: string
  percentage: number
  totalMinutes: number
}

function ymd(d: Date): string {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

export const gelisimimService = {
  async getStats(filter: 'all' | 'today'): Promise<GelisimimStats> {
    const res = await api.get(`/Gelisimim/stats?filter=${filter}`)
    const d = res.data ?? {}
    return {
      totalCompletedTasks: d.completedTasks ?? 0,
      totalStudyMinutes: d.totalMinutes ?? 0,
      totalQuestions: d.totalQuestions ?? 0,
      totalPomodoros: d.completedTasks ?? 0,
    }
  },

  async getXpInfo(): Promise<XpInfo> {
    const res = await api.get('/Gelisimim/xp-info')
    const d = res.data ?? {}
    const total = d.totalXP ?? 0
    const base = d.currentLevelXP ?? 0
    const next = d.nextLevelXP ?? 1
    return {
      currentXp: Math.max(0, total - base),
      xpForNextLevel: Math.max(1, next - base),
      level: 1,
      levelName: d.levelName ?? '',
      levelEmoji: d.levelEmoji ?? '🌱',
      streakDays: d.streakDays ?? 0,
    }
  },

  // Backend'de haftalık aktivite endpoint'i yok → aylık heatmap'ten son 7 gün türetilir
  async getWeeklyActivity(): Promise<ActivityDay[]> {
    let heatmap: { date: string; totalMinutes: number }[] = []
    try {
      const res = await api.get('/StudySession/monthly-heatmap')
      heatmap = res.data ?? []
    } catch {
      heatmap = []
    }
    const byDate: Record<string, number> = {}
    for (const h of heatmap) {
      byDate[h.date?.slice(0, 10)] = h.totalMinutes ?? 0
    }
    const days: ActivityDay[] = []
    for (let i = 6; i >= 0; i--) {
      const d = new Date()
      d.setDate(d.getDate() - i)
      const key = ymd(d)
      days.push({ date: key, totalMinutes: byDate[key] ?? 0 })
    }
    return days
  },

  async getLessonDistribution(filter: string): Promise<LessonDist[]> {
    const res = await api.get(`/Gelisimim/lesson-distribution?filter=${filter}`)
    const list = (res.data ?? []) as { lessonName: string; totalQuestions: number }[]
    const total = list.reduce((s, l) => s + (l.totalQuestions ?? 0), 0)
    return list.map((l) => ({
      lessonName: l.lessonName,
      totalMinutes: l.totalQuestions ?? 0,
      percentage: total > 0 ? Math.round(((l.totalQuestions ?? 0) / total) * 100) : 0,
    }))
  },
}
