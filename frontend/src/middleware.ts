import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

const PUBLIC_PATHS = ['/', '/login', '/register']

const ROLE_PREFIX: Record<string, string> = {
  admin:      '/admin',
  member:     '/member',
  superadmin: '/superadmin',
}

const ROLE_HOME: Record<string, string> = {
  admin:      '/admin/dashboard',
  member:     '/member/dashboard',
  superadmin: '/superadmin/overview',
}

function decodeJWT(token: string) {
  try {
    const payload = token.split('.')[1]
    return JSON.parse(Buffer.from(payload, 'base64').toString('utf-8')) as {
      role: string
      exp: number
    }
  } catch {
    return null
  }
}

function isPublic(pathname: string) {
  return PUBLIC_PATHS.some((p) => pathname === p || pathname.startsWith(p + '/'))
}

export default function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl
  const token = request.cookies.get('fc_token')?.value

  // ── Unauthenticated ────────────────────────────────────────────────────────
  if (!token) {
    if (isPublic(pathname)) return NextResponse.next()
    return NextResponse.redirect(new URL('/', request.url))
  }

  const payload = decodeJWT(token)

  // ── Invalid / expired token ────────────────────────────────────────────────
  if (!payload || Date.now() / 1000 > payload.exp) {
    const res = NextResponse.redirect(new URL('/', request.url))
    res.cookies.delete('fc_token')
    return res
  }

  const home = ROLE_HOME[payload.role]

  // ── Authenticated on a public page (login, register, landing) → dashboard ──
  if (isPublic(pathname)) {
    return home
      ? NextResponse.redirect(new URL(home, request.url))
      : NextResponse.next()
  }

  // ── Authenticated on wrong role prefix → correct dashboard ─────────────────
  const allowed = ROLE_PREFIX[payload.role]
  if (allowed && !pathname.startsWith(allowed)) {
    return NextResponse.redirect(new URL(home ?? allowed + '/dashboard', request.url))
  }

  return NextResponse.next()
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|uploads/|api/|.*\\.png$|.*\\.ico$).*)'],
}
