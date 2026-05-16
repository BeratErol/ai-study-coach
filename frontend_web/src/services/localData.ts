import { getUserId } from './tokenService'

// ─── Manuel görevler (mobildeki manualTasksProvider karşılığı) ───────────────

export interface ManualTask {
  id: string
  subjectName: string
  taskType: string
  durationMinutes: number
  date: string // YYYY-MM-DD
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
}

// ─── Hızlı notlar (mobildeki quickNotesProvider karşılığı) ───────────────────

export interface QuickNote {
  id: string
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
}
