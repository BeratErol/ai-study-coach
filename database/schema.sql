-- ============================================================
-- AI DESTEKLİ DERS PLANLAMA VE KOÇLUK SİSTEMİ
-- PostgreSQL Veritabanı Şeması
-- ============================================================

-- ============================================================
-- ENUM TİPLERİ (Sabit Seçenekler)
-- ============================================================

-- Çalışma türü: Pomodoro veya manuel giriş
CREATE TYPE calisma_tipi AS ENUM (
    'pomodoro',
    'manuel'
);

-- Planlanan görevin durumu
CREATE TYPE gorev_durum AS ENUM (
    'beklemede',
    'tamamlandi',
    'iptal'
);

-- ============================================================
-- 1. TABLO: kullanicilar
-- ============================================================
CREATE TABLE kullanicilar (
    id                 SERIAL PRIMARY KEY,
    ad_soyad           VARCHAR(255) NOT NULL,
    eposta             VARCHAR(255) NOT NULL UNIQUE,
    sifre              VARCHAR(255) NOT NULL, -- bcrypt/argon2 hash
    hedef_sinav        VARCHAR(100),          -- Örn: 'YKS', 'KPSS', 'Final'
    olusturulma_tarihi TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 2. TABLO: dersler
-- ============================================================
CREATE TABLE dersler (
    id           SERIAL PRIMARY KEY,
    kullanici_id INTEGER NOT NULL REFERENCES kullanicilar(id) ON DELETE CASCADE,
    ders_adi     VARCHAR(100) NOT NULL,
    renk_kodu    VARCHAR(7) DEFAULT '#3498db' -- UI'da dersleri ayırmak için
);

-- ============================================================
-- 3. TABLO: konular
-- ============================================================
CREATE TABLE konular (
    id           SERIAL PRIMARY KEY,
    ders_id      INTEGER NOT NULL REFERENCES dersler(id) ON DELETE CASCADE,
    konu_adi     VARCHAR(255) NOT NULL,
    is_tamamlandi BOOLEAN DEFAULT FALSE
);

-- ============================================================
-- 4. TABLO: calisma_kayitlari (Pomodoro ve Takip)
-- ============================================================
CREATE TABLE calisma_kayitlari (
    id                 SERIAL PRIMARY KEY,
    kullanici_id       INTEGER NOT NULL REFERENCES kullanicilar(id) ON DELETE CASCADE,
    konu_id            INTEGER NOT NULL REFERENCES konular(id) ON DELETE CASCADE,
    sure_dakika        INTEGER NOT NULL,
    tip                calisma_tipi DEFAULT 'pomodoro',
    tarih              TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 5. TABLO: deneme_sonuclari
-- ============================================================
CREATE TABLE deneme_sonuclari (
    id                 SERIAL PRIMARY KEY,
    kullanici_id       INTEGER NOT NULL REFERENCES kullanicilar(id) ON DELETE CASCADE,
    deneme_adi         VARCHAR(255) NOT NULL,
    net_skoru          NUMERIC(5, 2) NOT NULL,
    detaylar           JSONB, -- Örn: {"matematik": 30, "turkce": 35}
    tarih              TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 6. TABLO: ai_onerileri
-- ============================================================
CREATE TABLE ai_onerileri (
    id                 SERIAL PRIMARY KEY,
    kullanici_id       INTEGER NOT NULL REFERENCES kullanicilar(id) ON DELETE CASCADE,
    oneri_metni        TEXT NOT NULL,
    analiz_verisi      JSONB, -- AI'nın hangi veriye göre bu öneriyi yaptığı
    tarih              TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- İNDEKSLER (Performans için)
-- ============================================================
CREATE INDEX idx_calisma_kullanici ON calisma_kayitlari(kullanici_id);
CREATE INDEX idx_deneme_kullanici  ON deneme_sonuclari(kullanici_id);
CREATE INDEX idx_konular_ders      ON konular(ders_id);
CREATE INDEX idx_calisma_tarih     ON calisma_kayitlari(tarih);