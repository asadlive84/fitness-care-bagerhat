'use client'

import { useState, FormEvent } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { motion } from 'framer-motion'
import { Plant, Warning, CheckCircle } from '@phosphor-icons/react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { api } from '@/lib/api'
import type { ApiResponse } from '@/types'

function toNumber(v: string): number | undefined {
  const n = parseFloat(v)
  return isNaN(n) ? undefined : n
}

export default function RegisterPage() {
  const router = useRouter()

  const [form, setForm] = useState({
    name: '',
    phone: '',
    email: '',
    gender: 'Male',
    religion: '',
    date_of_birth: '',
    nid: '',
    present_address: '',
    height_ft: '',
    height_in: '',
    current_weight: '',
  })

  const [loading, setLoading] = useState(false)
  const [error, setError]     = useState<string | null>(null)
  const [success, setSuccess] = useState(false)

  function set(field: keyof typeof form) {
    return (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) =>
      setForm((p) => ({ ...p, [field]: e.target.value }))
  }

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setError(null)
    setLoading(true)
    try {
      // Convert ft+in → cm
      const ft = parseFloat(form.height_ft) || 0
      const inches = parseFloat(form.height_in) || 0
      const heightCm = ft > 0 || inches > 0 ? Math.round((ft * 12 + inches) * 2.54 * 10) / 10 : undefined

      const payload: Record<string, unknown> = {
        name:    form.name,
        phone:   form.phone,
        gender:  form.gender,
      }
      if (form.email)           payload.email           = form.email
      if (form.religion)        payload.religion        = form.religion
      if (form.date_of_birth)   payload.date_of_birth   = form.date_of_birth
      if (form.nid)             payload.nid             = form.nid
      if (form.present_address) payload.present_address = form.present_address
      if (heightCm)             payload.height_cm       = heightCm
      if (form.current_weight)  payload.current_weight  = toNumber(form.current_weight)

      const { data } = await api.post<ApiResponse<{ message: string }>>('/api/v1/auth/register', payload)
      if (!data.success) throw new Error(data.error?.message ?? 'Registration failed')
      setSuccess(true)
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

  if (success) {
    return (
      <div className="min-h-screen flex items-center justify-center px-4">
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          className="glass rounded-2xl p-10 max-w-sm w-full text-center space-y-4"
        >
          <CheckCircle size={56} weight="fill" className="text-primary mx-auto" />
          <h2 className="text-xl font-bold">Registration Submitted!</h2>
          <p className="text-sm text-muted-foreground leading-relaxed">
            Your registration is pending admin approval. We will contact you with your login details once approved.
          </p>
          <Button
            className="w-full bg-primary text-white hover:bg-primary/90"
            onClick={() => router.replace('/login')}
          >
            Back to Login
          </Button>
        </motion.div>
      </div>
    )
  }

  return (
    <div className="min-h-screen flex items-center justify-center px-4 py-10 relative overflow-hidden">
      <div className="absolute -top-32 -right-32 w-96 h-96 rounded-full bg-primary/8 blur-3xl pointer-events-none" />
      <div className="absolute -bottom-32 -left-32 w-96 h-96 rounded-full bg-accent/5 blur-3xl pointer-events-none" />

      <motion.div
        initial={{ opacity: 0, y: 24 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
        className="w-full max-w-2xl relative z-10"
      >
        {/* Brand */}
        <div className="flex flex-col items-center mb-8">
          <div className="w-14 h-14 rounded-2xl bg-primary flex items-center justify-center mb-3 shadow-lg shadow-primary/25">
            <Plant size={26} weight="fill" className="text-white" />
          </div>
          <h1 className="text-2xl font-bold tracking-tight">Create Account</h1>
          <p className="text-sm text-muted-foreground mt-1">Fitness Care Bagerhat</p>
        </div>

        <form onSubmit={handleSubmit} className="glass rounded-2xl p-6 space-y-5">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {/* Full Name */}
            <div className="space-y-1.5">
              <Label className="text-xs font-medium text-muted-foreground">Full Name *</Label>
              <Input value={form.name} onChange={set('name')} placeholder="John Doe" required className="h-11 bg-white/60" />
            </div>

            {/* Phone */}
            <div className="space-y-1.5">
              <Label className="text-xs font-medium text-muted-foreground">Phone Number *</Label>
              <Input value={form.phone} onChange={set('phone')} placeholder="01712345678" required type="tel" className="h-11 bg-white/60" />
            </div>

            {/* Email */}
            <div className="space-y-1.5">
              <Label className="text-xs font-medium text-muted-foreground">Email Address</Label>
              <Input value={form.email} onChange={set('email')} placeholder="you@example.com" type="email" className="h-11 bg-white/60" />
            </div>

            {/* Gender */}
            <div className="space-y-1.5">
              <Label className="text-xs font-medium text-muted-foreground">Gender *</Label>
              <select
                value={form.gender}
                onChange={set('gender')}
                required
                className="w-full h-11 rounded-md border border-input bg-white/60 px-3 text-sm focus:outline-none focus:ring-2 focus:ring-primary/40"
              >
                <option value="Male">Male</option>
                <option value="Female">Female</option>
                <option value="Other">Other</option>
              </select>
            </div>

            {/* Religion */}
            <div className="space-y-1.5">
              <Label className="text-xs font-medium text-muted-foreground">Religion</Label>
              <select
                value={form.religion}
                onChange={set('religion')}
                className="w-full h-11 rounded-md border border-input bg-white/60 px-3 text-sm focus:outline-none focus:ring-2 focus:ring-primary/40"
              >
                <option value="">— Select —</option>
                <option value="Islam">Islam</option>
                <option value="Christianity">Christianity</option>
                <option value="Hinduism">Hinduism</option>
                <option value="Buddhism">Buddhism</option>
                <option value="Other">Other</option>
              </select>
            </div>

            {/* Date of Birth */}
            <div className="space-y-1.5">
              <Label className="text-xs font-medium text-muted-foreground">Date of Birth</Label>
              <Input value={form.date_of_birth} onChange={set('date_of_birth')} type="date" className="h-11 bg-white/60" />
            </div>

            {/* NID */}
            <div className="space-y-1.5">
              <Label className="text-xs font-medium text-muted-foreground">NID / National ID</Label>
              <Input value={form.nid} onChange={set('nid')} placeholder="1234567890" className="h-11 bg-white/60" />
            </div>

            {/* Height */}
            <div className="space-y-1.5">
              <Label className="text-xs font-medium text-muted-foreground">Height</Label>
              <div className="flex gap-2">
                <div className="relative flex-1">
                  <Input
                    value={form.height_ft}
                    onChange={set('height_ft')}
                    placeholder="5"
                    type="number"
                    min={0}
                    max={9}
                    className="h-11 bg-white/60 pr-8"
                  />
                  <span className="absolute right-3 top-1/2 -translate-y-1/2 text-xs text-muted-foreground">ft</span>
                </div>
                <div className="relative flex-1">
                  <Input
                    value={form.height_in}
                    onChange={set('height_in')}
                    placeholder="8"
                    type="number"
                    min={0}
                    max={11}
                    className="h-11 bg-white/60 pr-8"
                  />
                  <span className="absolute right-3 top-1/2 -translate-y-1/2 text-xs text-muted-foreground">in</span>
                </div>
              </div>
            </div>

            {/* Weight */}
            <div className="space-y-1.5">
              <Label className="text-xs font-medium text-muted-foreground">Weight (kg)</Label>
              <Input
                value={form.current_weight}
                onChange={set('current_weight')}
                placeholder="65"
                type="number"
                min={20}
                max={300}
                step="0.1"
                className="h-11 bg-white/60"
              />
            </div>
          </div>

          {/* Address — full width */}
          <div className="space-y-1.5">
            <Label className="text-xs font-medium text-muted-foreground">Present Address</Label>
            <textarea
              value={form.present_address}
              onChange={set('present_address')}
              placeholder="House, Road, Area, City..."
              rows={2}
              className="w-full rounded-md border border-input bg-white/60 px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-primary/40 resize-none"
            />
          </div>

          {error && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="flex items-center gap-2 text-sm text-red-700 bg-red-50/80 border border-red-200/70 rounded-lg px-3 py-2.5"
            >
              <Warning size={14} weight="fill" className="shrink-0" />
              <span>{error}</span>
            </motion.div>
          )}

          <Button
            type="submit"
            disabled={loading}
            className="w-full h-11 font-semibold bg-primary hover:bg-primary/90 text-white shadow-sm"
          >
            {loading ? (
              <span className="flex items-center gap-2">
                <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                Submitting…
              </span>
            ) : 'Submit Registration'}
          </Button>

          <p className="text-center text-xs text-muted-foreground">
            Already have an account?{' '}
            <Link href="/login" className="text-primary font-medium hover:underline">Sign in</Link>
          </p>
        </form>
      </motion.div>
    </div>
  )
}
