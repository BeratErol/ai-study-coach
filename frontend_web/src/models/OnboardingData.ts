export interface OnboardingData {
  name: string
  gender: string
  educationLevel: string
  targetExam: string
  selectedArea: string
  examDate: string | null
  studyType: string
  hasWeekdaySchool: boolean
  weekdayStartTime: string
  weekdayEndTime: string
  weekdayStudyHours: number
  hasWeekendCourse: boolean
  weekendStartTime: string
  weekendStudyHours: number
  weekdayLatestTime: string
  weekendLatestTime: string
  offDays: number[]
  strongSubjects: string[]
  weakSubjects: string[]
}

export const defaultOnboardingData: OnboardingData = {
  name: '',
  gender: '',
  educationLevel: '',
  targetExam: '',
  selectedArea: '',
  examDate: null,
  studyType: '',
  hasWeekdaySchool: true,
  weekdayStartTime: '08:00',
  weekdayEndTime: '15:30',
  weekdayStudyHours: 3,
  hasWeekendCourse: false,
  weekendStartTime: '10:00',
  weekendStudyHours: 4,
  weekdayLatestTime: '22:30',
  weekendLatestTime: '23:30',
  offDays: [],
  strongSubjects: [],
  weakSubjects: [],
}
