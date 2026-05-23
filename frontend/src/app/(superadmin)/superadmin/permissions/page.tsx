'use client'

import { useSAMembers, useSAToggleAI } from '@/hooks/use-superadmin'
import { useAdminSettings, useUpsertSetting } from '@/hooks/use-admin'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import { Lock, ToggleLeft, ToggleRight, Check } from '@phosphor-icons/react'
import { useState } from 'react'

export default function SuperAdminPermissions() {
  const { data: settings = [], isLoading: loadingSettings } = useAdminSettings()
  const upsert  = useUpsertSetting()
  const toggleAI = useSAToggleAI()
  const { data } = useSAMembers({ status: 'all' })
  const members = data?.data ?? []

  const [saved, setSaved] = useState<string | null>(null)
  const [drafts, setDrafts] = useState<Record<string, string>>({})

  async function saveSetting(key: string) {
    if (!(key in drafts)) return
    const val = isNaN(Number(drafts[key])) ? drafts[key] : Number(drafts[key])
    await upsert.mutateAsync({ key, value: val })
    setSaved(key); setTimeout(() => setSaved(null), 1500)
  }

  async function disableAllAI() {
    if (!confirm('Disable AI for ALL members?')) return
    for (const m of members.filter((m) => m.is_ai_allowed)) {
      await toggleAI.mutateAsync({ id: m.id, is_ai_allowed: false })
    }
  }

  async function enableAllAI() {
    if (!confirm('Enable AI for ALL members?')) return
    for (const m of members.filter((m) => !m.is_ai_allowed)) {
      await toggleAI.mutateAsync({ id: m.id, is_ai_allowed: true })
    }
  }

  return (
    <div className="p-4 md:p-6 max-w-2xl mx-auto space-y-6">
      <div className="flex items-center gap-2">
        <Lock size={20} className="text-primary" />
        <h1 className="text-xl font-bold">Global Permissions</h1>
      </div>

      {/* Bulk AI controls */}
      <div className="bg-card border border-border rounded-2xl p-4 space-y-3">
        <p className="font-semibold text-sm">AI Feature — Bulk Control</p>
        <p className="text-xs text-muted-foreground">
          {members.filter((m) => m.is_ai_allowed).length} / {members.length} members have AI enabled.
        </p>
        <div className="flex gap-2">
          <Button size="sm" onClick={enableAllAI}  disabled={toggleAI.isPending} className="flex-1 bg-primary text-white hover:bg-primary/90">
            Enable AI for All
          </Button>
          <Button size="sm" onClick={disableAllAI} disabled={toggleAI.isPending} variant="outline" className="flex-1 text-destructive hover:bg-red-50 border-destructive/30">
            Disable AI for All
          </Button>
        </div>
      </div>

      {/* System settings */}
      <div className="space-y-3">
        <p className="font-semibold text-sm">System Settings</p>
        {loadingSettings
          ? <Skeleton className="h-32 rounded-2xl" />
          : settings.map((s) => (
              <div key={s.key} className="bg-card border border-border rounded-xl p-4 flex items-center gap-3">
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium">{s.key.replace(/_/g, ' ')}</p>
                  <input
                    className="mt-1 w-full h-8 px-2 text-sm rounded-md border border-input bg-background focus:outline-none focus:ring-1 focus:ring-ring"
                    value={s.key in drafts ? drafts[s.key] : String(s.value ?? '')}
                    onChange={(e) => setDrafts((d) => ({ ...d, [s.key]: e.target.value }))}
                  />
                </div>
                <Button size="sm" onClick={() => saveSetting(s.key)}
                  disabled={!(s.key in drafts) || upsert.isPending}
                  className={`shrink-0 ${saved === s.key ? 'bg-green-500 text-white' : 'bg-primary text-white hover:bg-primary/90'}`}>
                  {saved === s.key ? <Check size={12} /> : 'Save'}
                </Button>
              </div>
            ))
        }
      </div>

      {/* Info box */}
      <div className="bg-muted rounded-xl px-4 py-3 text-xs text-muted-foreground">
        <strong>Coming soon:</strong> Per-admin role toggles (disable admin portal, read-only mode, rate limiting) require a dedicated superadmin backend endpoint.
      </div>
    </div>
  )
}
