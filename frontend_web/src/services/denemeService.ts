import api from './api'

export interface ExamDetail {
  id: number
  lessonName: string
  correct: number
  incorrect: number
  net: number
}

export interface ExamRecord {
  id: number
  title: string
  date: string
  type: string
  totalNet: number
  details: ExamDetail[]
}

// Form → backend gövdesi
export interface CreateExamBody {
  title: string
  date: string
  type: string
  details: { lessonName: string; correct: number; incorrect: number }[]
}

interface BackendExam {
  id: number
  title: string
  date: string
  type: string
  totalNet: number
  details: ExamDetail[]
}

function normalize(e: BackendExam): ExamRecord {
  return {
    id: e.id,
    title: e.title ?? '',
    date: e.date,
    type: e.type ?? '',
    totalNet: e.totalNet ?? 0,
    details: (e.details ?? []).map((d) => ({
      id: d.id,
      lessonName: d.lessonName,
      correct: d.correct,
      incorrect: d.incorrect,
      net: d.net,
    })),
  }
}

export const denemeService = {
  async getAll(): Promise<ExamRecord[]> {
    const res = await api.get('/Exam')
    return ((res.data ?? []) as BackendExam[]).map(normalize)
  },
  async create(body: CreateExamBody): Promise<ExamRecord> {
    const res = await api.post('/Exam', body)
    return normalize(res.data as BackendExam)
  },
  async update(id: number, body: CreateExamBody): Promise<ExamRecord> {
    const res = await api.put(`/Exam/${id}`, body)
    return normalize(res.data as BackendExam)
  },
  delete: (id: number) => api.delete(`/Exam/${id}`),
  async getAiRecommendation(): Promise<string> {
    const res = await api.get('/Exam/recommendation')
    return res.data?.recommendation ?? ''
  },
}
