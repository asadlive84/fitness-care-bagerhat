'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { useCreateMember } from '@/hooks/use-admin'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { ArrowLeft, Copy, Check } from '@phosphor-icons/react'

export default function CreateMember() {
  const router = useRouter()
  const create = useCreateMember()
  const [copied, setCopied] = useState(false)
  const [result, setResult] = useState<{ name: string; tempPassword: string } | null>(null)
  const [form, setForm] = useState({
    name: '', phone: '', gender: 'Male', goal: '',
    current_weight: '', height_cm: '', blood_group: '',
    religion: '', occupation: '', emergency_phone: '',
    present_address: '', permanent_address: '',
  })

  const set = (k: string, v: string) => setForm((f) => ({ ...f, [k]: v }))

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    const res = await create.mutateAsync({
      name:             form.name,
      phone:            form.phone,
      gender:           form.gender,
      goal:             form.goal || undefined,
      current_weight:   form.current_weight ? Number(form.current_weight) : undefined,
      height_cm:        form.height_cm ? Number(form.height_cm) : undefined,
      blood_group:      form.blood_group || undefined,
      religion:         form.religion || undefined,
      occupation:       form.occupation || undefined,
      emergency_phone:  form.emergency_phone || undefined,
      present_address:  form.present_address || undefined,
      permanent_address: form.permanent_address || undefined,
    })
    setResult({ name: res.member.name, tempPassword: res.temp_password })
  }

  function copyPw() {
    if (!result) return
    navigator.clipboard.writeText(result.tempPassword)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  if (result) {
    return (
      <div className="p-4 md:p-6 max-w-sm mx-auto flex flex-col items-center text-center pt-20">
        <div className="w-16 h-16 rounded-full bg-green-100 flex items-center justify-center mb-4">
          <Check size={28} className="text-green-600" />
        </div>
        <h2 className="text-xl font-bold mb-1">Member Created!</h2>
        <p className="text-sm text-muted-foreground mb-6">Share the temporary password with {result.name}</p>
        <div className="w-full bg-amber-50 border border-amber-200 rounded-2xl p-5 mb-5">
          <p className="text-xs text-amber-600 font-medium mb-2">Temporary Password</p>
          <p className="font-mono text-2xl font-bold tracking-wider text-amber-800">{result.tempPassword}</p>
          <button onClick={copyPw} className="mt-3 text-xs flex items-center gap-1 text-amber-600 mx-auto hover:text-amber-800 transition-colors">
            {copied ? <Check size={12} /> : <Copy size={12} />}
            {copied ? 'Copied!' : 'Copy password'}
          </button>
        </div>
        <Button className="w-full bg-primary text-white hover:bg-primary/90" onClick={() => router.replace('/admin/members')}>
          Done
        </Button>
      </div>
    )
  }

  return (
    <div className="p-4 md:p-6 max-w-lg mx-auto">
      <button onClick={() => router.back()} className="flex items-center gap-1 text-sm text-muted-foreground mb-5 hover:text-foreground transition-colors">
        <ArrowLeft size={14} /> Back
      </button>
      <h1 className="text-xl font-bold mb-5">Add New Member</h1>

      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="grid grid-cols-2 gap-3">
          <div className="col-span-2">
            <Label className="text-xs">Full Name *</Label>
            <Input value={form.name} onChange={(e) => set('name', e.target.value)} required className="mt-1 h-10" />
          </div>
          <div className="col-span-2">
            <Label className="text-xs">Phone *</Label>
            <Input value={form.phone} onChange={(e) => set('phone', e.target.value)} required type="tel" placeholder="+8801700000000" className="mt-1 h-10" />
          </div>
          <div>
            <Label className="text-xs">Gender *</Label>
            <select value={form.gender} onChange={(e) => set('gender', e.target.value)} className="mt-1 h-10 w-full rounded-md border border-input bg-background px-3 text-sm">
              {['Male', 'Female', 'Other'].map((g) => <option key={g}>{g}</option>)}
            </select>
          </div>
          <div>
            <Label className="text-xs">Blood Group</Label>
            <select value={form.blood_group} onChange={(e) => set('blood_group', e.target.value)} className="mt-1 h-10 w-full rounded-md border border-input bg-background px-3 text-sm">
              <option value="">—</option>
              {['A+','A-','B+','B-','AB+','AB-','O+','O-'].map((bg) => <option key={bg}>{bg}</option>)}
            </select>
          </div>
          {[
            { key: 'goal',             label: 'Fitness Goal' },
            { key: 'current_weight',   label: 'Weight (kg)',  type: 'number' },
            { key: 'height_cm',        label: 'Height (cm)',  type: 'number' },
            { key: 'religion',         label: 'Religion' },
            { key: 'occupation',       label: 'Occupation' },
            { key: 'emergency_phone',  label: 'Emergency Phone', type: 'tel' },
            { key: 'present_address',  label: 'Present Address' },
            { key: 'permanent_address',label: 'Permanent Address' },
          ].map(({ key, label, type }) => (
            <div key={key}>
              <Label className="text-xs">{label}</Label>
              <Input type={type ?? 'text'} value={(form as Record<string,string>)[key]} onChange={(e) => set(key, e.target.value)} className="mt-1 h-10" />
            </div>
          ))}
        </div>

        <Button type="submit" disabled={create.isPending} className="w-full bg-primary text-white hover:bg-primary/90 mt-2">
          {create.isPending ? 'Creating…' : 'Create Member'}
        </Button>
        {create.error && <p className="text-sm text-destructive text-center">{String(create.error)}</p>}
      </form>
    </div>
  )
}
