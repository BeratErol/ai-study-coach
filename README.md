
---

# 📘 AI Study Coach

## 📌 Proje Hakkında

**AI Study Coach**, öğrencilerin ders çalışma süreçlerini daha planlı, verimli ve sürdürülebilir hale getirmeyi amaçlayan yapay zekâ destekli bir ders planlama ve koçluk sistemidir.

Sistem; kullanıcıların hedeflerini, derslerini ve performans verilerini analiz ederek kişiye özel çalışma planları oluşturur. Çalışma süreci boyunca elde edilen veriler doğrultusunda planlar dinamik olarak güncellenir.

Proje, web ve mobil platformlarda çalışacak şekilde ortak bir backend API altyapısı ile geliştirilmektedir.

---

## 🎯 Projenin Amaçları

* Kişiye özel çalışma planı oluşturmak
* Günlük ve haftalık çalışma takibi yapmak
* Pomodoro yöntemi ile süre yönetimi sağlamak
* Deneme sınavı sonuçlarını analiz etmek
* Zayıf konuları tespit ederek öneriler sunmak
* Yapay zekâ ile adaptif (uyarlanabilir) çalışma stratejisi geliştirmek

---

## 🛠 Planlanan Özellikler

* Ders ve konu bazlı planlama sistemi
* Günlük / haftalık takvim görünümü
* Pomodoro çalışma zamanlayıcısı
* Deneme sınavı sonuç girişi ve analiz paneli
* Performans grafikleri
* AI destekli öneri ve plan güncelleme sistemi
* Web ve mobil senkronizasyon

---

## 🏗 Geliştirme Süreci

Proje yaklaşık **10–12 haftalık** bir geliştirme planı doğrultusunda ilerlemektedir. Her hafta düzenli olarak GitHub üzerinden ilerleme paylaşılacaktır.

---

## ✅ 1. Hafta — Analiz ve Tasarım

Bu hafta proje için temel analiz ve sistem tasarımı tamamlanmıştır.

### 📂 Oluşturulan Klasörler ve İçerikler

#### 📁 `database/`

* `diagram.dbml` → Veritabanı tasarımının DBML formatında tanımı
* `ER_diagram.png` → Entity-Relationship diyagramı
* `schema.sql` → Veritabanı şema yapısı

#### 📁 `docs/`

* `Analiz_ve_Tasarim.md`
* `Kullanıcı_Senaryoları.pdf`
* `Problem_Tanımı_ve_Gereksinim_Analizi.pdf`
* `Proje_Dökümantasyonu.pdf`
* `Wireframe_ve_Akış_Planı.pdf`

---

## ✅ 2. Hafta — Backend Kurulumu

Bu hafta projenin backend altyapısı oluşturulmuş ve veritabanı ile entegrasyonu sağlanmıştır.

### ⚙️ Yapılan İşlemler

* `.NET Web API` projesi oluşturuldu
* PostgreSQL için gerekli paketler eklendi

  * `Npgsql.EntityFrameworkCore.PostgreSQL`
  * `Microsoft.EntityFrameworkCore.Design`
* Veritabanı varlıkları (Entities) oluşturuldu:

  * User, Lesson, Topic, StudySession, ExamResult
* `AppDbContext` yapılandırıldı
* Fluent API ile tablo ve sütun eşleştirmeleri yapıldı
* PostgreSQL bağlantı ayarları `appsettings.json` içine eklendi
* İlk migration (`InitialCreate`) oluşturuldu

---

## ✅ 3. Hafta — Kimlik Doğrulama ve Veritabanı Entegrasyonu

Bu hafta projenin güvenlik altyapısı kurulmuş ve veritabanı canlıya alınmıştır.

### ⚙️ Yapılan İşlemler

* **PostgreSQL Servis Yapılandırması:** Yerel sunucuda PostgreSQL servisi kuruldu, `initdb` ve `locale` ayarları yapılandırılarak veritabanı motoru aktif edildi.
* **Kullanıcı Kayıt ve Giriş (Auth):**
  * `BCrypt.Net-Next` kütüphanesi kullanılarak şifre güvenliği (hashing) sağlandı.
  * JWT (JSON Web Token) tabanlı kimlik doğrulama sistemi entegre edildi.
* **Veritabanı Şeması ve Migrations:**
  * Özel Enum tipleri (`calisma_tipi`) için PostgreSQL uyumlu yapılandırmalar yapıldı.
  * `Fluent API` ve `HasDefaultValueSql` kullanılarak veritabanı seviyesinde varsayılan değerler atandı.
  * `InitialCreate` migration'ı başarıyla uygulanarak tablolar oluşturuldu.
* **API Testleri:**
  * Swagger UI üzerinden `Register` ve `Login` endpoint'leri test edildi.
  * Başarıyla ilk kullanıcı kaydedildi ve JWT Token üretimi doğrulandı.

### 📂 Eklenen Klasörler ve İçerikler

#### 📁 `Backend/`

* `Controllers/AuthController.cs` → Kayıt ve giriş işlemlerini yöneten API uç noktaları.
* `Services/AuthService.cs` → Şifre doğrulama ve Token üretim mantığı.
* `DTOs/` → Veri transfer nesneleri (UserRegisterDto, UserLoginDto).

## 🖼 Ekran Görüntüleri

### ✅ Başarılı Giriş Testi

![Başarılı Giriş Testi](docs/screenshots/login_success.png)

Sistem, PostgreSQL veritabanı ile tam entegre çalışmakta olup, JWT tabanlı yetkilendirme başarıyla test edilmiştir.

---

## 🚀 Sonraki Adımlar (4. Hafta)

* **Ders ve Konu Yönetimi:** Kullanıcıların kendi derslerini ve konularını ekleyebileceği CRUD işlemlerinin yazılması.
* **Yetkilendirme (Authorization):** Sadece giriş yapmış kullanıcıların kendi verilerine erişebilmesini sağlayacak `[Authorize]` filtrelerinin eklenmesi.
* **Global Error Handling:** API genelinde hata yakalama ve standart raporlama sisteminin kurulması.

---

## 📌 Not

Bu proje aktif olarak geliştirilmektedir ve her hafta yeni özellikler eklenmeye devam edecektir.

---
