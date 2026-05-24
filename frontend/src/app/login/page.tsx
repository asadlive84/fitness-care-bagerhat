'use client'

import { useState, FormEvent, useEffect, Suspense } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { motion } from 'framer-motion'
import { Eye, EyeSlash, Plant, Warning } from '@phosphor-icons/react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { api } from '@/lib/api'
import { setToken } from '@/lib/auth'
import type { ApiResponse, LoginResponse } from '@/types'
import { cn } from '@/lib/utils'
import Link from 'next/link'
import { PublicHeader } from '@/components/public-header'
import { PublicFooter } from '@/components/public-footer'

// Wrapped in Suspense below because useSearchParams() requires it for static builds
function LoginForm() {
  const router      = useRouter()
  const params      = useSearchParams()
  const [identifier, setIdentifier] = useState('')
  const [password, setPassword]     = useState('')
  const [showPw, setShowPw]         = useState(false)
  const [role, setRole]             = useState<'member' | 'admin' | 'superadmin'>('member')

  useEffect(() => {
    const r = params.get('role')
    if (r === 'admin' || r === 'superadmin') setRole(r)
  }, [params])
  const [loading, setLoading]       = useState(false)
  const [error, setError]           = useState<string | null>(null)

  const ENDPOINTS = {
    member:     '/api/v1/auth/member/login',
    admin:      '/api/v1/auth/admin/login',
    superadmin: '/api/v1/auth/admin/login',
  }
  const isEmailRole = role === 'admin' || role === 'superadmin'

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setError(null)
    setLoading(true)
    try {
      const body = isEmailRole ? { email: identifier, password } : { phone: identifier, password }
      const { data } = await api.post<ApiResponse<LoginResponse>>(ENDPOINTS[role], body)
      if (!data.success) throw new Error(data.error?.message ?? 'Login failed')

      const token =
        (data.data as unknown as { access_token?: string })?.access_token
        ?? (data.data as unknown as { token?: string })?.token
      if (!token) throw new Error('No token received')

      setToken(token)
      document.cookie = `fc_token=${token}; path=/; max-age=${60 * 60 * 24 * 7}; SameSite=Lax`

      const { decodeToken, roleHomePath } = await import('@/lib/auth')
      const decoded = decodeToken(token)
      const resolvedRole = decoded?.role ?? role
      // Full page navigation so the browser includes the fresh cookie in the
      // request and the middleware can authenticate the superadmin correctly.
      window.location.href = roleHomePath(resolvedRole)
    } catch (err: unknown) {
      const msg =
        (err as { response?: { data?: ApiResponse<unknown> } })?.response?.data?.error?.message
        ?? (err as Error)?.message
        ?? 'Something went wrong'
      setError(msg)
    } finally {
      setLoading(false)
    }
  }

  const roleConfig = {
    member:     { label: 'Member',      hint: 'Track your fitness journey' },
    admin:      { label: 'Admin',       hint: 'Manage your gym' },
    superadmin: { label: 'Super Admin', hint: 'Provision the platform' },
  }

  return (
    <div className="min-h-screen flex flex-col bg-[#F5F7F0]" lang="bn">
      <PublicHeader />

      <main className="flex-1 flex items-center justify-center px-4 pt-20 pb-10 relative overflow-hidden">
        {/* Decorative ambient blobs */}
        <div className="absolute -top-32 -right-32 w-96 h-96 rounded-full bg-primary/8 blur-3xl pointer-events-none" />
        <div className="absolute -bottom-32 -left-32 w-96 h-96 rounded-full bg-accent/5 blur-3xl pointer-events-none" />

        <motion.div
          initial={{ opacity: 0, y: 24 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
          className="w-full max-w-sm relative z-10"
        >
          {/* Brand */}
          <div className="flex flex-col items-center mb-10">
            <div className="w-16 h-16 rounded-2xl bg-primary flex items-center justify-center mb-4 shadow-lg shadow-primary/25">
              <Plant size={30} weight="fill" className="text-white" />
            </div>
            <h1 className="text-2xl font-bold text-foreground tracking-tight">Fitness Care</h1>
            <p className="text-sm text-muted-foreground mt-1">Bagerhat</p>
          </div>

          <div className="glass rounded-2xl p-6">
            {/* Role pills */}
            <div className="flex gap-1 mb-5 bg-muted/60 rounded-xl p-1">
              {(['member', 'admin', 'superadmin'] as const).map((r) => (
                <button
                  key={r}
                  type="button"
                  onClick={() => setRole(r)}
                  className={cn(
                    'flex-1 text-xs font-semibold py-2 rounded-lg transition-all duration-200',
                    role === r
                      ? 'bg-primary text-white shadow-sm'
                      : 'text-muted-foreground hover:text-foreground',
                  )}
                >
                  {roleConfig[r].label}
                </button>
              ))}
            </div>
            <p className="text-xs text-muted-foreground text-center mb-5">{roleConfig[role].hint}</p>

            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="space-y-1.5">
                <Label htmlFor="identifier" className="text-xs font-medium text-muted-foreground">
                  {isEmailRole ? 'Email address' : 'Phone number'}
                </Label>
                <Input
                  id="identifier"
                  type={isEmailRole ? 'email' : 'tel'}
                  placeholder={isEmailRole ? 'name@example.com' : '01712345678'}
                  value={identifier}
                  onChange={(e) => setIdentifier(e.target.value)}
                  required
                  className="h-11 bg-white/60"
                />
              </div>

              <div className="space-y-1.5">
                <Label htmlFor="password" className="text-xs font-medium text-muted-foreground">Password</Label>
                <div className="relative">
                  <Input
                    id="password"
                    type={showPw ? 'text' : 'password'}
                    placeholder="••••••••"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                    className="h-11 pr-10 bg-white/60"
                  />
                  <button
                    type="button"
                    tabIndex={-1}
                    onClick={() => setShowPw(!showPw)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                  >
                    {showPw ? <EyeSlash size={16} /> : <Eye size={16} />}
                  </button>
                </div>
              </div>

              {error && (
                <motion.div
                  initial={{ opacity: 0, scale: 0.97 }}
                  animate={{ opacity: 1, scale: 1 }}
                  className="flex items-center gap-2 text-sm text-red-700 bg-red-50/80 border border-red-200/70 rounded-lg px-3 py-2.5"
                >
                  <Warning size={14} weight="fill" className="shrink-0" />
                  <span className="leading-tight">{error}</span>
                </motion.div>
              )}

              <Button
                type="submit"
                disabled={loading}
                className="w-full h-11 font-semibold bg-primary hover:bg-primary/90 text-white shadow-sm mt-1"
              >
                {loading ? (
                  <span className="flex items-center gap-2">
                    <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                    Signing in…
                  </span>
                ) : 'Sign in'}
              </Button>
            </form>
          </div>

          <p className="text-center text-xs text-muted-foreground mt-5">
            New member?{' '}
            <Link href="/register" className="text-primary font-medium hover:underline">
              Register here
            </Link>
          </p>
        </motion.div>
      </main>

      <PublicFooter />
    </div>
  )
}

export default function LoginPage() {
  return (
    <Suspense>
      <LoginForm />
    </Suspense>
  )
}
