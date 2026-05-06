import type { OnboardingData } from '../models/OnboardingData'

const DAY_NAMES = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar']

export interface StudyBlock {
  subjectName: string
  startTime: string
  endTime: string
  durationMinutes: number
  isStrong: boolean
}

export interface StudyDay {
  date: string
  dayName: string
  blocks: StudyBlock[]
  totalMinutes: number
}

function toMins(time: string): number {
  const [h, m] = time.split(':').map(Number)
  return h * 60 + m
}

function minsToStr(mins: number): string {
  const h = Math.floor(mins / 60) % 24
  const m = mins % 60
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`
}

function netDaily(studyHours: number, hasCourse: boolean): number {
  let raw = studyHours * 60
  if (hasCourse) raw -= 60
  return raw < 60 ? 60 : raw
}

function strongBlockDur(subject: string): number {
  return subject.startsWith('AYT ') || subject.startsWith('ÖABT') ? 45 : 30
}

function weakBlockDur(subject: string): number {
  return subject.startsWith('AYT ') || subject.startsWith('ÖABT') ? 90 : 60
}

interface PendingBlock {
  subject: string
  duration: number
  isStrong: boolean
}

export function generateWeeklyPlan(data: OnboardingData): StudyDay[] {
  const now = new Date()
  const netWeekday = netDaily(data.weekdayStudyHours, data.hasWeekdaySchool)
  const netWeekend = netDaily(data.weekendStudyHours, data.hasWeekendCourse)

  const activeWeekdays = [0, 1, 2, 3, 4].filter((d) => !data.offDays.includes(d)).length
  const activeWeekend = [5, 6].filter((d) => !data.offDays.includes(d)).length
  const totalMins = activeWeekdays * netWeekday + activeWeekend * netWeekend

  const strongMins = Math.round(totalMins * 0.25)
  const weakMins = totalMins - strongMins

  const strongPerSubject =
    data.strongSubjects.length === 0 ? 0 : Math.round(strongMins / data.strongSubjects.length)
  const weakPerSubject =
    data.weakSubjects.length === 0 ? 0 : Math.round(weakMins / data.weakSubjects.length)

  const strongQueue: PendingBlock[] = []
  const weakQueue: PendingBlock[] = []

  for (const s of data.strongSubjects) {
    const dur = strongBlockDur(s)
    let rem = strongPerSubject
    while (rem >= dur) {
      strongQueue.push({ subject: s, duration: dur, isStrong: true })
      rem -= dur
    }
  }
  for (const s of data.weakSubjects) {
    const dur = weakBlockDur(s)
    let rem = weakPerSubject
    while (rem >= dur) {
      weakQueue.push({ subject: s, duration: dur, isStrong: false })
      rem -= dur
    }
  }

  const blockQueue: PendingBlock[] = []
  const wLen = weakQueue.length
  const sLen = strongQueue.length
  let wi = 0, si = 0
  for (let i = 0; i < wLen + sLen; i++) {
    if (wi < wLen && (si >= sLen || i % 2 === 0)) {
      blockQueue.push(weakQueue[wi++])
    } else if (si < sLen) {
      blockQueue.push(strongQueue[si++])
    }
  }

  const days: StudyDay[] = []
  let blockIdx = 0

  for (let offset = 0; offset < 7; offset++) {
    const date = new Date(now.getFullYear(), now.getMonth(), now.getDate() + offset)
    const dayIdx = (date.getDay() + 6) % 7 // 0=Mon..6=Sun
    const dayName = DAY_NAMES[dayIdx]

    if (data.offDays.includes(dayIdx)) {
      days.push({ date: date.toISOString(), dayName, blocks: [], totalMinutes: 0 })
      continue
    }

    const isWeekend = dayIdx >= 5
    const budget = isWeekend ? netWeekend : netWeekday
    const latestMins = toMins(isWeekend ? data.weekendLatestTime : data.weekdayLatestTime)

    const dayPending: PendingBlock[] = []
    let used = 0
    let idx = blockIdx
    while (idx < blockQueue.length) {
      const b = blockQueue[idx]
      if (used + b.duration > budget) break
      dayPending.push(b)
      used += b.duration
      idx++
    }

    const totalBreaks = dayPending.length > 1 ? (dayPending.length - 1) * 10 : 0
    const totalTime = dayPending.reduce((s, b) => s + b.duration, 0) + totalBreaks

    let startMins: number
    if (data.studyType === 'sabah') {
      if (!isWeekend && data.hasWeekdaySchool) {
        startMins = toMins(data.weekdayEndTime) + 60
      } else if (isWeekend && data.hasWeekendCourse) {
        startMins = toMins(data.weekendStartTime) + 180
      } else {
        startMins = 9 * 60
      }
    } else {
      startMins = latestMins - totalTime
      if (startMins < 14 * 60) startMins = 14 * 60
    }

    const blocks: StudyBlock[] = []
    let timePtr = startMins

    for (let pi = 0; pi < dayPending.length; pi++) {
      const pb = dayPending[pi]
      const startTime = minsToStr(timePtr)
      timePtr += pb.duration
      const endTime = minsToStr(timePtr)
      blocks.push({
        subjectName: pb.subject,
        startTime,
        endTime,
        durationMinutes: pb.duration,
        isStrong: pb.isStrong,
      })
      if (pi < dayPending.length - 1) timePtr += 10
      blockIdx++
    }

    const totalMinutes = blocks.reduce((s, b) => s + b.durationMinutes, 0)
    days.push({ date: date.toISOString(), dayName, blocks, totalMinutes })
  }

  return days
}
