'use client'

import { useState } from 'react'
import { useProvisionGymAdmin } from '@/hooks/use-financials'
import { GlassCard } from '@/components/glass-card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Buildings, Check, ShieldStar, Copy, Warning, KeyReturn } from '@phosphor-icons/react'
import { motion } from 'framer-motion'

export default function GymProvisioning() {
  const [apiKey, setApiKey]     = useState(() => typeof window !== 'undefined' ? localStorage.getItem('sa_api_key') ?? '' : '')
  const [form, setForm]         = useState({ name: '', email: '', phone: '', password: '' })
  const [showKeyHint, setShowKeyHint] = useState(false)
  const [result, setResult]     = useState<{ name: string; email: string } | null>(null)
  const [copied, setCopied]     = useState(false)

  const provision = useProvisionGymAdmin(apiKey)
  const set = (k: string, v: string) => setForm((f) => ({ ...f, [k]: v }))

  function saveKey(k: string) {
    setApiKey(k)
    if (k) localStorage.setItem('sa_api_key', k)
    else   localStorage.removeItem('sa_api_key')
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!apiKey) { setShowKeyHint(true); return }
    try {
      const data = await provision.mutateAsync(form)
      setResult({ name: data.name, email: data.email })
      setForm({ name: '', email: '', phone: '', password: '' })
    } catch {}
  }

  function copyPw() {
    if (!form.password) return
    navigator.clipboard.writeText(form.password)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <div className="p-4 md:p-8 max-w-2xl mx-auto space-y-6">
      <header className="flex items-start gap-3">
        <div className="w-11 h-11 rounded-2xl bg-primary/10 text-primary flex items-center justify-center shrink-0">
          <Buildings size={20} weight="fill" />
        </div>
        <div>
          <h1 className="text-2xl md:text-3xl font-bold tracking-tight">Gym Provisioning</h1>
          <p className="text-sm text-muted-foreground mt-1">
            Onboard a new gym by creating its primary admin account.
          </p>
        </div>
      </header>

      {/* API Key vault */}
      <GlassCard className="p-5 space-y-3">
        <div className="flex items-center gap-2">
          <KeyReturn size={16} className="text-primary" />
          <h3 className="font-semibold text-sm">Machine-to-Machine API Key</h3>
        </div>
        <p className="text-xs text-muted-foreground leading-relaxed">
          The provisioning endpoint is secured with an <code className="text-xs bg-muted px-1.5 py-0.5 rounded">X-API-KEY</code> header,
          not your superadmin login. Paste the key set on the backend as <code className="text-xs bg-muted px-1.5 py-0.5 rounded">SUPERADMIN_API_KEY</code>.
        </p>
        <Input
          type="password"
          value={apiKey}
          onChange={(e) => saveKey(e.target.value)}
          placeholder="sa_••••••••••••"
          className="bg-white/60 font-mono text-xs"
        />
        {apiKey && (
          <p className="text-[11px] text-emerald-700 flex items-center gap-1">
            <Check size={12} weight="bold" /> Stored locally in this browser
          </p>
        )}
        {showKeyHint && !apiKey && (
          <p className="text-[11px] text-red-600 flex items-center gap-1">
            <Warning size={12} weight="fill" /> API key is required to provision a new admin.
          </p>
        )}
      </GlassCard>

      {/* Success banner */}
      {result && (
        <motion.div
          initial={{ opacity: 0, y: -8 }}
          animate={{ opacity: 1, y: 0 }}
          className="rounded-2xl border border-emerald-200/70 bg-emerald-50/70 backdrop-blur-sm p-4 flex items-start gap-3"
        >
          <div className="w-9 h-9 rounded-full bg-emerald-100 text-emerald-700 flex items-center justify-center shrink-0">
            <Check size={16} weight="bold" />
          </div>
          <div className="flex-1">
            <p className="font-semibold text-emerald-800 text-sm">Gym provisioned!</p>
            <p className="text-xs text-emerald-700 mt-0.5">
              <strong>{result.name}</strong> can now sign in with <code className="text-xs bg-white/60 px-1 rounded">{result.email}</code>.
            </p>
          </div>
          <button onClick={() => setResult(null)} className="text-emerald-700 text-xs">Dismiss</button>
        </motion.div>
      )}

      {/* Form */}
      <GlassCard className="p-6">
        <div className="flex items-center gap-2 mb-4">
          <ShieldStar size={16} className="text-primary" />
          <h3 className="font-semibold">New Gym Admin</h3>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <Label className="text-xs text-muted-foreground">Gym Name / Admin Name</Label>
            <Input
              value={form.name}
              onChange={(e) => set('name', e.target.value)}
              placeholder="Atlas Fitness — Owner"
              required
              className="mt-1 h-11 bg-white/60"
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <Label className="text-xs text-muted-foreground">Email</Label>
              <Input
                type="email"
                value={form.email}
                onChange={(e) => set('email', e.target.value)}
                placeholder="owner@atlas.gym"
                required
                className="mt-1 h-11 bg-white/60"
              />
            </div>
            <div>
              <Label className="text-xs text-muted-foreground">Phone (optional)</Label>
              <Input
                type="tel"
                value={form.phone}
                onChange={(e) => set('phone', e.target.value)}
                placeholder="01700000000"
                className="mt-1 h-11 bg-white/60"
              />
            </div>
          </div>

          <div>
            <Label className="text-xs text-muted-foreground">Initial Password</Label>
            <div className="relative">
              <Input
                value={form.password}
                onChange={(e) => set('password', e.target.value)}
                placeholder="Will be shared with the new admin"
                required
                minLength={6}
                className="mt-1 h-11 bg-white/60 pr-10 font-mono"
              />
              {form.password && (
                <button
                  type="button"
                  onClick={copyPw}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                >
                  {copied ? <Check size={14} weight="bold" className="text-emerald-600" /> : <Copy size={14} />}
                </button>
              )}
            </div>
            <p className="text-[11px] text-muted-foreground mt-1">Min 6 chars. The admin can change it after first login.</p>
          </div>

          {provision.error && (
            <div className="text-xs text-red-700 bg-red-50/80 border border-red-200/70 rounded-lg px-3 py-2.5 flex items-center gap-2">
              <Warning size={12} weight="fill" />
              {(provision.error as Error).message}
            </div>
          )}

          <Button
            type="submit"
            disabled={provision.isPending}
            className="w-full h-11 bg-primary text-white hover:bg-primary/90 font-semibold"
          >
            {provision.isPending ? 'Provisioning…' : 'Provision Gym Admin'}
          </Button>
        </form>
      </GlassCard>
    </div>
  )
}
