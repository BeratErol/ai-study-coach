import api from './api'

export const studyPlanService = {
  getPlan: () => api.get('/StudyPlan'),
  getWeeklySummary: () => api.get('/StudySession/weekly-summary'),
  getExamCountdown: () => api.get('/Exam/countdown').catch(() => null),
}
