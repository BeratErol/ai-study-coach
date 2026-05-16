import { useEffect, useState, useCallback } from 'react'
import api from '../services/api'

export interface UserProfile {
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

export function useUserProfile() {
  const [profile, setProfile] = useState<UserProfile | null>(null)
  const [loading, setLoading] = useState(true)

  const refresh = useCallback(async () => {
    try {
      const r = await api.get('/UserProfile')
      setProfile(r.data)
    } catch {
      // profil yoksa null kalır
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    refresh()
  }, [refresh])

  return { profile, loading, refresh, setProfile }
}
