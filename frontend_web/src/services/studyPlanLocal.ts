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

function archiveKey(userId: string): string {
  return `user_${userId}_weekly_plan_archive`
}

/** Geçmiş tüm plan günleri birleştirilmiş arşiv. Yeni plan üretildiğinde
 *  eski plan günleri buraya eklenir; "Geçmişi Gör"de eski plan günlerinde
 *  blok bilgisi ve dinlenme bayrağı bu arşivden okunur. */
export function getPlanArchive(): StudyDay[] {
  const userId = getUserId()
  if (!userId) return []
  const raw = localStorage.getItem(archiveKey(userId))
  if (!raw) return []
  try {
    return JSON.parse(raw) as StudyDay[]
  } catch {
    return []
  }
}

/** Onboarding verisinden plan üretir; hem localStorage'a hem backend'e yazar.
 *  Yeni plan üretirken eski planın günlerini arşive ekler (geçmişi gör için). */
export function generateAndStorePlan(userId: string, data: OnboardingData): StudyDay[] {
  // Mevcut planı oku ve geçmiş günlerini arşive ekle.
  const existingRaw = localStorage.getItem(planKey(userId))
  if (existingRaw) {
    try {
      const old = JSON.parse(existingRaw) as StudyDay[]
      const archive = getPlanArchive()
      const known = new Set(archive.map((d) => d.date.slice(0, 10)))
      const merged = [...archive]
      for (const d of old) {
        const k = d.date.slice(0, 10)
        if (!known.has(k)) {
          merged.push(d)
          known.add(k)
        }
      }
      localStorage.setItem(archiveKey(userId), JSON.stringify(merged))
      pushAppState('weekly_plan_archive', merged)
    } catch {
      // bozuk eski plan → arşive eklenmez
    }
  }
  const plan = generateWeeklyPlan(data)
  localStorage.setItem(planKey(userId), JSON.stringify(plan))
  pushAppState('weekly_plan', plan)
  return plan
}

/** Kaydedilmiş planı sil; bir sonraki getStudyPlan() çağrısı yeniden üretir. */
export function resetStudyPlan(userId: string): void {
  localStorage.removeItem(planKey(userId))
}

/**
 * "Etkin gün" — gece kuşu kullanıcılar için sabah 04:00'a kadar dünden say.
 * Plan süresi de bu mantıkla değerlendirilir.
 */
function effectiveToday(): Date {
  const now = new Date()
  if (now.getHours() < 4) {
    const y = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 1)
    return y
  }
  return new Date(now.getFullYear(), now.getMonth(), now.getDate())
}

/**
 * Geçerli haftalık planı döndürür — TÜM 7 günü (geçmiş + bugün + gelecek).
 * - Kayıtlı plan varsa olduğu gibi döndürür (süresi dolsa bile).
 * - Plan hiç yoksa ilk kez `OnboardingData`'dan üretir.
 *
 * Süresi dolan planı OTOMATİK yenilemez — bunu kullanıcı dashboard'daki
 * "Yeni Program Oluştur" akışıyla manuel yapar. Bu sayede iki cihaz da
 * yeni plan tek bir yerden üretildiğinde senkron kalır.
 */
export function getStudyPlan(): StudyDay[] {
  const userId = getUserId()
  if (!userId) return []
  const data = getOnboardingData(userId)
  if (!data) return []

  const raw = localStorage.getItem(planKey(userId))
  if (raw) {
    try {
      const stored = JSON.parse(raw) as StudyDay[]
      if (stored.length > 0 && stored[0].blocks !== undefined) {
        return stored
      }
    } catch {
      // bozuk JSON → yeni üret
    }
  }
  // Hiç plan yok — ilk kez üret
  return generateAndStorePlan(userId, data)
}

/**
 * Plan süresi doldu mu? "Etkin gün" (gece kuşu kuralı: 04:00'tan önceyse dün)
 * planın son gününden BÜYÜKSE plan bitti demektir.
 */
export function isPlanExpired(plan?: StudyDay[]): boolean {
  const p = plan ?? getStudyPlan()
  if (p.length === 0) return false
  const last = new Date(p[p.length - 1].date)
  const lastDay = new Date(last.getFullYear(), last.getMonth(), last.getDate())
  return effectiveToday().getTime() > lastDay.getTime()
}

/** Bugünün planını döndürür (yoksa null). */
export function getTodayPlan(): StudyDay | null {
  const plan = getStudyPlan()
  const today = new Date()
  return plan.find((d) => isSameDay(new Date(d.date), today)) ?? null
}
