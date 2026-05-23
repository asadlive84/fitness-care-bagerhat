'use client'

import { useState } from 'react'
import { useMemberProfile, useUpdateProfile } from '@/hooks/use-member'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Skeleton } from '@/components/ui/skeleton'
import { Check, PencilSimple } from '@phosphor-icons/react'

export default function MemberProfile() {
  const { data: member, isLoading } = useMemberProfile()
  const update = useUpdateProfile()
  const [editing, setEditing] = useState(false)
  const [form, setForm] = useState<Record<string, string>>({})

  function startEdit() {
    if (!member) return
    setForm({
      name:             member.name ?? '',
      goal:             member.goal ?? '',
      current_weight:   String(member.current_weight ?? ''),
      height_cm:        String(member.height_cm ?? ''),
      occupation:       member.occupation ?? '',
      present_address:  member.present_address ?? '',
      emergency_phone:  member.emergency_phone ?? '',
    })
    setEditing(true)
  }

  async function save() {
    await update.mutateAsync({
      name:            form.name,
      goal:            form.goal || undefined,
      current_weight:  form.current_weight ? Number(form.current_weight) : undefined,
      height_cm:       form.height_cm ? Number(form.height_cm) : undefined,
      occupation:      form.occupation || undefined,
      present_address: form.present_address || undefined,
      emergency_phone: form.emergency_phone || undefined,
    })
    setEditing(false)
  }

  if (isLoading) return (
    <div className="p-4 md:p-6 max-w-lg mx-auto space-y-4">
      {Array.from({ length: 6 }).map((_, i) => <Skeleton key={i} className="h-14 rounded-xl" />)}
    </div>
  )

  const fields: Array<{ key: string; label: string; type?: string }> = [
    { key: 'name',            label: 'Full Name' },
    { key: 'goal',            label: 'Fitness Goal' },
    { key: 'current_weight',  label: 'Weight (kg)',   type: 'number' },
    { key: 'height_cm',       label: 'Height (cm)',   type: 'number' },
    { key: 'occupation',      label: 'Occupation' },
    { key: 'present_address', label: 'Present Address' },
    { key: 'emergency_phone', label: 'Emergency Phone' },
  ]

  return (
    <div className="p-4 md:p-6 max-w-lg mx-auto">
      <div className="flex items-center justify-between mb-5">
        <div>
          <h1 className="text-xl font-bold">My Profile</h1>
          <p className="text-xs text-muted-foreground">{member?.phone}</p>
        </div>
        {!editing ? (
          <Button size="sm" variant="outline" onClick={startEdit} className="gap-1.5">
            <PencilSimple size={14} /> Edit
          </Button>
        ) : (
          <Button size="sm" onClick={save} disabled={update.isPending} className="gap-1.5 bg-primary text-white hover:bg-primary/90">
            <Check size={14} /> {update.isPending ? 'Saving…' : 'Save'}
          </Button>
        )}
      </div>

      {/* Read-only badges */}
      <div className="flex gap-2 flex-wrap mb-5">
        {member?.gender && <span className="text-xs bg-muted px-2 py-1 rounded-full">{member.gender}</span>}
        {member?.blood_group && <span className="text-xs bg-red-50 text-red-600 px-2 py-1 rounded-full">{member.blood_group}</span>}
        {member?.status && <span className={`text-xs px-2 py-1 rounded-full ${member.status === 'active' ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>{member.status}</span>}
        {member?.bmi && <span className="text-xs bg-blue-50 text-blue-600 px-2 py-1 rounded-full">BMI {member.bmi}</span>}
      </div>

      <div className="space-y-3">
        {fields.map(({ key, label, type }) => (
          <div key={key}>
            <Label className="text-xs text-muted-foreground">{label}</Label>
            {editing ? (
              <Input
                type={type ?? 'text'}
                value={form[key] ?? ''}
                onChange={(e) => setForm((f) => ({ ...f, [key]: e.target.value }))}
                className="mt-1 h-10"
              />
            ) : (
              <p className="text-sm font-medium mt-0.5">
                {(member as unknown as Record<string, unknown>)?.[key] ? String((member as unknown as Record<string, unknown>)[key]) : <span className="text-muted-foreground">—</span>}
              </p>
            )}
          </div>
        ))}
      </div>

      {/* Read-only info */}
      <div className="mt-5 pt-5 border-t border-border space-y-2">
        {[
          { label: 'NID', value: member?.nid },
          { label: 'Permanent Address', value: member?.permanent_address },
          { label: 'Join Date', value: member?.join_date },
          { label: 'Date of Birth', value: member?.date_of_birth },
        ].map(({ label, value }) => value ? (
          <div key={label}>
            <p className="text-xs text-muted-foreground">{label}</p>
            <p className="text-sm">{value}</p>
          </div>
        ) : null)}
      </div>
    </div>
  )
}
