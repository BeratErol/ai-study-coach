# AI Study Coach

Kişiselleştirilmiş yapay zeka destekli çalışma koçu. Öğrencinin sınav hedefine, güçlü/zayıf derslerine ve günlük müsaitliğine göre haftalık program oluşturur; çalışma süreci boyunca rehberlik eder.

> LGS, TYT/AYT, KPSS, YDS ve diğer sınavlara hazırlanan öğrenciler için.

---

## Özellikler

### Akıllı Program Yönetimi
- Onboarding sırasında seçilen sınav türü, zayıf/güçlü dersler ve haftalık çalışma saatlerine göre otomatik haftalık plan üretimi
- Zayıf dersler öncelikli (75/25 dağılımı), mola blokları dahil
- Görev türü rotasyonu: zayıf dersler konu anlatımı → soru çözümü, güçlü dersler soru çözümü → konu anlatımı şeklinde dönüşümlü ilerler
- Haftalık programa konu atama (her bloğa ayrı konu)
- Manuel görev ekleme: alanındaki tüm dersler arasından seçim

### Çalışma Oturumu
- Gerçek zamanlı geri sayım zamanlayıcısı, görsel ilerleme halkası
- Ortam sesi seçici (Hafif Yağmur, Ateş, Orman, Kuş, Kafe vb. — arka planda stream)
- Acil mola modu (5 dk)
- Oturum tamamlandığında görev otomatik işaretleme

### Takip ve Analiz
- Deneme sınavı kaydı, net hesaplama (−0.25 yanış), ders bazlı kırılım
- Haftalık çalışma özeti ve trend grafikleri
- Tamamlanan görev sayacı

### Genel
- JWT tabanlı kimlik doğrulama; her kullanıcı verisi izole
- Koyu tema çalışma ekranı, açık tema dashboard
- Hızlı not alma
- Çevrimdışı çalışma desteği (local storage yedek)

---

## Teknoloji Yığını

| Katman | Teknolojiler |
|--------|-------------|
| **Backend** | ASP.NET Core 8, Entity Framework Core, PostgreSQL, JWT Bearer, BCrypt |
| **Mobil** | Flutter 3, Riverpod 2, GoRouter, Dio, audioplayers, fl_chart, SharedPreferences |
| **Web** | React 18, Vite, TypeScript, Tailwind CSS v4, Recharts, React Router v6 |

---

## Proje Yapısı

```
ai-study-coach/
├── Backend/
│   ├── Controllers/        # Auth, Lesson, StudySession, Exam, Ai, UserProfile
│   ├── Data/               # AppDbContext
│   ├── DTOs/               # Request/Response modelleri
│   ├── Models/             # EF Core varlıkları
│   └── Services/           # İş mantığı
├── frontend_mobile/
│   ├── lib/
│   │   ├── core/           # Tema, router, sabitler
│   │   ├── data/           # Sınav/ders/konu veri tanımları
│   │   ├── models/         # Veri modelleri
│   │   ├── providers/      # Riverpod state yönetimi
│   │   ├── screens/        # Tüm ekranlar
│   │   ├── services/       # API, plan üretici, token, prefs
│   │   └── widgets/        # Yeniden kullanılabilir bileşenler
│   └── assets/
│       ├── icon/
│       └── sounds/         # Ortam sesi dosyaları (.mp3)
└── frontend_web/
    └── src/
        ├── components/
        ├── hooks/
        └── pages/
```

---

## Kurulum

### Gereksinimler

- .NET 8 SDK
- PostgreSQL 14+
- Flutter 3.19+
- Node.js 20+

### Backend

```bash
cd Backend

# appsettings.Development.json oluştur ve doldur
cp appsettings.json appsettings.Development.json
# ConnectionStrings.DefaultConnection → PostgreSQL bağlantı dizesi
# JwtSettings.Secret → rastgele uzun anahtar

dotnet ef database update
dotnet run
# → https://localhost:5001
```

### Flutter Mobil

```bash
cd frontend_mobile
flutter pub get
flutter run
```

`lib/services/api_service.dart` içindeki `baseUrl`'i backend adresinizle güncelleyin.

### Web Panosu

```bash
cd frontend_web
npm install
npm run dev
# → http://localhost:5173
```

---

## API Özeti

| Yöntem | Endpoint | Açıklama |
|--------|----------|----------|
| POST | `/api/Auth/register` | Kayıt |
| POST | `/api/Auth/login` | Giriş → JWT |
| GET/POST | `/api/UserProfile` | Onboarding profili |
| GET/POST/DELETE | `/api/Lesson` | Ders CRUD |
| GET/POST | `/api/StudySession` | Çalışma oturumu |
| GET | `/api/StudySession/weekly-summary` | Haftalık özet |
| GET | `/api/StudySession/monthly-heatmap` | Aylık ısı haritası |
| GET/POST | `/api/Exam` | Deneme sınavı |
| GET | `/api/Exam/analysis` | Sınav trend analizi |
| POST | `/api/Ai/coach-message` | AI koç mesajı |

---

## Lisans

MIT
