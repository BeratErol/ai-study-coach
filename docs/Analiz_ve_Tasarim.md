# 📌 Proje Analiz ve Gereksinim Dokümanı

## 🎯 Projenin Amacı
Bu projenin amacı, öğrencilerin zaman yönetimini geliştirmek ve daha verimli çalışma planları oluşturmalarını sağlamaktır. Uygulama, kullanıcıların derslerini organize etmelerine, odaklanma sürelerini takip etmelerine ve performanslarını analiz etmelerine yardımcı olur.

---

## 🚀 Temel Özellikler

### 📚 Ders ve Konu Yönetimi
- Kullanıcılar ders ekleyebilir, düzenleyebilir ve silebilir.
- Her ders için konu başlıkları oluşturulabilir.
- Derslere ait ilerleme durumu takip edilebilir.

### ⏱️ Pomodoro Sayacı
- Kullanıcıların odaklanmasını artırmak için Pomodoro tekniği uygulanır.
- Çalışma ve mola süreleri ayarlanabilir.
- Tamamlanan Pomodoro sayıları kaydedilir.

### 📊 Deneme Sınavı Analizi
- Kullanıcılar deneme sınavı sonuçlarını kaydedebilir.
- Doğru, yanlış ve boş sayıları girilebilir.
- Performans analizi ve gelişim grafikleri sunulur.

### 🤖 Yapay Zeka Destekli Öneriler
- OpenAI API kullanılarak kişiye özel çalışma önerileri sunulur.
- Kullanıcının geçmiş performansına göre öneriler üretilir.

---

## 🧱 Teknoloji Yığını

### 📱 Frontend (Mobil Uygulama)
- Flutter

### 🌐 Backend (Sunucu)
- .NET Web API

### 🗄️ Veritabanı
- PostgreSQL

---

## 🏗️ Sistem Mimarisi

Uygulama, mobil istemci ve backend servisinin birlikte çalıştığı katmanlı bir mimariye sahiptir.

### 📲 İstemci (Client)
- Kullanıcı arayüzünü sağlar.
- Kullanıcıdan alınan verileri backend API’ye gönderir.
- API’den gelen verileri kullanıcıya sunar.

### ⚙️ Sunucu (Backend API)
- İş mantığını yönetir.
- Kullanıcıdan gelen verileri işler.
- Veritabanı ile iletişim kurar.
- Güvenlik ve doğrulama işlemlerini gerçekleştirir.

### 🗃️ Veritabanı (Database)
- Tüm kullanıcı verilerini saklar.
- Dersler, Pomodoro kayıtları ve sınav sonuçlarını tutar.
- Güvenli ve performanslı veri erişimi sağlar.

---

## 🔄 Veri Akışı

1. Kullanıcı mobil uygulama üzerinden işlem yapar.
2. İstemci, isteği Backend API’ye gönderir.
3. Backend API isteği işler ve veritabanına kaydeder.
4. Gerekli veriler veritabanından çekilir.
5. Sonuç istemciye geri gönderilir.
6. Kullanıcı arayüzünde gösterilir.

---