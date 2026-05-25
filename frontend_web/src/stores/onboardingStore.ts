import { create } from 'zustand'
import api from '../services/api'
import { defaultOnboardingData, type OnboardingData } from '../models/OnboardingData'
import { getUserId } from '../services/tokenService'
import { setOnboardingCompleted, saveOnboardingData } from '../services/userPrefsService'
import { generateAndStorePlan } from '../services/studyPlanLocal'

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
  updateCustomSubjects: (v: string[]) => void
  reset: () => void
  completeOnboarding: () => Promise<void>
}

export const useOnboardingStore = create<OnboardingStore>((set, get) => ({
  ...defaultOnboardingData,

  updateName: (v) => set({ name: v }),
  updateGender: (v) => set({ gender: v }),
  updateEducationLevel: (v) => set({ educationLevel: v }),
  // Sınav/alan değiştiğinde önceki sınavın ders havuzundan seçilmiş
  // zayıf/güçlü/manuel listeler artık geçersiz — sıfırla. Aksi halde
  // yeni sınava ait olmayan dersler programa sızıyor.
  updateTargetExam: (v) => set((s) =>
    s.targetExam === v
      ? { targetExam: v }
      : { targetExam: v, weakSubjects: [], strongSubjects: [], customSubjects: [], selectedArea: '' }
  ),
  updateSelectedArea: (v) => set((s) =>
    s.selectedArea === v
      ? { selectedArea: v }
      : { selectedArea: v, weakSubjects: [], strongSubjects: [], customSubjects: [] }
  ),
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
  updateCustomSubjects: (v) => set({ customSubjects: v }),
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
      customSubjects: state.customSubjects,
    }
    // Önce backend'e yaz — başarısız olursa hata fırlat, çağıran ele alsın.
    // Profil backend'e kesin yazılmadan onboarding "tamamlandı" sayılmaz;
    // aksi halde başka cihazda onboarding tekrar gösterilir.
    await api.post('/UserProfile', data)

    // Backend kaydı başarılı → yerel cache ve plan
    setOnboardingCompleted(userId, true)
    saveOnboardingData(userId, data)
    generateAndStorePlan(userId, data)
  },
}))
