import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useOnboardingStore } from '../../stores/onboardingStore'
import Step1NameGender from './steps/Step1NameGender'
import Step2Education from './steps/Step2Education'
import Step3TargetExam from './steps/Step3TargetExam'
import Step4AreaSelection from './steps/Step4AreaSelection'
import Step4ExamDate from './steps/Step4ExamDate'
import Step5StudyType from './steps/Step5StudyType'
import Step6DailyRoutine from './steps/Step6DailyRoutine'
import Step7SleepTime from './steps/Step7SleepTime'
import Step8Subjects from './steps/Step8Subjects'

function hasAreaStep(targetExam: string) {
  return targetExam === 'YKS' || targetExam === 'KPSS' || targetExam === 'OkulSinavi'
}

function buildStepNames(withArea: boolean): string[] {
  return [
    'İsim',
    'Kademe',
    'Hedef Sınav',
    ...(withArea ? ['Alan Seçimi'] : []),
    'Sınav Tarihi',
    'Biyoritim',
    'Günlük Rutin',
    'Uyku Saati',
    'Dersler',
  ]
}

export default function OnboardingPage() {
  const navigate = useNavigate()
  const store = useOnboardingStore()
  const [currentStep, setCurrentStep] = useState(0)
  const [finishing, setFinishing] = useState(false)
  const [finishError, setFinishError] = useState<string | null>(null)

  const withArea = hasAreaStep(store.targetExam)
  const stepNames = buildStepNames(withArea)
  const totalSteps = stepNames.length
  const isLastStep = currentStep === totalSteps - 1

  function goNext() {
    if (isLastStep) {
      finish()
    } else {
      setCurrentStep((s) => s + 1)
    }
  }

  function goBack() {
    setCurrentStep((s) => Math.max(0, s - 1))
  }

  async function finish() {
    setFinishing(true)
    setFinishError(null)
    try {
      await store.completeOnboarding()
      navigate('/dashboard')
    } catch {
      // Backend'e profil yazılamadı → onboarding tamamlanmış sayılmaz.
      setFinishError('Profilin kaydedilemedi. İnternet bağlantını kontrol edip tekrar dene.')
      setFinishing(false)
    }
  }

  function isStepValid(): boolean {
    switch (currentStep) {
      case 0:
        return store.name.trim().length > 0 && store.gender.length > 0
      case 1:
        return store.educationLevel.length > 0
      case 2:
        return store.targetExam.length > 0
      case 3:
        if (withArea) return store.selectedArea.length > 0
        return true
      default: {
        const studyTypeIdx = withArea ? 5 : 4
        const subjectsIdx = withArea ? 8 : 7
        if (currentStep === studyTypeIdx) return store.studyType.length > 0
        if (currentStep === subjectsIdx) {
          // uni_diger: kullanıcı tüm dersleri manuel ekler → customSubjects yeterli
          if (store.targetExam === 'OkulSinavi' && store.selectedArea === 'uni_diger') {
            return store.customSubjects.length > 0
          }
          return store.weakSubjects.length > 0
        }
        return true
      }
    }
  }

  function buildPages(): React.ReactNode[] {
    const pages: React.ReactNode[] = [
      <Step1NameGender key="1" />,
      <Step2Education key="2" />,
      <Step3TargetExam key="3" />,
    ]
    if (withArea) pages.push(<Step4AreaSelection key="area" />)
    pages.push(<Step4ExamDate key="date" onSkip={goNext} />)
    pages.push(<Step5StudyType key="5" />)
    pages.push(<Step6DailyRoutine key="6" />)
    pages.push(<Step7SleepTime key="7" />)
    pages.push(<Step8Subjects key="8" />)
    return pages
  }

  const valid = isStepValid()
  const progress = ((currentStep + 1) / totalSteps) * 100

  return (
    <div className="min-h-screen flex flex-col" style={{ background: '#F8F7FF' }}>

      {/* PROGRESS BAR (sticky) */}
      <div className="sticky top-0 z-20 shadow-sm" style={{ background: '#ffffff', borderBottom: '2px solid #E5E7EB' }}>
        <div className="max-w-5xl mx-auto px-8 py-5">
          <div className="flex justify-between items-center mb-3">
            <div className="flex items-center gap-3">
              <div
                className="w-12 h-12 rounded-xl flex items-center justify-center text-white font-extrabold text-xl"
                style={{ background: 'linear-gradient(135deg, #4F46E5, #6D28D9)' }}
              >
                {currentStep + 1}
              </div>
              <div>
                <span className="text-indigo-600 font-extrabold text-2xl block leading-tight">
                  Adım {currentStep + 1}/{totalSteps}
                </span>
                <span className="text-gray-500 text-base">{stepNames[currentStep]}</span>
              </div>
            </div>
            <div className="flex gap-1.5">
              {stepNames.map((_, i) => (
                <div
                  key={i}
                  className="h-2 rounded-full transition-all duration-300"
                  style={{
                    width: i <= currentStep ? '28px' : '8px',
                    background: i <= currentStep ? '#4F46E5' : '#E5E7EB',
                  }}
                />
              ))}
            </div>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-3">
            <div
              className="h-3 rounded-full transition-all duration-500 ease-out"
              style={{
                width: `${progress}%`,
                background: 'linear-gradient(90deg, #4F46E5, #6D28D9)',
              }}
            />
          </div>
        </div>
      </div>

      {/* İÇERİK */}
      <div className="flex-1 overflow-y-auto pb-44">
        <div className="w-full flex justify-center px-8 py-12">
          <div className="w-full max-w-4xl">
            {buildPages()[currentStep]}
          </div>
        </div>
      </div>

      {/* ALT BUTON BARI (fixed) */}
      <div
        className="fixed bottom-0 left-0 right-0 z-20 shadow-2xl"
        style={{ background: '#ffffff', borderTop: '2px solid #E5E7EB' }}
      >
        {finishError && (
          <div className="w-full px-10 pt-4">
            <div className="px-5 py-3 rounded-xl text-base font-medium" style={{ background: '#FEF2F2', color: '#DC2626', border: '1.5px solid #FCA5A5' }}>
              ⚠️ {finishError}
            </div>
          </div>
        )}
        <div className="w-full px-10 py-6 flex gap-4 items-center justify-between">
          {currentStep > 0 ? (
            <button
              onClick={goBack}
              className="flex items-center justify-center gap-2 h-16 w-72 rounded-2xl font-bold text-lg cursor-pointer transition-all shrink-0"
              style={{ background: '#F3F4F6', color: '#374151', border: '2px solid #E5E7EB' }}
              onMouseEnter={(e) => {
                e.currentTarget.style.background = '#E5E7EB'
                e.currentTarget.style.borderColor = '#D1D5DB'
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.background = '#F3F4F6'
                e.currentTarget.style.borderColor = '#E5E7EB'
              }}
            >
              ← Geri
            </button>
          ) : (
            <div />
          )}

          <button
            onClick={valid ? goNext : undefined}
            disabled={!valid || finishing}
            className="flex items-center justify-center gap-2 h-16 w-72 rounded-2xl font-extrabold text-xl cursor-pointer transition-all text-white shrink-0"
            style={{
              background: valid && !finishing
                ? 'linear-gradient(135deg, #4F46E5, #6D28D9)'
                : '#D1D5DB',
              color: valid && !finishing ? '#ffffff' : '#9CA3AF',
              boxShadow: valid && !finishing ? '0 8px 24px rgba(79,70,229,0.35)' : 'none',
              cursor: !valid || finishing ? 'not-allowed' : 'pointer',
            }}
          >
            {finishing
              ? '⏳ Oluşturuluyor...'
              : isLastStep
              ? '🚀 Programımı Oluştur'
              : 'Devam Et →'}
          </button>
        </div>
      </div>
    </div>
  )
}
