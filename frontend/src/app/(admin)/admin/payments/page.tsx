'use client'

import { useState } from 'react'
import { usePaymentSummary, useRecordPayment, useAdminMembers } from '@/hooks/use-admin'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Money, Plus } from '@phosphor-icons/react'
import { useDebounce } from '@/hooks/use-debounce'

export default function AdminPayments() {
  const month   = new Date().toISOString().slice(0, 7)
  const { data: summary } = usePaymentSummary(month)
  const record  = useRecordPayment()
  const [open, setOpen] = useState(false)
  const [memberSearch, setMemberSearch] = useState('')
  const [selectedMemberId, setSelectedMemberId] = useState('')
  const [amount, setAmount] = useState('')
  const [method, setMethod] = useState('cash')
  const [note,   setNote]   = useState('')

  const debouncedSearch = useDebounce(memberSearch, 300)
  const { data: memberResults } = useAdminMembers({ search: debouncedSearch, status: 'active' })
  const members = memberSearch.length >= 2 ? (memberResults?.data ?? []) : []

  async function handleRecord() {
    if (!selectedMemberId || !amount) return
    await record.mutateAsync({ member_id: selectedMemberId, amount: Number(amount), method, note: note || undefined })
    setOpen(false); setAmount(''); setNote(''); setSelectedMemberId(''); setMemberSearch('')
  }

  return (
    <div className="p-4 md:p-6 max-w-2xl mx-auto space-y-5">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold">Payments</h1>
        <Button size="sm" onClick={() => setOpen(true)} className="gap-1.5 bg-primary text-white hover:bg-primary/90">
          <Plus size={14} /> Record Payment
        </Button>
      </div>

      {/* Monthly summary */}
      {summary && (
        <div className="grid grid-cols-2 gap-3">
          <div className="bg-card border border-border rounded-2xl p-4">
            <div className="w-9 h-9 rounded-xl bg-green-50 flex items-center justify-center mb-2">
              <Money size={18} className="text-green-600" />
            </div>
            <p className="text-xl font-bold text-green-600">৳{summary.total_amount.toLocaleString()}</p>
            <p className="text-xs text-muted-foreground">Revenue in {month}</p>
          </div>
          <div className="bg-card border border-border rounded-2xl p-4">
            <div className="w-9 h-9 rounded-xl bg-blue-50 flex items-center justify-center mb-2">
              <Money size={18} className="text-blue-600" />
            </div>
            <p className="text-xl font-bold">{summary.payment_count}</p>
            <p className="text-xs text-muted-foreground">Payments recorded</p>
          </div>
        </div>
      )}

      {/* Record Payment dialog */}
      <Dialog open={open} onOpenChange={(o) => { if (!o) setOpen(false) }}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>Record Payment</DialogTitle>
          </DialogHeader>
          <div className="space-y-3 mt-2">
            <div>
              <Label className="text-xs">Member</Label>
              <Input value={memberSearch} onChange={(e) => { setMemberSearch(e.target.value); setSelectedMemberId('') }}
                placeholder="Search member…" className="mt-1 h-10" />
              {members.length > 0 && !selectedMemberId && (
                <div className="mt-1 border border-border rounded-lg overflow-hidden max-h-36 overflow-y-auto">
                  {members.map((m) => (
                    <button key={m.id} onClick={() => { setSelectedMemberId(m.id); setMemberSearch(m.name) }}
                      className="w-full text-left px-3 py-2 text-sm hover:bg-muted flex justify-between">
                      <span>{m.name}</span>
                      <span className="text-muted-foreground text-xs">{m.phone}</span>
                    </button>
                  ))}
                </div>
              )}
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <Label className="text-xs">Amount (৳)</Label>
                <Input type="number" value={amount} onChange={(e) => setAmount(e.target.value)} className="mt-1 h-10" />
              </div>
              <div>
                <Label className="text-xs">Method</Label>
                <select value={method} onChange={(e) => setMethod(e.target.value)}
                  className="mt-1 h-10 w-full rounded-md border border-input bg-background px-3 text-sm">
                  {['cash', 'bkash', 'nagad', 'card', 'bank'].map((m) => <option key={m}>{m}</option>)}
                </select>
              </div>
            </div>
            <div>
              <Label className="text-xs">Note (optional)</Label>
              <Input value={note} onChange={(e) => setNote(e.target.value)} className="mt-1 h-10" />
            </div>
            <Button onClick={handleRecord} disabled={!selectedMemberId || !amount || record.isPending} className="w-full bg-primary text-white hover:bg-primary/90">
              {record.isPending ? 'Recording…' : 'Record Payment'}
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  )
}
