import api from './api'
import { getUserId } from './tokenService'

/**
 * Cihazdan bağımsız generic key-value senkron katmanı.
 *
 * Yerel `localData.ts` / `userPrefsService.ts` servisleri verileri
 * `user_{userId}_{key}` biçiminde localStorage'da tutar (hızlı/offline cache).
 * Bu servis aynı veriyi backend `AppState` tablosuyla senkron eder:
 *  - `pushAppState`  → localStorage + backend'e yazar
 *  - `hydrateAppState` → backend'deki tüm değerleri localStorage cache'ine indirir
 *
 * Backend tarafında key sade haliyle (`quick_notes`), userId token'dan gelir.
 */

function fullKey(key: string): string | null {
  const uid = getUserId()
  return uid ? `user_${uid}_${key}` : null
}

/** Bir anahtarı localStorage'a yazar ve backend'e (fire-and-forget) push eder. */
export function pushAppState(key: string, value: unknown): void {
  const lk = fullKey(key)
  if (lk) localStorage.setItem(lk, JSON.stringify(value))
  // Backend'e gönder — hata olsa da yerel kayıt durmaz (offline toleransı).
  api.put(`/AppState/${encodeURIComponent(key)}`, value).catch(() => {})
}

/** Bir anahtarı hem localStorage'dan hem backend'den siler. */
export function deleteAppState(key: string): void {
  const lk = fullKey(key)
  if (lk) localStorage.removeItem(lk)
  api.delete(`/AppState/${encodeURIComponent(key)}`).catch(() => {})
}

/**
 * Backend'deki tüm AppState değerlerini çekip localStorage cache'ine yazar.
 * Login sonrası ve uygulama açılışında çağrılır — böylece başka cihazda
 * yapılan değişiklikler bu cihaza iner. Backend doğruluk kaynağıdır.
 */
export async function hydrateAppState(): Promise<void> {
  const uid = getUserId()
  if (!uid) {
    console.warn('[AppState] hydrate: userId yok, atlandı')
    return
  }
  try {
    const res = await api.get('/AppState')
    const data = (res.data ?? {}) as Record<string, unknown>
    console.info('[AppState] hydrate uid=' + uid + ' anahtarlar:', Object.keys(data))
    for (const [key, value] of Object.entries(data)) {
      localStorage.setItem(`user_${uid}_${key}`, JSON.stringify(value))
    }
  } catch (e) {
    console.warn('[AppState] hydrate başarısız:', e)
  }
}
