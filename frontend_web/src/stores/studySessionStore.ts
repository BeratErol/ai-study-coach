import { create } from 'zustand'

export interface StudyTask {
  id: string
  subjectName: string
  emoji: string
  startTime: string
  endTime: string
  durationMinutes: number
  taskType: string
  isCompleted: boolean
  isMola: boolean
}

interface StudySessionStore {
  isOpen: boolean
  activeTask: StudyTask | null
  open: (task: StudyTask) => void
  close: () => void
}

export const useStudySessionStore = create<StudySessionStore>((set) => ({
  isOpen: false,
  activeTask: null,
  open: (task) => set({ isOpen: true, activeTask: task }),
  close: () => set({ isOpen: false, activeTask: null }),
}))
