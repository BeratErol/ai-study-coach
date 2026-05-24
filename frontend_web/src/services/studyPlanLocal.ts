import type { OnboardingData } from '../models/OnboardingData'
import { generateWeeklyPlan, type StudyDay } from './studyPlanGenerator'
import { getOnboardingData } from './userPrefsService'
import { getUserId } from './tokenService'
import { pushAppState } from './appStateService'

export type StudyDayView = StudyDay

function planKey(userId: string): string {
  return `user_${userId}_weekly_plan`
}

function isSameDay(a: Date, b: Date): boolean {
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  )
}

/** Onboarding verisinden plan üretir; hem localStorage'a hem backend'e yazar. */
export function generateAndStorePlan(userId: string, data: OnboardingData): StudyDay[] {
  const plan = generateWeeklyPlan(data)
  localStorage.setItem(planKey(userId), JSON.stringify(plan))
  // Backend senkronu — mobil aynı planı kullansın
  pushAppState('weekly_plan', plan)
  return plan
}

/** Kaydedilmiş planı sil; bir sonraki getStudyPlan() çağrısı yeniden üretir. */
export function resetStudyPlan(userId: string): void {
  localStorage.removeItem(planKey(userId))
}

/**
 * Geçerli haftalık planı döndürür — TÜM 7 günü (geçmiş + bugün + gelecek).
 * - Kayıtlı plan hâlâ geçerliyse (7 günlük pencere dolmadıysa) tam liste döner.
 * - Plan yok / süresi dolmuş / bozuksa yeni üret ve kaydet.
 *
 * Bugüne özel kullanım `getTodayPlan` ile yapılır; haftalık görünüm geçmiş
 * günleri de "geçti" olarak gösterebilsin diye filtre kaldırıldı.
 */
export function getStudyPlan(): StudyDay[] {
  const userId = getUserId()
  if (!userId) return []
  const data = getOnboardingData(userId)
  if (!data) return []

  const today = new Date()
  const todayDate = new Date(today.getFullYear(), today.getMonth(), today.getDate())

  const raw = localStorage.getItem(planKey(userId))
  if (raw) {
    try {
      const stored = JSON.parse(raw) as StudyDay[]
      if (stored.length > 0 && stored[0].blocks !== undefined) {
        const first = new Date(stored[0].date)
        const startDate = new Date(first.getFullYear(), first.getMonth(), first.getDate())
        const endDate = new Date(startDate)
        endDate.setDate(endDate.getDate() + 6)

        if (todayDate.getTime() <= endDate.getTime()) {
          return stored
        }
        // plan süresi dolmuş → yeniden üret
      }
    } catch {
      // bozuk JSON → yeniden üret
    }
  }

  return generateAndStorePlan(userId, data)
}

/** Bugünün planını döndürür (yoksa null). */
export function getTodayPlan(): StudyDay | null {
  const plan = getStudyPlan()
  const today = new Date()
  return plan.find((d) => isSameDay(new Date(d.date), today)) ?? null
}
