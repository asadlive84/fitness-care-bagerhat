import type { JWTPayload, Role } from '@/types'

export function getToken(): string | null {
  if (typeof window === 'undefined') return null
  const ls = localStorage.getItem('fc_token')
  if (ls) return ls
  // Fall back to cookie (middleware uses this; keeps them in sync)
  const match = document.cookie.match(/(?:^|;\s*)fc_token=([^;]+)/)
  return match ? match[1] : null
}

export function setToken(token: string): void {
  localStorage.setItem('fc_token', token)
}

export function clearToken(): void {
  localStorage.removeItem('fc_token')
}

export function decodeToken(token: string): JWTPayload | null {
  try {
    const payload = token.split('.')[1]
    return JSON.parse(atob(payload)) as JWTPayload
  } catch {
    return null
  }
}

export function getRole(): Role | null {
  const token = getToken()
  if (!token) return null
  if (isTokenExpired(token)) return null
  return decodeToken(token)?.role ?? null
}

export function isTokenExpired(token: string): boolean {
  const payload = decodeToken(token)
  if (!payload) return true
  return Date.now() / 1000 > payload.exp
}

export function roleHomePath(role: Role): string {
  switch (role) {
    case 'superadmin': return '/superadmin/overview'
    case 'admin':      return '/admin/dashboard'
    case 'member':     return '/member/dashboard'
  }
}
