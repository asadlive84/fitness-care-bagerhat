'use client'

import { useState, useMemo } from 'react'
import { useFinancialsReport, useExpenses, useExpensesSummary, useRecordExpense } from '@/hooks/use-financials'
import { GlassCard, StatTile } from '@/components/glass-card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Skeleton } from '@/components/ui/skeleton'
import { TrendUp, TrendDown, Wallet, Coins, Receipt, Plus, Tag } from '@phosphor-icons/react'
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid, Legend } from 'recharts'
import { cn } from '@/lib/utils'

type Range = 'this_month' | 'last_month' | 'custom'

const CATEGORIES = ['Utility', 'Salary', 'Equipment', 'Maintenance', 'Marketing', 'Rent', 'Water', 'Electricity', 'Other']

// Convert a Date to ISO datetime that the backend accepts (UTC).
function isoDateTime(d: Date): string {
  return d.toISOString()
}

export default function FinancialsHub() {
  const [range, setRange] = useState<Range>('this_month')
  const [customFrom, setCustomFrom] = useState('')
  const [customTo,   setCustomTo]   = useState('')
  const [expenseOpen, setExpenseOpen] = useState(false)

  const { from, to } = useMemo(() => {
    const now = new Date()
    if (range === 'this_month') {
      const start = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0)
      const end   = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59)
      return { from: isoDateTime(start), to: isoDateTime(end) }
    }
    if (range === 'last_month') {
      const start = new Date(now.getFullYear(), now.getMonth() - 1, 1, 0, 0, 0)
      const end   = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59)
      return { from: isoDateTime(start), to: isoDateTime(end) }
    }
    if (customFrom && customTo) {
      return { from: isoDateTime(new Date(customFrom + 'T00:00:00')),
               to:   isoDateTime(new Date(customTo + 'T23:59:59')) }
    }
    return { from: '', to: '' }
  }, [range, customFrom, customTo])

  const { data: report, isLoading: reportLoading } = useFinancialsReport({ from, to })
  const { data: expenses = [] }                    = useExpenses({})
  const { data: summary }                          = useExpensesSummary()

  const income = report?.total_income ?? 0
  const cost   = report?.total_cost   ?? 0
  const net    = report?.net_profit   ?? (income - cost)
  const margin = income > 0 ? (net / income) * 100 : 0

  const chartData = (report?.timeline ?? []).map((d) => ({
    date: new Date(d.date).toLocaleDateString('en-GB', { day: 'numeric', month: 'short' }),
    Earnings: d.earnings,
    Expenses: d.expenses,
  }))

  return (
    <div className="p-4 md:p-8 max-w-6xl mx-auto space-y-6">
      <header className="flex flex-col sm:flex-row sm:items-end sm:justify-between gap-3">
        <div>
          <h1 className="text-2xl md:text-3xl font-bold tracking-tight">Financial Hub</h1>
          <p className="text-sm text-muted-foreground mt-1">A calm view of your gym&apos;s flow of value.</p>
        </div>
        <Button onClick={() => setExpenseOpen(true)} className="gap-1.5 bg-primary text-white hover:bg-primary/90 self-start sm:self-auto">
          <Plus size={14} /> Log Expense
        </Button>
      </header>

      {/* Quick at-a-glance from /expenses/summary (lifetime view) */}
      {summary && (
        <div className="grid grid-cols-3 gap-2 sm:gap-4">
          <QuickTile label="Today's Spend"     value={summary.today_total} />
          <QuickTile label="Yesterday's Spend" value={summary.yesterday_total} />
          <QuickTile label="This Month Spend"  value={summary.month_total} />
        </div>
      )}

      {/* Range pills */}
      <div className="flex flex-wrap items-center gap-2">
        {([
          ['this_month', 'This Month'],
          ['last_month', 'Previous Month'],
          ['custom',     'Custom Range'],
        ] as const).map(([key, label]) => (
          <button
            key={key}
            onClick={() => setRange(key)}
            className={cn(
              'px-4 py-1.5 rounded-full text-xs font-semibold transition-colors',
              range === key
                ? 'bg-primary text-white shadow-sm'
                : 'glass hover:bg-white/80 text-foreground',
            )}
          >
            {label}
          </button>
        ))}
        {range === 'custom' && (
          <div className="flex gap-2 ml-2 items-center">
            <Input type="date" value={customFrom} onChange={(e) => setCustomFrom(e.target.value)} className="h-8 text-xs w-36 bg-white/60" />
            <span className="text-muted-foreground text-xs">→</span>
            <Input type="date" value={customTo}   onChange={(e) => setCustomTo(e.target.value)}   className="h-8 text-xs w-36 bg-white/60" />
          </div>
        )}
      </div>

      {/* Stat tiles */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        {reportLoading ? (
          [0, 1, 2].map((i) => <Skeleton key={i} className="h-32 rounded-2xl" />)
        ) : (
          <>
            <StatTile
              label="Total Inflow"
              value={<>৳{income.toLocaleString()}</>}
              icon={<Coins size={20} weight="bold" />}
              tint="success"
            />
            <StatTile
              label="Operational Cost"
              value={<>৳{cost.toLocaleString()}</>}
              icon={<Receipt size={20} weight="bold" />}
              tint="warning"
            />
            <StatTile
              label="Net Margin"
              value={<>৳{net.toLocaleString()}</>}
              icon={net >= 0 ? <TrendUp size={20} weight="bold" /> : <TrendDown size={20} weight="bold" />}
              tint={net >= 0 ? 'primary' : 'error'}
              delta={income > 0 ? { value: margin, positive: net >= 0 } : undefined}
            />
          </>
        )}
      </div>

      {/* Comparison chart */}
      <GlassCard className="p-5">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h3 className="font-semibold">Earnings vs Expenses</h3>
            <p className="text-xs text-muted-foreground">Daily flow within the selected window</p>
          </div>
          <Wallet size={20} className="text-muted-foreground" />
        </div>
        <div className="h-[260px]">
          {chartData.length === 0 ? (
            <div className="flex items-center justify-center h-full text-sm text-muted-foreground">
              No financial activity in this range.
            </div>
          ) : (
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={chartData} margin={{ top: 4, right: 8, bottom: 0, left: -10 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" vertical={false} />
                <XAxis dataKey="date" tick={{ fontSize: 10, fill: '#5E6E62' }} axisLine={false} tickLine={false} />
                <YAxis  tick={{ fontSize: 10, fill: '#5E6E62' }} axisLine={false} tickLine={false} tickFormatter={(v) => `৳${(v as number).toLocaleString()}`} />
                <Tooltip
                  contentStyle={{ fontSize: 12, borderRadius: 12, border: '1px solid #E5E7EB', background: 'rgba(255,255,255,0.95)', backdropFilter: 'blur(8px)' }}
                  formatter={(v) => `৳${Number(v).toLocaleString()}`}
                />
                <Legend wrapperStyle={{ fontSize: 11, paddingTop: 8 }} />
                <Bar dataKey="Earnings" fill="#1B5E20" radius={[6, 6, 0, 0]} maxBarSize={26} />
                <Bar dataKey="Expenses" fill="#FF6D00" radius={[6, 6, 0, 0]} maxBarSize={26} />
              </BarChart>
            </ResponsiveContainer>
          )}
        </div>
      </GlassCard>

      {/* Breakdown grids */}
      {report && (report.revenue_by_method.length > 0 || report.expenses_by_category.length > 0) && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {report.revenue_by_method.length > 0 && (
            <GlassCard className="p-5">
              <h3 className="font-semibold text-sm mb-3">Revenue by Method</h3>
              <div className="space-y-2">
                {report.revenue_by_method.map((m) => (
                  <div key={m.payment_method} className="flex items-center gap-3 bg-white/40 rounded-xl px-3 py-2.5 border border-border/40">
                    <span className="text-xs font-medium bg-emerald-100/60 text-emerald-700 px-2 py-0.5 rounded-full capitalize">{m.payment_method}</span>
                    <span className="text-[11px] text-muted-foreground">{m.transaction_count} txn</span>
                    <span className="ml-auto font-semibold numeric text-emerald-700">৳{m.total_amount.toLocaleString()}</span>
                  </div>
                ))}
              </div>
            </GlassCard>
          )}

          {report.expenses_by_category.length > 0 && (
            <GlassCard className="p-5">
              <h3 className="font-semibold text-sm mb-3">Expenses by Category</h3>
              <div className="space-y-2">
                {report.expenses_by_category.map((e) => (
                  <div key={e.category} className="flex items-center gap-3 bg-white/40 rounded-xl px-3 py-2.5 border border-border/40">
                    <Tag size={12} className="text-accent shrink-0" />
                    <span className="text-xs font-medium text-foreground capitalize">{e.category}</span>
                    <span className="text-[11px] text-muted-foreground">{e.expense_count} entry</span>
                    <span className="ml-auto font-semibold numeric text-accent">৳{e.total_amount.toLocaleString()}</span>
                  </div>
                ))}
              </div>
            </GlassCard>
          )}
        </div>
      )}

      {/* Expense ledger */}
      <GlassCard className="p-5">
        <div className="flex items-center justify-between mb-4">
          <h3 className="font-semibold">Logged Expenses</h3>
          <span className="text-xs text-muted-foreground">{expenses.length} entries</span>
        </div>
        {expenses.length === 0 ? (
          <p className="text-sm text-muted-foreground text-center py-8">
            No expenses logged yet.
          </p>
        ) : (
          <div className="space-y-2">
            {expenses.map((e) => (
              <div key={e.id} className="flex items-center gap-3 bg-white/40 rounded-xl px-4 py-3 border border-border/40">
                <div className="w-9 h-9 rounded-lg bg-orange-50 text-accent flex items-center justify-center shrink-0">
                  <Receipt size={16} weight="bold" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium truncate">{e.description}</p>
                  <p className="text-xs text-muted-foreground">
                    <span className="inline-block bg-muted px-2 py-0.5 rounded-full mr-2">{e.category}</span>
                    {new Date(e.spent_at).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })}
                  </p>
                </div>
                <p className="font-semibold numeric text-foreground">৳{e.amount.toLocaleString()}</p>
              </div>
            ))}
          </div>
        )}
      </GlassCard>

      <LogExpenseDialog open={expenseOpen} onClose={() => setExpenseOpen(false)} />
    </div>
  )
}

// ── Tiny tile ────────────────────────────────────────────────────────────────

function QuickTile({ label, value }: { label: string; value: number }) {
  return (
    <GlassCard variant="subtle" className="p-3 text-center">
      <p className="text-base sm:text-lg font-bold numeric text-foreground">৳{value.toLocaleString()}</p>
      <p className="text-[10px] sm:text-xs text-muted-foreground mt-0.5">{label}</p>
    </GlassCard>
  )
}

// ── Dialog ────────────────────────────────────────────────────────────────────

function LogExpenseDialog({ open, onClose }: { open: boolean; onClose: () => void }) {
  const record = useRecordExpense()
  const [form, setForm] = useState({ amount: '', description: '', category: 'Other', spent_at: new Date().toISOString().slice(0, 10) })
  const set = (k: string, v: string) => setForm((f) => ({ ...f, [k]: v }))

  async function handleSubmit() {
    if (!form.amount || !form.description) return
    await record.mutateAsync({
      amount: Number(form.amount),
      description: form.description,
      category: form.category,
      spent_at: new Date(form.spent_at + 'T00:00:00').toISOString(),
    })
    setForm({ amount: '', description: '', category: 'Other', spent_at: new Date().toISOString().slice(0, 10) })
    onClose()
  }

  return (
    <Dialog open={open} onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="max-w-sm">
        <DialogHeader><DialogTitle>Log Expense</DialogTitle></DialogHeader>
        <div className="space-y-3 mt-2">
          <div className="grid grid-cols-2 gap-2">
            <div>
              <Label className="text-xs">Amount (৳)</Label>
              <Input type="number" value={form.amount} onChange={(e) => set('amount', e.target.value)} className="mt-1 h-10" />
            </div>
            <div>
              <Label className="text-xs">Category</Label>
              <select value={form.category} onChange={(e) => set('category', e.target.value)}
                className="mt-1 h-10 w-full rounded-md border border-input bg-background px-3 text-sm">
                {CATEGORIES.map((c) => <option key={c}>{c}</option>)}
              </select>
            </div>
          </div>
          <div>
            <Label className="text-xs">Description</Label>
            <Input value={form.description} onChange={(e) => set('description', e.target.value)} placeholder="Electric bill, equipment, …" className="mt-1 h-10" />
          </div>
          <div>
            <Label className="text-xs">Date</Label>
            <Input type="date" value={form.spent_at} onChange={(e) => set('spent_at', e.target.value)} className="mt-1 h-10" />
          </div>
          <Button onClick={handleSubmit} disabled={!form.amount || !form.description || record.isPending}
            className="w-full bg-primary text-white hover:bg-primary/90">
            {record.isPending ? 'Logging…' : 'Log Expense'}
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  )
}
