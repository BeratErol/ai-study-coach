import { create } from 'zustand'
import api from '../services/api'
import { defaultOnboardingData, type OnboardingData } from '../models/OnboardingData'
import { getUserId } from '../services/tokenService'
import { setOnboardingCompleted, saveOnboardingData } from '../services/userPrefsService'

interface OnboardingStore extends OnboardingData {
  updateName: (v: string) => void
  updateGender: (v: string) => void
  updateEducationLevel: (v: string) => void
  updateTargetExam: (v: string) => void
  updateSelectedArea: (v: string) => void
  updateExamDate: (v: string | null) => void
  updateStudyType: (v: string) => void
  updateHasWeekdaySchool: (v: boolean) => void
  updateWeekdayStartTime: (v: string) => void
  updateWeekdayEndTime: (v: string) => void
  updateWeekdayStudyHours: (v: number) => void
  updateHasWeekendCourse: (v: boolean) => void
  updateWeekendStartTime: (v: string) => void
  updateWeekendStudyHours: (v: number) => void
  updateWeekdayLatestTime: (v: string) => void
  updateWeekendLatestTime: (v: string) => void
  updateOffDays: (v: number[]) => void
  updateStrongSubjects: (v: string[]) => void
  updateWeakSubjects: (v: string[]) => void
  reset: () => void
  completeOnboarding: () => Promise<void>
}

export const useOnboardingStore = create<OnboardingStore>((set, get) => ({
  ...defaultOnboardingData,

  updateName: (v) => set({ name: v }),
  updateGender: (v) => set({ gender: v }),
  updateEducationLevel: (v) => set({ educationLevel: v }),
  updateTargetExam: (v) => set({ targetExam: v }),
  updateSelectedArea: (v) => set({ selectedArea: v }),
  updateExamDate: (v) => set({ examDate: v }),
  updateStudyType: (v) => set({ studyType: v }),
  updateHasWeekdaySchool: (v) => set({ hasWeekdaySchool: v }),
  updateWeekdayStartTime: (v) => set({ weekdayStartTime: v }),
  updateWeekdayEndTime: (v) => set({ weekdayEndTime: v }),
  updateWeekdayStudyHours: (v) => set({ weekdayStudyHours: v }),
  updateHasWeekendCourse: (v) => set({ hasWeekendCourse: v }),
  updateWeekendStartTime: (v) => set({ weekendStartTime: v }),
  updateWeekendStudyHours: (v) => set({ weekendStudyHours: v }),
  updateWeekdayLatestTime: (v) => set({ weekdayLatestTime: v }),
  updateWeekendLatestTime: (v) => set({ weekendLatestTime: v }),
  updateOffDays: (v) => set({ offDays: v }),
  updateStrongSubjects: (v) => set({ strongSubjects: v }),
  updateWeakSubjects: (v) => set({ weakSubjects: v }),
  reset: () => set({ ...defaultOnboardingData }),

  completeOnboarding: async () => {
    const userId = getUserId()
    if (!userId) return
    const state = get()
    const data: OnboardingData = {
      name: state.name,
      gender: state.gender,
      educationLevel: state.educationLevel,
      targetExam: state.targetExam,
      selectedArea: state.selectedArea,
      examDate: state.examDate,
      studyType: state.studyType,
      hasWeekdaySchool: state.hasWeekdaySchool,
      weekdayStartTime: state.weekdayStartTime,
      weekdayEndTime: state.weekdayEndTime,
      weekdayStudyHours: state.weekdayStudyHours,
      hasWeekendCourse: state.hasWeekendCourse,
      weekendStartTime: state.weekendStartTime,
      weekendStudyHours: state.weekendStudyHours,
      weekdayLatestTime: state.weekdayLatestTime,
      weekendLatestTime: state.weekendLatestTime,
      offDays: state.offDays,
      strongSubjects: state.strongSubjects,
      weakSubjects: state.weakSubjects,
    }
    setOnboardingCompleted(userId, true)
    saveOnboardingData(userId, data)
    try {
      await api.post('/UserProfile', data)
    } catch {
      // sync failure is non-blocking
    }
  },
}))
