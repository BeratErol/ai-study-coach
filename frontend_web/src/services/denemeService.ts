import api from './api'

// ─── Backend ile birebir uyumlu tipler ──────────────────────────────────────

export interface ExamSubjectInput {
  name: string
  correct: number
  wrong: number
}

export interface CreateExamDto {
  title: string
  date: string
  type: string
  subjects: ExamSubjectInput[]
}

export interface ExamSubjectNet {
  subjectName: string
  correct: number
  wrong: number
  net: number
}

export interface ExamRecord {
  id: number
  title: string
  date: string
  type: string
  totalNet: number
  subjectNets: ExamSubjectNet[]
}

// Backend ExamResponseDto → web ExamRecord
interface BackendExamDetail {
  id: number
  lessonName: string
  correct: number
  incorrect: number
  net: number
}
interface BackendExam {
  id: number
  title: string
  date: string
  type: string
  totalNet: number
  details: BackendExamDetail[]
}

function normalizeExam(e: BackendExam): ExamRecord {
  return {
    id: e.id,
    title: e.title ?? '',
    date: e.date,
    type: e.type ?? '',
    totalNet: e.totalNet ?? 0,
    subjectNets: (e.details ?? []).map((d) => ({
      subjectName: d.lessonName,
      correct: d.correct,
      wrong: d.incorrect,
      net: d.net,
    })),
  }
}

// web CreateExamDto → backend CreateExamDto gövdesi
function toBackendBody(dto: CreateExamDto) {
  return {
    title: dto.title,
    date: dto.date,
    type: dto.type,
    details: dto.subjects.map((s) => ({
      lessonName: s.name,
      correct: s.correct,
      incorrect: s.wrong,
    })),
  }
}

export const denemeService = {
  async getAll(): Promise<ExamRecord[]> {
    const res = await api.get('/Exam')
    const list = (res.data ?? []) as BackendExam[]
    return list.map(normalizeExam)
  },
  async create(dto: CreateExamDto): Promise<ExamRecord> {
    const res = await api.post('/Exam', toBackendBody(dto))
    return normalizeExam(res.data as BackendExam)
  },
  delete: (id: number) => api.delete(`/Exam/${id}`),
  async getAiRecommendation(): Promise<string> {
    const res = await api.get('/Exam/recommendation')
    return res.data?.recommendation ?? ''
  },
}
