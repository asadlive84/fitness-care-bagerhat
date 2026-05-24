import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

// Routes accessible without a token
const PUBLIC_PATHS = ['/', '/login', '/register']

const ROLE_PREFIX: Record<string, string> = {
  admin:      '/admin',
  member:     '/member',
  superadmin: '/superadmin',
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

export default function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl

  // Allow public paths
  if (PUBLIC_PATHS.some((p) => pathname === p || pathname.startsWith(p + '/'))) {
    return NextResponse.next()
  }

  const token = request.cookies.get('fc_token')?.value

  if (!token) {
    // Unauthenticated → send to landing page
    return NextResponse.redirect(new URL('/', request.url))
  }

  const payload = decodeJWT(token)

  if (!payload || Date.now() / 1000 > payload.exp) {
    const res = NextResponse.redirect(new URL('/', request.url))
    res.cookies.delete('fc_token')
    return res
  }

  // Authenticated user on wrong role prefix → redirect to their own dashboard
  const allowed = ROLE_PREFIX[payload.role]
  if (allowed && !pathname.startsWith(allowed)) {
    return NextResponse.redirect(new URL(allowed + '/dashboard', request.url))
  }

  return NextResponse.next()
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|uploads/|api/|.*\\.png$|.*\\.ico$).*)'],
}
