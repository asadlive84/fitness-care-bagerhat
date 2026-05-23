'use client'

import { useState } from 'react'
import { useAdminPlans, useCreatePlan, useUpdatePlan, useDeletePlan } from '@/hooks/use-admin'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Skeleton } from '@/components/ui/skeleton'
import { Scroll, Plus, PencilSimple, Trash, Users } from '@phosphor-icons/react'
import type { Plan } from '@/types/admin'

type PlanForm = { name: string; default_price: string; duration_days: string; billing_type: string }
const EMPTY: PlanForm = { name: '', default_price: '', duration_days: '', billing_type: 'prepaid' }

export default function AdminPlans() {
  const { data: plans = [], isLoading } = useAdminPlans()
  const createPlan = useCreatePlan()
  const deletePlan = useDeletePlan()
  const [editing, setEditing]   = useState<Plan | null>(null)
  const [creating, setCreating] = useState(false)
  const [form, setForm]         = useState<PlanForm>(EMPTY)

  const set = (k: string, v: string) => setForm((f) => ({ ...f, [k]: v }))

  function openCreate() { setForm(EMPTY); setCreating(true) }
  function openEdit(p: Plan) {
    setEditing(p)
    setForm({ name: p.name, default_price: String(p.default_price), duration_days: String(p.duration_days), billing_type: p.billing_type })
  }

  const updatePlan = useUpdatePlan(editing?.id ?? '')

  async function handleSave() {
    const payload = { name: form.name, default_price: Number(form.default_price), duration_days: Number(form.duration_days), billing_type: form.billing_type as 'prepaid' | 'postpaid' }
    if (editing) { await updatePlan.mutateAsync(payload); setEditing(null) }
    else { await createPlan.mutateAsync(payload); setCreating(false) }
  }

  const isPending = createPlan.isPending || updatePlan.isPending

  return (
    <div className="p-4 md:p-6 max-w-3xl mx-auto">
      <div className="flex items-center justify-between mb-5">
        <h1 className="text-xl font-bold">Plans</h1>
        <Button size="sm" onClick={openCreate} className="gap-1.5 bg-primary text-white hover:bg-primary/90">
          <Plus size={14} /> New Plan
        </Button>
      </div>

      {isLoading ? (
        <div className="space-y-3">{Array.from({ length: 3 }).map((_, i) => <Skeleton key={i} className="h-32 rounded-2xl" />)}</div>
      ) : plans.length === 0 ? (
        <div className="text-center py-16 text-muted-foreground">
          <Scroll size={36} className="mx-auto mb-3 opacity-30" />
          <p className="text-sm">No plans yet. Create your first plan.</p>
        </div>
      ) : (
        <div className="grid sm:grid-cols-2 gap-3">
          {plans.map((plan) => (
            <div key={plan.id} className="bg-card border border-border rounded-2xl p-4">
              <div className="flex justify-between items-start mb-3">
                <div>
                  <p className="font-bold">{plan.name}</p>
                  <p className="text-xs text-muted-foreground mt-0.5">
                    {plan.duration_days >= 28
                      ? `${Math.round(plan.duration_days / 30)} month${Math.round(plan.duration_days / 30) > 1 ? 's' : ''}`
                      : `${plan.duration_days} days`}
                    {' · '}
                    <span className={plan.billing_type === 'prepaid' ? 'text-green-600' : 'text-blue-600'}>
                      {plan.billing_type}
                    </span>
                  </p>
                </div>
                <p className="text-lg font-bold text-primary">৳{plan.default_price.toLocaleString()}</p>
              </div>

              {plan.subscribers && plan.subscribers.length > 0 && (
                <div className="flex items-center gap-1 text-xs text-muted-foreground mb-3">
                  <Users size={12} />
                  {plan.subscribers.length} subscriber{plan.subscribers.length !== 1 ? 's' : ''}
                </div>
              )}

              <div className="flex gap-2">
                <Button size="sm" variant="outline" className="flex-1 gap-1" onClick={() => openEdit(plan)}>
                  <PencilSimple size={12} /> Edit
                </Button>
                <Button size="sm" variant="outline" className="gap-1 text-destructive hover:bg-red-50 border-destructive/30"
                  onClick={() => confirm(`Delete "${plan.name}"?`) && deletePlan.mutate(plan.id)}>
                  <Trash size={12} />
                </Button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Create / Edit dialog */}
      <Dialog open={creating || !!editing} onOpenChange={(o) => { if (!o) { setCreating(false); setEditing(null) } }}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>{editing ? 'Edit Plan' : 'New Plan'}</DialogTitle>
          </DialogHeader>
          <div className="space-y-3 mt-2">
            <div>
              <Label className="text-xs">Plan Name</Label>
              <Input value={form.name} onChange={(e) => set('name', e.target.value)} placeholder="Monthly Membership" className="mt-1 h-10" />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <Label className="text-xs">Price (৳)</Label>
                <Input type="number" value={form.default_price} onChange={(e) => set('default_price', e.target.value)} className="mt-1 h-10" />
              </div>
              <div>
                <Label className="text-xs">Duration (days)</Label>
                <Input type="number" value={form.duration_days} onChange={(e) => set('duration_days', e.target.value)} className="mt-1 h-10" />
              </div>
            </div>
            <div>
              <Label className="text-xs">Billing Type</Label>
              <select value={form.billing_type} onChange={(e) => set('billing_type', e.target.value)}
                className="mt-1 h-10 w-full rounded-md border border-input bg-background px-3 text-sm">
                <option value="prepaid">Prepaid</option>
                <option value="postpaid">Postpaid</option>
              </select>
            </div>
            <Button onClick={handleSave} disabled={!form.name || !form.default_price || !form.duration_days || isPending}
              className="w-full bg-primary text-white hover:bg-primary/90">
              {isPending ? 'Saving…' : editing ? 'Save Changes' : 'Create Plan'}
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  )
}
