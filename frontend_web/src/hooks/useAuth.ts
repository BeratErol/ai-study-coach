export function getToken(): string | null {
  return localStorage.getItem('jwt_token')
}

export function setToken(token: string): void {
  localStorage.setItem('jwt_token', token)
}

export function clearToken(): void {
  localStorage.removeItem('jwt_token')
}

export function isAuthenticated(): boolean {
  const token = getToken()
  if (!token) return false
  try {
    const payload = JSON.parse(atob(token.split('.')[1]))
    return payload.exp * 1000 > Date.now()
  } catch {
    return false
  }
}

export function getUserName(): string {
  const token = getToken()
  if (!token) return ''
  try {
    const payload = JSON.parse(atob(token.split('.')[1]))
    return (
      payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'] ||
      payload.name ||
      ''
    )
  } catch {
    return ''
  }
}
