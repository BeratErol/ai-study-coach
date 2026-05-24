import { useOnboardingStore } from '../../../stores/onboardingStore'
import StepHeader from './StepHeader'

interface AreaOption {
  icon: string
  title: string
  subtitle: string
  value: string
}

// ── YKS ──────────────────────────────────────────────────────────────────────
const yksOptions: AreaOption[] = [
  { icon: '📘', title: 'Sadece TYT', subtitle: 'Sadece TYT dersleri ve TYT denemeleri', value: 'sadece_tyt' },
  { icon: '🔢', title: 'Sayısal (MF)', subtitle: 'Matematik, Fizik, Kimya, Biyoloji', value: 'sayisal' },
  { icon: '⚖️', title: 'Eşit Ağırlık (TM)', subtitle: 'Matematik, Edebiyat, Tarih, Coğrafya', value: 'esit_agirlik' },
  { icon: '📚', title: 'Sözel (TS)', subtitle: 'Edebiyat, Tarih, Coğrafya, Felsefe', value: 'sozel' },
  { icon: '🌐', title: 'Dil', subtitle: 'Yabancı Dil (İngilizce)', value: 'dil' },
]

// ── KPSS ─────────────────────────────────────────────────────────────────────
const kpssOptions: AreaOption[] = [
  { icon: '💼', title: 'KPSS Lisans', subtitle: 'Genel Yetenek - Genel Kültür', value: 'kpss_lisans' },
  { icon: '📁', title: 'KPSS Önlisans', subtitle: 'Genel Yetenek - Genel Kültür', value: 'kpss_onlisans' },
]

// ── OkulSinavi ───────────────────────────────────────────────────────────────
const okulOrtaokulOptions: AreaOption[] = [
  { icon: '5️⃣', title: '5. Sınıf', subtitle: 'Türkçe, Matematik, Fen, Sosyal, İngilizce, Din', value: 'sinif_5' },
  { icon: '6️⃣', title: '6. Sınıf', subtitle: 'Türkçe, Matematik, Fen, Sosyal, İngilizce, Din', value: 'sinif_6' },
  { icon: '7️⃣', title: '7. Sınıf', subtitle: 'Türkçe, Matematik, Fen, Sosyal, İngilizce, Din', value: 'sinif_7' },
  { icon: '8️⃣', title: '8. Sınıf', subtitle: 'Türkçe, Matematik, Fen, İnkılap, İngilizce, Din', value: 'sinif_8' },
]

const okulLise910Options: AreaOption[] = [
  { icon: '9️⃣', title: '9. Sınıf', subtitle: 'Matematik, Fizik, Kimya, Biyoloji, Tarih, Edebiyat, Coğrafya, Din, İngilizce, Almanca', value: 'lise_9' },
  { icon: '🔟', title: '10. Sınıf', subtitle: 'Matematik, Fizik, Kimya, Biyoloji, Tarih, Edebiyat, Coğrafya, Din, İngilizce, Almanca, Felsefe', value: 'lise_10' },
]

const okulLise1112Options: AreaOption[] = [
  { icon: '🔢', title: '11-12 Sayısal (MF)', subtitle: 'Ortak Dersler + Seçmeli Matematik, Fizik, Kimya, Biyoloji', value: 'lise_1112_sayisal' },
  { icon: '⚖️', title: '11-12 Eşit Ağırlık (EA)', subtitle: 'Ortak Dersler + Seçmeli Matematik, Edebiyat, Coğrafya', value: 'lise_1112_ea' },
  { icon: '📚', title: '11-12 Sözel (TS)', subtitle: 'Ortak Dersler + Seçmeli Edebiyat, Coğrafya, Psikoloji', value: 'lise_1112_sozel' },
  { icon: '🌐', title: '11-12 Dil (YDT)', subtitle: 'Ortak Dersler + İngilizce, İngilizce Edebiyatı, Almanca', value: 'lise_1112_dil' },
]

const okulUniversiteOptions: AreaOption[] = [
  { icon: '💻', title: 'Yazılım / Bilgisayar', subtitle: 'Algoritma, Veri Yapıları, Diferansiyel…', value: 'uni_yazilim' },
  { icon: '🏥', title: 'Tıp', subtitle: 'Anatomi, Fizyoloji, Biyokimya, Histoloji…', value: 'uni_tip' },
  { icon: '⚖️', title: 'Hukuk', subtitle: 'Medeni, Borçlar, Ticaret, Ceza, İdare Hukuku…', value: 'uni_hukuk' },
  { icon: '🧠', title: 'Psikoloji', subtitle: 'Genel, Gelişim, Sosyal, Klinik Psikoloji…', value: 'uni_psikoloji' },
  { icon: '📈', title: 'İşletme / Ekonomi', subtitle: 'Muhasebe, Finans, Pazarlama, Yönetim…', value: 'uni_isletme' },
  { icon: '⚙️', title: 'Mühendislik', subtitle: 'Diferansiyel, Fizik, Kimya, Termodinamik…', value: 'uni_muhendislik' },
  { icon: '🏫', title: 'Eğitim / Öğretmenlik', subtitle: 'Eğitim Psikolojisi, Öğretim Yöntemleri…', value: 'uni_egitim' },
  { icon: '✏️', title: 'Diğer / Kendi Ekle', subtitle: 'Tüm dersleri kendin belirle', value: 'uni_diger' },
]

function GroupDivider({ label }: { label: string }) {
  return (
    <div
      className="inline-flex items-center px-4 py-2 rounded-xl text-base font-bold"
      style={{ background: '#EEF2FF', color: '#4F46E5', border: '1.5px solid rgba(79,70,229,0.25)' }}
    >
      {label}
    </div>
  )
}

function AreaCard({
  option,
  selected,
  onSelect,
}: {
  option: AreaOption
  selected: boolean
  onSelect: () => void
}) {
  return (
    <button
      onClick={onSelect}
      className={`w-full flex items-center gap-5 p-6 rounded-3xl border-2 cursor-pointer transition-all duration-200 select-none text-left ${
        selected
          ? 'border-indigo-600 bg-indigo-50 shadow-lg shadow-indigo-100'
          : 'border-gray-200 bg-white hover:border-indigo-300 hover:bg-indigo-50/40 hover:shadow-md'
      }`}
    >
      <span className="text-4xl flex-shrink-0">{option.icon}</span>
      <div className="flex-1">
        <p className={`font-bold text-xl ${selected ? 'text-indigo-700' : 'text-gray-900'}`}>
          {option.title}
        </p>
        <p className="text-gray-500 text-base mt-1">{option.subtitle}</p>
      </div>
      {selected && (
        <div className="w-9 h-9 bg-indigo-600 rounded-full flex items-center justify-center flex-shrink-0">
          <span className="text-white font-bold text-base">✓</span>
        </div>
      )}
    </button>
  )
}

export default function Step4AreaSelection() {
  const { targetExam, educationLevel, selectedArea, updateSelectedArea, updateStrongSubjects, updateWeakSubjects, updateCustomSubjects } =
    useOnboardingStore()

  function select(value: string) {
    updateSelectedArea(value)
    updateStrongSubjects([])
    updateWeakSubjects([])
    updateCustomSubjects([])
  }

  const isYKS = targetExam === 'YKS'
  const isKPSS = targetExam === 'KPSS'
  const isOkul = targetExam === 'OkulSinavi'

  let title = 'Alan Seçimi'
  let subtitle = 'Bu seçim ders havuzunu belirleyecek'
  let options: AreaOption[] = kpssOptions
  const isOkulLise = isOkul && educationLevel === 'lise'

  if (isYKS) {
    title = 'Hangi Alandan Hazırlanıyorsun?'
    subtitle = 'Bu seçim ders havuzunu belirleyecek'
    options = yksOptions
  } else if (isKPSS) {
    title = "Hangi KPSS'ye Hazırlanıyorsun?"
    subtitle = 'Bu seçim ders havuzunu belirleyecek'
    options = kpssOptions
  } else if (isOkul) {
    if (educationLevel === 'ortaokul') {
      title = 'Kaçıncı Sınıftasın?'
      subtitle = 'Sınıfına göre ders havuzu belirlenir'
      options = okulOrtaokulOptions
    } else if (educationLevel === 'lise') {
      title = 'Kaçıncı Sınıftasın?'
      subtitle = '11-12. sınıflar için alan seçimi de yapılır'
      options = [...okulLise910Options, ...okulLise1112Options]
    } else {
      title = 'Hangi Bölümdesin?'
      subtitle = 'Bölümüne uygun ders havuzu hazırlanır'
      options = okulUniversiteOptions
    }
  }

  return (
    <div className="w-full max-w-3xl mx-auto">
      <StepHeader emoji={isOkul ? '🏫' : '🗺️'} title={title} subtitle={subtitle} />

      {isOkulLise ? (
        <div className="space-y-4">
          <GroupDivider label="9. ve 10. Sınıf" />
          {okulLise910Options.map((opt) => (
            <AreaCard key={opt.value} option={opt} selected={selectedArea === opt.value} onSelect={() => select(opt.value)} />
          ))}
          <div className="pt-2">
            <GroupDivider label="11. ve 12. Sınıf — Alan Seçimi" />
          </div>
          {okulLise1112Options.map((opt) => (
            <AreaCard key={opt.value} option={opt} selected={selectedArea === opt.value} onSelect={() => select(opt.value)} />
          ))}
        </div>
      ) : (
        <div className="space-y-4">
          {options.map((opt) => (
            <AreaCard key={opt.value} option={opt} selected={selectedArea === opt.value} onSelect={() => select(opt.value)} />
          ))}
        </div>
      )}
    </div>
  )
}
