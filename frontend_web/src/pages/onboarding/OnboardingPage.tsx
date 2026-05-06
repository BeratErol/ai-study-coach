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
  return targetExam === 'YKS' || targetExam === 'KPSS'
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
    await store.completeOnboarding()
    navigate('/dashboard')
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
        if (currentStep === subjectsIdx) return store.weakSubjects.length > 0
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
    <div className="min-h-screen bg-slate-50 flex flex-col w-full">

      {/* PROGRESS BAR (sticky) */}
      <div className="sticky top-0 z-20 bg-white border-b border-gray-200 shadow-sm w-full">
        <div className="w-full max-w-2xl mx-auto px-6 py-4">
          <div className="flex justify-between items-center mb-3">
            <span className="text-indigo-600 font-bold text-lg">
              Adım {currentStep + 1}/{totalSteps}
            </span>
            <span className="text-gray-400 text-sm font-medium bg-gray-100 px-3 py-1 rounded-full">
              {stepNames[currentStep]}
            </span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2.5">
            <div
              className="bg-indigo-600 h-2.5 rounded-full transition-all duration-500 ease-out"
              style={{ width: `${progress}%` }}
            />
          </div>
        </div>
      </div>

      {/* İÇERİK */}
      <div className="flex-1 w-full overflow-y-auto pb-32">
        <div className="w-full max-w-2xl mx-auto px-6 py-8">
          {buildPages()[currentStep]}
        </div>
      </div>

      {/* ALT BUTON BARI (fixed) */}
      <div className="fixed bottom-0 left-0 right-0 z-20 bg-white border-t-2 border-gray-100 shadow-2xl">
        <div className="w-full max-w-2xl mx-auto px-6 py-5 flex justify-between items-center">
          {currentStep > 0 ? (
            <button
              onClick={goBack}
              className="flex items-center gap-2 px-6 py-3.5 rounded-2xl font-semibold text-base text-gray-600 hover:text-gray-900 hover:bg-gray-100 transition-all border-2 border-gray-200 hover:border-gray-300 cursor-pointer"
            >
              ← Geri
            </button>
          ) : (
            <div />
          )}

          <button
            onClick={valid ? goNext : undefined}
            disabled={!valid || finishing}
            className={`flex items-center gap-2 px-10 py-3.5 rounded-2xl font-bold text-base transition-all cursor-pointer ${
              valid && !finishing
                ? 'bg-indigo-600 hover:bg-indigo-700 text-white shadow-lg shadow-indigo-200 hover:shadow-xl hover:-translate-y-0.5'
                : 'bg-gray-200 text-gray-400 cursor-not-allowed'
            }`}
          >
            {finishing
              ? 'Oluşturuluyor...'
              : isLastStep
              ? 'Programımı Oluştur 🚀'
              : 'Devam Et →'}
          </button>
        </div>
      </div>
    </div>
  )
}
