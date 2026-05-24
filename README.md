# 🎓 AI Study Coach

**Yapay zeka destekli, kişiselleştirilmiş öğrenci çalışma koçu.** Öğrencinin sınav hedefine, güçlü/zayıf derslerine ve günlük müsaitliğine göre haftalık program üretir; çalışma süreci boyunca rehberlik eder, ilerlemeyi takip eder ve gerçek zamanlı AI koç sohbetiyle yön gösterir.

Mobil (Flutter) ve web (React) istemcileri **aynı backend** üzerinden birebir senkron çalışır: bir cihazda yaptığın değişiklik diğerine anında yansır.

> Hedef kitle: **YKS (TYT/AYT/YDT), LGS, KPSS (Lisans/Önlisans/Ortaöğretim), ALES, YDS, ÖABT, Okul Sınavları** ve diğer Türk eğitim sistemine yönelik sınavlara hazırlanan öğrenciler.

---

## 🚀 Öne Çıkan Özellikler

### 🧠 Akıllı Program Üretimi
- **Onboarding sihirbazı**: İsim, cinsiyet, eğitim düzeyi (ortaokul/lise/üniversite/mezun), hedef sınav, alan, sınav tarihi, çalışma tipi (sabah kuşu / gece kuşu), günlük çalışma saatleri, okul/kurs durumu, en geç ders saati, off-day seçimi, güçlü/zayıf ders işaretleme.
- **Otomatik haftalık plan**: Algoritma; zayıf dersleri öncelikli (kırmızı bölüm), güçlü dersleri pekiştirme (turuncu, zayıflar bitince açılır) olarak yerleştirir.
- **Görev türü rotasyonu**: Zayıf ders → konu anlatımı → soru çözümü; güçlü ders → soru çözümü → konu anlatımı sırasıyla döngüsel ilerler.
- **Mola blokları**: 30 dakikalık mola; zayıf dersler arasına stratejik olarak yerleştirilir.
- **Gece kuşu desteği**: "En geç" saati 00:00 sonrası seçildiğinde plan ertesi günün gece saatlerine kadar uzanır; saatler doğru sırada listelenir.
- **OkulSinavi + "Diğer"**: Tamamen manuel ders havuzu — kullanıcı kendi derslerini ekler.
- **Akıllı yenileme**: Sadece saat/biyoritim değiştiyse plan yenilenir ama tamamlanan dersler korunur. Sınav türü/alan/dersler değiştiyse bugünün konu atamaları ve tamamlamaları sıfırlanır (eski blok id'leri yeni planla uyumsuz olduğu için).

### ⏱️ Çalışma Oturumu (Pomodoro)
- Görsel ilerleme dairesi + gerçek zamanlı geri sayım.
- 5 dakikalık mola modu.
- **Ortam sesleri**: yağmur, şömine, orman, kuş, kafe (`audioplayers` ile arka plan stream).
- **Study With Me YouTube yayınları**: çalışma yayınlarına gömülü erişim.
- Süre bitince görev otomatik tamamlanır + ders detayı kalıcı kaydedilir.

### 📈 Gelişimim (Progress Hub)
- **XP sistemi**: Tamamlanan oturum +10 XP, çözülen soru +1 XP, aktif gün +5 XP.
- **Seviyeler**: 🌱 Çırak → 📖 Acemi → 📚 Gelişen → 🎓 Uzman.
- **Streak (🔥 günlük seri)**: Ardışık aktif gün sayısı.
- **Bugün / Tüm Zamanlar filtresi**:
  - Tamamlanan oturum sayısı, toplam çalışma süresi, çözülen soru sayısı, dinlenme günü sayısı.
  - **Tüm Zamanlar**: Ders Dağılımı + Soru Çözümleri **günlere göre gruplanır** (her gün başlığıyla ayrı kart).
- **Soru Gelişimi**: O gün hangi dersten kaç soru çözüldüğünü gir; backend `QuestionLog` tablosunda saklanır.
- **Geçmişi Gör**: Takvim açar; bir güne dokununca o günün detaylı raporu:
  - ✅ Tamamlanan dersler (isim + tür + süre + konu)
  - ⏳ Tamamlanmayan oturumlar (programdaydı ama yapılmadı)
  - 📝 Çözülen sorular (ders × adet)
- Gelecek günler için **planlanan program**, dinlenme günleri için **"Dinlenme günü"** etiketi.

### 📝 Denemeler
- **Çok sayıda sınav türü desteği**: TYT, AYT (Sayısal/EA/Sözel/Dil), Branş denemeleri, LGS, KPSS (Lisans/Önlisans/Ortaöğretim), ALES, YDS, ÖABT, Okul Sınavı.
- Ders bazında **doğru/yanlış sayısı** girişi → otomatik **net hesaplama** (−0.25 yanlış kuralı).
- Sınav türüne göre **gerçekçi placeholder örnekleri** ("3D Yayınları TYT Genel", "2024 KPSS Çıkmış Sorular", "Pegem ÖABT Branş" vb.).
- **Net Özeti**: en yüksek, ortalama, son deneme netleri.
- **Net Trend grafiği**: zaman içinde net + kayan ortalama (Recharts/fl_chart).
- **Denge Radarı**: ders bazında güçlü/zayıf görseli (3+ dersi olan sınav türlerinde).
- **Koç Analizi**: 3+ deneme olduğunda AI yorumu.
- **Karşılaştırma**: 2-3 deneme yan yana karşılaştırma.
- **Branş denemeleri**: Ders adına göre gruplanır — her ders kendi net özeti, trendi, koç analizi ve geçmiş listesine sahip olur.

### 👤 Profil & Senkron
- **Notlarım**: hızlı not ekle/sil (onay ister).
- **Akademik Hedef**: hedef üniversite/lise/iş + gereken net; sınav türüne göre detaylı placeholder örnekleri.
- **Ders Profilim**: güçlü/zayıf ders chip seçimi. `OkulSinavi`'nde manuel ders ekleme alanı açılır.
- **Zaman ve Biyoritim**: studyType (sabah/gece kuşu), off-day'ler, hafta içi/sonu okul/kurs durumu, başlangıç/bitiş/çalışma saatleri, en geç saat.
- **Sınav Tarihi ve Hedef**: hedef sınav, alan, sınav tarihi → ana sayfa "Kalan Gün" rozetini günceller.
- **Ayarlar**: 🌙 Karanlık Mod, 🚪 Çıkış.
- Her değişiklik **backend AppState'e ve UserProfile'a push edilir**; diğer cihaz bir sonraki giriş/hydrate'te aynı veriyi indirir.

### 🤖 AI Koç Sohbet
- Google Gemini 2.5 Flash tabanlı.
- **Öğrenci bağlamına tam erişim**: isim, hedef sınav, alan, genel zayıf/güçlü dersler, bugünkü programdaki zayıf/güçlü ayrımı, her görevin **tamamlanma durumu** (✓/⬜), ilerleme yüzdesi.
- **Davranış kuralları**:
  - Hiçbir işlemi kendi yapmaz — sadece **adım adım yol gösterir** ("Ana sayfada sağ alttaki + Görev butonuna bas → Konuları Düzenle → ...").
  - "Bugün ne çalışmalıyım?" sorularında sadece **bugün programda olan VE henüz tamamlanmamış** dersleri önerir.
  - "Sırada ne var?" → tamamlananları atlar, kalanları sırasıyla söyler.
  - "Hepsini bitirdim!" → tebrik + yarına hazırlık önerisi.
  - Siyaset/haber/ödev çözme gibi konu dışı sorulara nazikçe yönlendirme yapar.
- **Çoklu sohbet**: En fazla 3 paralel sohbet; başlık otomatik ilk mesajdan üretilir, düzenlenebilir, silinebilir.

### 🔄 Tam Cihaz-Arası Senkron (Mobile ↔ Web)
- Tüm kullanıcı verisi (haftalık plan, notlar, sohbetler, tamamlanan dersler, soru çözümleri, denemeler, konu atamaları, dinlenme günleri, akademik hedef) **backend `AppState` tablosuna** push edilir.
- Login + Dashboard mount sırasında `hydrateAppState` çağrılır; backend'deki güncel veri yerel cache'e indirilir.
- Web ve mobil **aynı JSON şemalarını** kullanır (mobil tarafta `StudyDay.date` `YYYY-MM-DD` string, `startTime/endTime` `"HH:MM"` formatında — webin formatıyla birebir).
- Profil değişikliği sonrası plan iki cihazda da otomatik güncellenir.

### 🎨 Tasarım ve UX
- **Karanlık/Aydınlık tema**: CSS custom property tabanlı, anlık geçiş, kart/sınır/yüzey renkleri otomatik adapte.
- **Tutarlı renk paleti**: indigo (primary), turuncu (warning/manuel), yeşil (success), kırmızı (öncelik/danger).
- **Mobile gesture-friendly**: tüm sheet/dialog'lar `MediaQuery.padding.bottom` ile telefon navigasyon barını tolere eder.
- **Web sidebar**: sınav etiketi okunabilir formatta ("OkulSinavi" → "Okul Sınavı"), her route geçişinde otomatik refresh.
- **PDF indir**: haftalık plan modalından bir tıklamayla PDF olarak dışa aktarılabilir.

---

## 🧱 Teknoloji Yığını

| Katman | Teknolojiler |
|---|---|
| **Backend** | ASP.NET Core 9, Entity Framework Core, PostgreSQL 17, JWT Bearer, BCrypt.Net, Google Gemini API |
| **Mobil** | Flutter 3, Riverpod 2, GoRouter, Dio, SharedPreferences, flutter_secure_storage, table_calendar, fl_chart, audioplayers, intl, pdf + printing |
| **Web** | React 19, Vite 8, TypeScript, Tailwind CSS 4, Zustand, React Router 6, Recharts, Axios |

---

## 🗂️ Proje Yapısı

```
ai-study-coach/
├── Backend/                          # ASP.NET Core 9 API
│   ├── Controllers/
│   │   ├── AuthController.cs         # /Auth/register, /Auth/login
│   │   ├── UserProfileController.cs  # /UserProfile GET/POST
│   │   ├── AppStateController.cs     # /AppState — generic key-value senkron
│   │   ├── LessonController.cs       # Ders CRUD
│   │   ├── TopicController.cs        # Konu CRUD
│   │   ├── StudySessionController.cs # Çalışma oturumu
│   │   ├── ExamController.cs         # Deneme sonuçları
│   │   ├── GelisimimController.cs    # Stats, XP, takvim, ders dağılımı, günlük rapor
│   │   └── AiController.cs           # /Ai/chat, /Ai/plan, /Ai/coach-message
│   ├── Models/
│   │   ├── User.cs, UserProfile.cs
│   │   ├── AppState.cs               # (UserId, Key, ValueJson) — senkron deposu
│   │   ├── StudySession.cs, Exam.cs, ExamDetail.cs
│   │   ├── Lesson.cs, Topic.cs
│   │   └── QuestionLog.cs
│   ├── Services/
│   │   ├── AiService.cs              # Gemini entegrasyonu, koç prompt'u
│   │   ├── UserProfileService.cs
│   │   └── ...
│   ├── DTOs/                         # Request/response modelleri
│   ├── Data/AppDbContext.cs          # EF Core
│   └── Migrations/
│
├── frontend_mobile/                  # Flutter uygulaması
│   ├── lib/
│   │   ├── core/                     # Tema, router, sabitler, global navigator
│   │   ├── data/                     # exam_type_data, subjects_data, subject_topics
│   │   ├── models/
│   │   ├── providers/                # Riverpod (chatbot, study_plan, gelisimim, onboarding)
│   │   ├── screens/
│   │   │   ├── login_screen.dart, register_screen.dart
│   │   │   ├── onboarding/, onboarding_screen.dart
│   │   │   ├── shell_screen.dart     # Bottom nav: 4 sekme
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── gelisimim_screen.dart
│   │   │   ├── gelisimim/            # Takvim, soru gelişimi, günlük rapor sheet'leri
│   │   │   ├── denemeler_screen.dart, exam_result_screen.dart
│   │   │   ├── profile_screen.dart
│   │   │   └── study_session_screen.dart
│   │   ├── services/
│   │   │   ├── api_service.dart      # Dio singleton + JWT interceptor
│   │   │   ├── app_state_service.dart # Push/hydrate (web ile ortak)
│   │   │   ├── user_prefs_service.dart
│   │   │   ├── token_service.dart
│   │   │   ├── gelisimim_service.dart
│   │   │   └── study_plan_generator.dart
│   │   └── widgets/                  # task_card, chatbot_fab, quick_note_sheet, ...
│   ├── assets/
│   │   ├── icon/app_icon.png         # Mor gradient + mezuniyet kepi
│   │   ├── sounds/                   # Ortam sesi mp3'leri
│   │   └── fonts/
│   └── scripts/make_icon.py          # APK ikonunu Python+Pillow ile üretir
│
└── frontend_web/                     # React + Vite uygulaması
    ├── public/app_icon.png
    └── src/
        ├── components/
        │   ├── Sidebar.tsx           # Sol bar, route bazlı profile refresh
        │   ├── ChatbotPanel.tsx
        │   └── StudySessionModal.tsx
        ├── hooks/                    # useAuth, useUserProfile
        ├── pages/
        │   ├── LoginPage.tsx, RegisterPage.tsx
        │   ├── onboarding/           # Step1..Step8
        │   ├── DashboardPage.tsx
        │   ├── GelisimimPage.tsx
        │   ├── DenemelorPage.tsx
        │   └── ProfilePage.tsx
        ├── services/
        │   ├── api.ts                # Axios + JWT interceptor
        │   ├── appStateService.ts    # pushAppState, hydrateAppState
        │   ├── userPrefsService.ts
        │   ├── localData.ts          # quick_notes, manual_tasks, completed_tasks/lessons, topic_assignments, rest_days
        │   ├── studyPlanLocal.ts, studyPlanGenerator.ts
        │   └── gelisimimService.ts
        ├── stores/                   # Zustand: chatbotStore
        ├── data/                     # subjects, exam_types
        └── models/                   # OnboardingData tipi
```

---

## ⚙️ Kurulum

### Gereksinimler
- .NET 9 SDK
- PostgreSQL 14+ (Windows için 17 kullanılıyor)
- Flutter 3.19+
- Node.js 20+

### 1. Veritabanı
```sql
-- PostgreSQL'de yeni veritabanı oluştur
CREATE DATABASE aistudycoach;
```

### 2. Backend
`Backend/appsettings.json` (veya `appsettings.Development.json`):
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Database=aistudycoach;Username=postgres;Password=YOUR_PASSWORD"
  },
  "JwtSettings": {
    "Secret": "EN_AZ_32_KARAKTER_RASTGELE_GIZLI_ANAHTAR"
  },
  "GeminiApiKey": "YOUR_GEMINI_API_KEY"
}
```

```bash
cd Backend
dotnet ef database update
dotnet run
# → http://0.0.0.0:5228  (tüm ağ arabirimleri)
```

### 3. Web
```bash
cd frontend_web
npm install
npm run dev
# → http://localhost:5173
```
`vite.config.ts` proxy `/api` → `http://localhost:5228`.

### 4. Mobil
Mobilde **fiziksel cihaz** için bilgisayarın LAN IP'sini `lib/utils/constants.dart` içine yaz:
```dart
return 'http://192.168.X.X:5228/api';
```

```bash
cd frontend_mobile
flutter pub get
flutter run                      # debug
flutter build apk --release      # APK üretimi
flutter install                  # USB'den telefona kurulum
```

**APK ikon değişikliği** için:
```bash
python frontend_mobile/scripts/make_icon.py   # assets/icon/app_icon.png üretir
cd frontend_mobile
dart run flutter_launcher_icons               # Android+iOS tüm boyutları üretir
```

---

## 🔌 API Özeti

| Yöntem | Endpoint | Açıklama |
|---|---|---|
| POST | `/api/Auth/register` | Kayıt |
| POST | `/api/Auth/login` | Giriş → JWT |
| GET/POST | `/api/UserProfile` | Onboarding/profil verisi |
| GET | `/api/AppState` | Tüm key-value senkron verisi |
| PUT | `/api/AppState/{key}` | Tek anahtar upsert |
| DELETE | `/api/AppState/{key}` | Anahtar sil |
| GET/POST/DELETE | `/api/Lesson` | Ders CRUD |
| GET/POST | `/api/StudySession` | Çalışma oturumu |
| GET | `/api/StudySession/weekly-summary` | Haftalık özet |
| GET | `/api/StudySession/monthly-heatmap` | Aylık ısı haritası |
| GET/POST/DELETE | `/api/Exam` | Deneme CRUD |
| GET | `/api/Gelisimim/stats?filter=today\|all` | Toplam oturum/süre/soru/dinlenme |
| GET | `/api/Gelisimim/xp-info` | XP, seviye, streak |
| GET | `/api/Gelisimim/calendar?year=...&month=...` | Aktif günler |
| GET | `/api/Gelisimim/daily-report?date=YYYY-MM-DD` | Günlük tamamlama + sorular |
| GET | `/api/Gelisimim/lesson-distribution?filter=...` | Ders bazlı soru dağılımı |
| GET | `/api/Gelisimim/question-subjects` | Bugün her ders için girilen soru |
| POST | `/api/Gelisimim/save-questions` | Soru sayısı upsert |
| POST | `/api/Ai/chat` | AI Koç sohbeti |

Tüm `Authorize` endpoint'leri `Authorization: Bearer {JWT}` ister.

---

## 🗄️ Veritabanı Şeması (özet)

| Tablo | İçerik |
|---|---|
| `kullanicilar` | Users — ad, e-posta, sifre (BCrypt), olusturulma_tarihi |
| `kullanici_profilleri` | UserProfile — sınav, alan, dersler (JSON), saatler, off-day'ler, sınav tarihi |
| `uygulama_durumu` | **AppState** — (kullanici_id, anahtar, deger_json, guncelleme_tarihi); generic key-value senkron deposu (notlar, plan, tamamlamalar, hedefler, dinlenme günleri, sohbet geçmişi) |
| `dersler` / `konular` | Lesson / Topic (kullanıcı-tanımlı ders/konu) |
| `calisma_kayitlari` | StudySession — pomodoro/oturum kayıtları |
| `denemeler` / `deneme_detaylari` | Exam / ExamDetail — deneme + ders bazlı doğru/yanlış/net |
| `soru_kayitlari` | QuestionLog — (kullanici, tarih, ders_anahtar) → soru sayısı |

---

## 🔐 Güvenlik & İzolasyon

- **JWT Bearer**: tüm kullanıcı endpoint'leri token doğrular; her sorgu `UserId` claim'i ile filtrelenir.
- **BCrypt** ile şifre hashing.
- **Kullanıcı izolasyonu**: tüm tablolarda `kullanici_id` FK + `CASCADE DELETE`; bir kullanıcı silindiğinde tüm verisi temizlenir.
- **Token interceptor**: web `axios` + mobil `Dio` her isteğe otomatik `Authorization` ekler; 401 alındığında login'e yönlendirir.

---

## 🧪 Doğrulama Komutları

```bash
# Backend derleme
cd Backend && dotnet build

# Web build
cd frontend_web && npm run build

# Mobil statik analiz
cd frontend_mobile && flutter analyze
```

---

## 📱 Ekranlar (Mobil & Web)

### Ana Sayfa
- Üst banner: bugünün adı + görev sayısı + 🔥 kalan gün rozeti.
- Haftalık Planımı İncele kartı.
- Öncelikli (zayıf) → Pekiştirme (güçlü) → Manuel görev bölümleri; saatli sıralama (gece kuşu desteğiyle).
- Sağ alt **+ Görev** butonu: Konuları Düzenle / Kendim Görev Ekle / Hastayım–Dinlenme Modu.
- Sol alt 🔔 hızlı not ikonu.

### Gelişimim
- XP header (seviye, ilerleme, streak, toplam soru).
- 4 stat kart.
- Soru Gelişimi + Geçmişi Gör butonları.
- Bugün/Tüm Zamanlar toggle → ders dağılımı + soru çözümleri (Tüm Zamanlar'da günlere göre gruplu).

### Denemeler
- Üst kırmızı banner + Deneme Sonucu Ekle.
- Tür filtresi chip'leri.
- Net Özeti, Net Trend, Denge Radarı, Koç Analizi kartları (renkli tonlu arka plan).
- Karşılaştırma modalı.
- **Branş denemeleri**: ders adına göre gruplu, her ders kendi analizine sahip.

### Profil
- Accordion bölümler: Notlarım, Akademik Hedef, Ders Profilim, Zaman ve Biyoritim, Sınav Tarihi ve Hedef, Ayarlar.
- Her bölümün kendi rengi var (tonlu zemin + çerçeve).
- Karanlık Mod toggle, Çıkış Yap.

### Çalışma Ekranı
- Daire animasyonlu sayaç.
- Mola butonu (5dk).
- Ortam sesi seçici + YouTube Study With Me kartı.

### Onboarding
- 8-9 adımlı sihirbaz: isim, kademe, sınav, alan (varsa), sınav tarihi, çalışma tipi, günlük rutin, uyku saati, dersler.

---

## 🤝 Lisans

MIT — Detay için [LICENSE](LICENSE).

---

## 🙏 Teşekkür

- **Google Gemini API** — AI koç ve plan önerileri için.
- **Material Design Icons**, **Tailwind**, **Riverpod**, **Recharts** topluluklarına.
