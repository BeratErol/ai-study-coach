function getPayload(): Record<string, unknown> | null {
  const token = localStorage.getItem('jwt_token')
  if (!token) return null
  try {
    const payload = JSON.parse(atob(token.split('.')[1]))
    if (payload.exp * 1000 < Date.now()) return null
    return payload
  } catch {
    return null
  }
}

export function getUserId(): string | null {
  const p = getPayload()
  if (!p) return null
  const id =
    p['sub'] ??
    p['nameid'] ??
    p['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier']
  return id ? String(id) : null
}

export function getUserName(): string | null {
  const p = getPayload()
  if (!p) return null
  const name =
    p['name'] ??
    p['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name']
  return name ? String(name) : null
}
