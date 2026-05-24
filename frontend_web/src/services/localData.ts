import { getUserId } from './tokenService'
import { pushAppState } from './appStateService'

// ─── Manuel görevler (mobildeki manualTasksProvider karşılığı) ───────────────

export interface ManualTask {
  id: string
  subjectName: string
  taskType: string
  durationMinutes: number
  date: string // YYYY-MM-DD
  topicName?: string
  isStrong?: boolean
}

function manualKey(userId: string): string {
  return `user_${userId}_manual_tasks`
}

export function getManualTasks(): ManualTask[] {
  const userId = getUserId()
  if (!userId) return []
  const raw = localStorage.getItem(manualKey(userId))
  if (!raw) return []
  try {
    return JSON.parse(raw) as ManualTask[]
  } catch {
    return []
  }
}

export function saveManualTasks(tasks: ManualTask[]): void {
  const userId = getUserId()
  if (!userId) return
  localStorage.setItem(manualKey(userId), JSON.stringify(tasks))
  pushAppState('manual_tasks', tasks)
}

// ─── Hızlı notlar (mobildeki quickNotesProvider karşılığı) ───────────────────

export interface QuickNote {
  id: string
  title: string
  content: string
  createdAt: string
}

function notesKey(userId: string): string {
  return `user_${userId}_quick_notes`
}

export function getQuickNotes(): QuickNote[] {
  const userId = getUserId()
  if (!userId) return []
  const raw = localStorage.getItem(notesKey(userId))
  if (!raw) return []
  try {
    return JSON.parse(raw) as QuickNote[]
  } catch {
    return []
  }
}

export function saveQuickNotes(notes: QuickNote[]): void {
  const userId = getUserId()
  if (!userId) return
  localStorage.setItem(notesKey(userId), JSON.stringify(notes))
  pushAppState('quick_notes', notes)
}

// ─── Tamamlanan görevler (gün bazlı, mobildeki completedTaskIdsProvider) ─────

function todayStr(): string {
  const d = new Date()
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

function completedKey(userId: string): string {
  return `user_${userId}_completed_tasks_${todayStr()}`
}

export function getCompletedTaskIds(): Set<string> {
  const userId = getUserId()
  if (!userId) return new Set()
  const raw = localStorage.getItem(completedKey(userId))
  if (!raw) return new Set()
  try {
    return new Set(JSON.parse(raw) as string[])
  } catch {
    return new Set()
  }
}

export function saveCompletedTaskIds(ids: Set<string>): void {
  const userId = getUserId()
  if (!userId) return
  localStorage.setItem(completedKey(userId), JSON.stringify([...ids]))
  pushAppState(`completed_tasks_${todayStr()}`, [...ids])
}

/** Belirli bir tarihteki (YYYY-MM-DD) tamamlanan görev id'lerini döndürür. */
export function getCompletedTaskIdsForDate(dateStr: string): Set<string> {
  const userId = getUserId()
  if (!userId) return new Set()
  const raw = localStorage.getItem(`user_${userId}_completed_tasks_${dateStr}`)
  if (!raw) return new Set()
  try {
    return new Set(JSON.parse(raw) as string[])
  } catch {
    return new Set()
  }
}

/**
 * Tüm geçmiş günlerdeki tamamlanan görevleri tarar (mobildeki localAllTimeStats).
 * Döndürür: { date → Set<id> } — bugün dahil.
 */
export function getAllCompletedTaskDays(): Record<string, Set<string>> {
  const userId = getUserId()
  if (!userId) return {}
  const prefix = `user_${userId}_completed_tasks_`
  const result: Record<string, Set<string>> = {}
  for (let i = 0; i < localStorage.length; i++) {
    const key = localStorage.key(i)
    if (!key || !key.startsWith(prefix)) continue
    const date = key.slice(prefix.length)
    const raw = localStorage.getItem(key)
    if (!raw) continue
    try {
      result[date] = new Set(JSON.parse(raw) as string[])
    } catch {
      // bozuk → atla
    }
  }
  return result
}

// ─── Tamamlanan ders detayları (gün bazlı, ders adı/türü dahil) ──────────────
// completedTaskIds sadece id tutar; geçmiş günlerde ders adını gösterebilmek için
// tamamlama anında dersin tüm bilgisini bu kayda da yazarız.

export interface CompletedLessonRecord {
  id: string
  subjectName: string
  emoji: string
  taskType: string
  durationMinutes: number
  topicName?: string
}

function lessonRecKey(userId: string, dateStr: string): string {
  return `user_${userId}_completed_lessons_${dateStr}`
}

/** Bir günün tamamlanan ders detaylarını döndürür. */
export function getCompletedLessons(dateStr: string): CompletedLessonRecord[] {
  const userId = getUserId()
  if (!userId) return []
  const raw = localStorage.getItem(lessonRecKey(userId, dateStr))
  if (!raw) return []
  try {
    return JSON.parse(raw) as CompletedLessonRecord[]
  } catch {
    return []
  }
}

/** Bir günün tamamlanan ders detaylarını kaydeder. */
export function saveCompletedLessons(dateStr: string, lessons: CompletedLessonRecord[]): void {
  const userId = getUserId()
  if (!userId) return
  localStorage.setItem(lessonRecKey(userId, dateStr), JSON.stringify(lessons))
  pushAppState(`completed_lessons_${dateStr}`, lessons)
}

/** Bir dersi belirli güne ekler (tekrar eklemez). */
export function addCompletedLesson(dateStr: string, lesson: CompletedLessonRecord): void {
  const list = getCompletedLessons(dateStr)
  if (list.some((l) => l.id === lesson.id)) return
  saveCompletedLessons(dateStr, [...list, lesson])
}

/** Bir dersi belirli günden çıkarır (görev geri-tikleme). */
export function removeCompletedLesson(dateStr: string, id: string): void {
  const list = getCompletedLessons(dateStr)
  saveCompletedLessons(dateStr, list.filter((l) => l.id !== id))
}

/** Tüm günlerin tamamlanan ders detaylarını döndürür: { date → records }. */
export function getAllCompletedLessons(): Record<string, CompletedLessonRecord[]> {
  const userId = getUserId()
  if (!userId) return {}
  const prefix = `user_${userId}_completed_lessons_`
  const result: Record<string, CompletedLessonRecord[]> = {}
  for (let i = 0; i < localStorage.length; i++) {
    const key = localStorage.key(i)
    if (!key || !key.startsWith(prefix)) continue
    const date = key.slice(prefix.length)
    const raw = localStorage.getItem(key)
    if (!raw) continue
    try {
      result[date] = JSON.parse(raw) as CompletedLessonRecord[]
    } catch {
      // bozuk → atla
    }
  }
  return result
}

// ─── Konu atamaları (blockId → konu adı) ─────────────────────────────────────

function topicKey(userId: string): string {
  return `user_${userId}_topic_assignments`
}

export function getTopicAssignments(): Record<string, string> {
  const userId = getUserId()
  if (!userId) return {}
  const raw = localStorage.getItem(topicKey(userId))
  if (!raw) return {}
  try {
    return JSON.parse(raw) as Record<string, string>
  } catch {
    return {}
  }
}

export function saveTopicAssignments(map: Record<string, string>): void {
  const userId = getUserId()
  if (!userId) return
  localStorage.setItem(topicKey(userId), JSON.stringify(map))
  pushAppState('topic_assignments', map)
}

// ─── Dinlenme günleri (YYYY-MM-DD listesi) ───────────────────────────────────

function restKey(userId: string): string {
  return `user_${userId}_rest_days`
}

export function getRestDays(): string[] {
  const userId = getUserId()
  if (!userId) return []
  const raw = localStorage.getItem(restKey(userId))
  if (!raw) return []
  try {
    return JSON.parse(raw) as string[]
  } catch {
    return []
  }
}

export function saveRestDays(days: string[]): void {
  const userId = getUserId()
  if (!userId) return
  localStorage.setItem(restKey(userId), JSON.stringify(days))
  pushAppState('rest_days', days)
}
