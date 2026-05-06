import type { OnboardingData } from '../models/OnboardingData'

function key(userId: string, k: string): string {
  return `user_${userId}_${k}`
}

export function isOnboardingCompleted(userId: string): boolean {
  return localStorage.getItem(key(userId, 'onboarding_completed')) === 'true'
}

export function setOnboardingCompleted(userId: string, value: boolean): void {
  localStorage.setItem(key(userId, 'onboarding_completed'), String(value))
}

export function saveOnboardingData(userId: string, data: OnboardingData): void {
  localStorage.setItem(key(userId, 'onboarding_data'), JSON.stringify(data))
}

export function getOnboardingData(userId: string): OnboardingData | null {
  const raw = localStorage.getItem(key(userId, 'onboarding_data'))
  if (!raw) return null
  try {
    return JSON.parse(raw) as OnboardingData
  } catch {
    return null
  }
}

export function clearUserData(userId: string): void {
  localStorage.removeItem(key(userId, 'onboarding_completed'))
  localStorage.removeItem(key(userId, 'onboarding_data'))
}
