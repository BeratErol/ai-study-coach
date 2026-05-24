import type { OnboardingData } from '../models/OnboardingData'
import { pushAppState } from './appStateService'

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
  pushAppState('onboarding_data', data)
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

// ─── Akademik hedef (mobildeki saveExamGoal/getExamGoal) ─────────────────────

export interface ExamGoal {
  tytHedef: string
  tytNet: number | null
  aytHedef: string
  aytNet: number | null
}

export function saveExamGoal(userId: string, goal: ExamGoal): void {
  localStorage.setItem(key(userId, 'exam_goal'), JSON.stringify(goal))
  pushAppState('exam_goal', goal)
}

export function getExamGoal(userId: string): ExamGoal {
  const raw = localStorage.getItem(key(userId, 'exam_goal'))
  if (!raw) return { tytHedef: '', tytNet: null, aytHedef: '', aytNet: null }
  try {
    const g = JSON.parse(raw) as Partial<ExamGoal>
    return {
      tytHedef: g.tytHedef ?? '',
      tytNet: g.tytNet ?? null,
      aytHedef: g.aytHedef ?? '',
      aytNet: g.aytNet ?? null,
    }
  } catch {
    return { tytHedef: '', tytNet: null, aytHedef: '', aytNet: null }
  }
}
