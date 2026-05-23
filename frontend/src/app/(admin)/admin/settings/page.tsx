'use client'

import { useState } from 'react'
import { useAdminSettings, useUpsertSetting } from '@/hooks/use-admin'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Skeleton } from '@/components/ui/skeleton'
import { Check } from '@phosphor-icons/react'

// Human-readable labels for known setting keys
const KEY_LABELS: Record<string, { label: string; description: string; type: 'number' | 'text' | 'json' }> = {
  subscription_reminder_days: { label: 'Renewal Reminder (days before)', description: 'Days before expiry to send renewal reminder', type: 'number' },
  quiet_window_start:         { label: 'Quiet Hours Start',              description: '24h format, e.g. 22 for 10 PM',                type: 'number' },
  quiet_window_end:           { label: 'Quiet Hours End',                description: '24h format, e.g. 7 for 7 AM',                 type: 'number' },
  weight_reminder_days:       { label: 'Weight Log Reminder (days)',     description: 'Remind if no weight log in N days',            type: 'number' },
  gym_name:                   { label: 'Gym Name',                       description: 'Displayed to members',                        type: 'text' },
  gym_address:                { label: 'Gym Address',                    description: 'Full address',                                type: 'text' },
  gym_phone:                  { label: 'Gym Phone',                      description: 'Contact number',                             type: 'text' },
}

export default function AdminSettings() {
  const { data: settings = [], isLoading } = useAdminSettings()
  const upsert = useUpsertSetting()
  const [saved, setSaved] = useState<string | null>(null)
  const [drafts, setDrafts] = useState<Record<string, string>>({})

  function getDraft(key: string, raw: unknown): string {
    if (key in drafts) return drafts[key]
    return raw !== null && raw !== undefined ? String(raw) : ''
  }

  async function handleSave(key: string) {
    const val = drafts[key]
    if (val === undefined) return
    const meta = KEY_LABELS[key]
    const parsed = meta?.type === 'number' ? Number(val) : val
    await upsert.mutateAsync({ key, value: parsed })
    setSaved(key)
    setTimeout(() => setSaved(null), 1500)
  }

  if (isLoading) return (
    <div className="p-4 md:p-6 max-w-lg mx-auto space-y-3">
      {Array.from({ length: 5 }).map((_, i) => <Skeleton key={i} className="h-16 rounded-xl" />)}
    </div>
  )

  return (
    <div className="p-4 md:p-6 max-w-lg mx-auto space-y-5">
      <h1 className="text-xl font-bold">Settings</h1>

      {settings.map((s) => {
        const meta    = KEY_LABELS[s.key]
        const label   = meta?.label ?? s.key.replace(/_/g, ' ')
        const desc    = meta?.description ?? ''
        const current = getDraft(s.key, s.value)

        return (
          <div key={s.key} className="bg-card border border-border rounded-xl p-4">
            <p className="text-sm font-semibold">{label}</p>
            {desc && <p className="text-xs text-muted-foreground mb-2">{desc}</p>}
            <div className="flex gap-2 mt-2">
              <Input
                value={current}
                onChange={(e) => setDrafts((d) => ({ ...d, [s.key]: e.target.value }))}
                type={meta?.type === 'number' ? 'number' : 'text'}
                className="flex-1 h-9"
              />
              <Button
                size="sm"
                onClick={() => handleSave(s.key)}
                disabled={upsert.isPending || !(s.key in drafts)}
                className={`gap-1 ${saved === s.key ? 'bg-green-500 text-white' : 'bg-primary text-white hover:bg-primary/90'}`}
              >
                {saved === s.key ? <Check size={12} /> : 'Save'}
              </Button>
            </div>
          </div>
        )
      })}

      {settings.length === 0 && (
        <p className="text-center text-muted-foreground text-sm py-12">No settings configured yet.</p>
      )}
    </div>
  )
}
