import type { OnboardingData } from '../models/OnboardingData'

const DAY_NAMES = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar']

export interface StudyBlock {
  id: string
  subjectName: string
  startTime: string
  endTime: string
  durationMinutes: number
  isStrong: boolean
  taskType: string
  isMola: boolean
  emoji: string
}

export interface StudyDay {
  date: string
  dayName: string
  blocks: StudyBlock[]
  totalMinutes: number
  isOffDay: boolean
}

function toMins(time: string): number {
  const [h, m] = time.split(':').map(Number)
  return h * 60 + m
}

// Yerel tarihi YYYY-MM-DD olarak döndürür (toISOString UTC kayması yapmasın diye)
function localDateStr(d: Date): string {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

function minsToStr(mins: number): string {
  const h = Math.floor(mins / 60) % 24
  const m = mins % 60
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`
}

// Kullanıcının seçtiği saat = tam bütçe (mobil ile birebir)
function calcNetMinutes(rawHours: number): number {
  return Math.min(600, Math.max(60, rawHours * 60))
}

// Başlangıç saatini mobildeki _roundStartTime mantığıyla yuvarla
function roundStartTime(mins: number): number {
  const h = Math.floor(mins / 60)
  const m = mins % 60
  if (m <= 5) return h * 60
  if (m <= 20) return h * 60 + 10
  if (m <= 35) return h * 60 + 30
  if (m <= 50) return h * 60 + 40
  return ((h + 1) % 24) * 60
}

function getSubjectEmoji(name: string): string {
  if (name.includes('Matematik') || name.includes('Geometri')) return '📐'
  if (name.includes('Fizik')) return '⚡'
  if (name.includes('Kimya')) return '🧪'
  if (name.includes('Biyoloji')) return '🧬'
  if (name.includes('Türkçe')) return '📖'
  if (name.includes('Edebiyat')) return '✏️'
  if (name.includes('Tarih') || name.includes('İnkılap')) return '🏛️'
  if (name.includes('Coğrafya')) return '🌍'
  if (name.includes('Felsefe')) return '💭'
  if (name.includes('İngilizce') || name.includes('YDT') || name.includes('Dil')) return '🇬🇧'
  if (name.includes('Din')) return '☪️'
  if (name.includes('Vatandaşlık')) return '🏛️'
  if (name.includes('Fen')) return '🔬'
  return '📚'
}

interface ProtoBlock {
  id: string
  subjectName: string
  durationMinutes: number
  isStrong: boolean
  taskType: string
  isMola: boolean
  emoji: string
}

/**
 * Belirli güne ait blokları döngüsel dolgu mantığıyla oluşturur (mobil ile birebir).
 * Güçlü blok: 30 dk. Zayıf blok: 60 dk. Mola bütçeden düşülmez.
 */
function buildDayBlocks(
  weakSubjects: string[],
  strongSubjects: string[],
  net: number,
  isWeekend: boolean,
  data: OnboardingData,
  dayOffset: number,
  weakOccurrences: Record<string, number>,
  strongOccurrences: Record<string, number>,
): StudyBlock[] {
  const weakDur = 60
  const strongDur = 30

  const hasWeak = weakSubjects.length > 0
  const hasStrong = strongSubjects.length > 0
  if (!hasWeak && !hasStrong) return []

  // Mola süresi (bütçeden düşülmez)
  const molaDur = net >= 360 ? 60 : 30

  const minBlock = hasWeak ? weakDur : strongDur
  if (net < minBlock) return []

  const budgetForStudy = net
  if (budgetForStudy <= 0) return []

  // w×60 + s×30 = net, s ≤ w olacak şekilde çöz
  let targetWeak = 0
  let targetStrong = 0
  if (!hasWeak) {
    targetStrong = Math.floor(budgetForStudy / strongDur)
  } else if (!hasStrong) {
    targetWeak = Math.floor(budgetForStudy / weakDur)
  } else {
    let bestW = 0
    let bestS = 0
    let bestRemainder = budgetForStudy
    for (let w = 1; w * weakDur <= budgetForStudy; w++) {
      const remaining = budgetForStudy - w * weakDur
      const s = Math.min(w, Math.floor(remaining / strongDur))
      const remainder = remaining - s * strongDur
      if (remainder < bestRemainder) {
        bestRemainder = remainder
        bestW = w
        bestS = s
      }
      if (remainder === 0) break
    }
    targetWeak = bestW
    targetStrong = bestS
  }

  // Önceki günlerdeki toplam görünüme göre cursor başlangıcı (adil rotasyon)
  const totalWeakSoFar = Object.values(weakOccurrences).reduce((s, v) => s + v, 0)
  const totalStrongSoFar = Object.values(strongOccurrences).reduce((s, v) => s + v, 0)
  let weakCursor = weakSubjects.length > 0 ? totalWeakSoFar % weakSubjects.length : 0
  let strongCursor = strongSubjects.length > 0 ? totalStrongSoFar % strongSubjects.length : 0

  const weakBlocks: ProtoBlock[] = []
  const strongBlocks: ProtoBlock[] = []
  let counter = 0

  for (let i = 0; i < targetWeak; i++) {
    const subject = weakSubjects[weakCursor % weakSubjects.length]
    weakCursor++
    const count = weakOccurrences[subject] ?? 0
    weakOccurrences[subject] = count + 1
    weakBlocks.push({
      id: `w_${dayOffset}_${counter++}`,
      subjectName: subject,
      durationMinutes: weakDur,
      isStrong: false,
      taskType: count % 2 === 0 ? 'konu_anlatimi' : 'soru_cozumu',
      isMola: false,
      emoji: getSubjectEmoji(subject),
    })
  }

  for (let i = 0; i < targetStrong; i++) {
    const subject = strongSubjects[strongCursor % strongSubjects.length]
    strongCursor++
    const count = strongOccurrences[subject] ?? 0
    strongOccurrences[subject] = count + 1
    strongBlocks.push({
      id: `s_${dayOffset}_${counter++}`,
      subjectName: subject,
      durationMinutes: strongDur,
      isStrong: true,
      taskType: count % 2 === 0 ? 'soru_cozumu' : 'konu_anlatimi',
      isMola: false,
      emoji: getSubjectEmoji(subject),
    })
  }

  const weakBlockCount = weakBlocks.length
  const rawBlocks: ProtoBlock[] = [...weakBlocks, ...strongBlocks]
  if (rawBlocks.length === 0) return []

  // Mola bloğu — zayıf blokların ortasına eklenir
  const molaBlock: ProtoBlock = {
    id: `m_${dayOffset}_mola`,
    subjectName: 'Mola',
    durationMinutes: molaDur,
    isStrong: false,
    taskType: 'mola',
    isMola: true,
    emoji: '☕',
  }

  const fitting: ProtoBlock[] = [...rawBlocks]
  if (weakBlockCount > 0) {
    const molaAfterWeakN = Math.min(weakBlockCount, Math.max(1, Math.ceil(weakBlockCount / 2)))
    fitting.splice(molaAfterWeakN, 0, molaBlock)
  }

  // Başlangıç saati
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
    const latestStr = isWeekend ? data.weekendLatestTime : data.weekdayLatestTime
    const totalSched =
      fitting.reduce((s, b) => s + b.durationMinutes, 0) +
      (fitting.length > 1 ? (fitting.length - 1) * 10 : 0)
    // Gece kuşu: "en geç" 00:00–04:00 arası seçildiyse ertesi günün saati
    // anlamına gelir (örn. "01:00" = bugün 25:00). +24 saat ekle ki son ders
    // gerçekten o saatte bitsin.
    let latestMins = toMins(latestStr)
    if (latestMins < 4 * 60) latestMins += 24 * 60
    startMins = latestMins - totalSched
    if (startMins < 14 * 60) startMins = 14 * 60
  }

  // Saatleri ata
  let current = roundStartTime(startMins)
  const result: StudyBlock[] = []
  for (let i = 0; i < fitting.length; i++) {
    const b = fitting[i]
    const start = current
    const end = current + b.durationMinutes
    result.push({
      id: b.id,
      subjectName: b.subjectName,
      startTime: minsToStr(start),
      endTime: minsToStr(end),
      durationMinutes: b.durationMinutes,
      isStrong: b.isStrong,
      taskType: b.taskType,
      isMola: b.isMola,
      emoji: b.emoji,
    })
    if (i < fitting.length - 1) current = end + 10
  }

  return result
}

export function generateWeeklyPlan(data: OnboardingData): StudyDay[] {
  const now = new Date()
  const days: StudyDay[] = []
  const weakOccurrences: Record<string, number> = {}
  const strongOccurrences: Record<string, number> = {}

  for (let offset = 0; offset < 7; offset++) {
    const date = new Date(now.getFullYear(), now.getMonth(), now.getDate() + offset)
    const dayIdx = (date.getDay() + 6) % 7 // 0=Pzt … 6=Paz
    const dayName = DAY_NAMES[dayIdx]

    if (data.offDays.includes(dayIdx)) {
      days.push({ date: localDateStr(date), dayName, blocks: [], totalMinutes: 0, isOffDay: true })
      continue
    }

    const isWeekend = dayIdx >= 5
    const net = calcNetMinutes(isWeekend ? data.weekendStudyHours : data.weekdayStudyHours)
    const blocks = buildDayBlocks(
      data.weakSubjects, data.strongSubjects, net, isWeekend, data, offset,
      weakOccurrences, strongOccurrences,
    )
    const totalMinutes = blocks.filter((b) => !b.isMola).reduce((s, b) => s + b.durationMinutes, 0)
    days.push({ date: localDateStr(date), dayName, blocks, totalMinutes, isOffDay: false })
  }

  return days
}
