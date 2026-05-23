'use client'

import { useState, useMemo } from 'react'
import { useAIAuditLogs, useAICostByGym, useAIHeavyUsers } from '@/hooks/use-ai-audit'
import { GlassCard, StatTile } from '@/components/glass-card'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import { ClipboardText, Brain, Buildings, Warning, ArrowLeft, ArrowRight, MagnifyingGlass, Coins, Receipt, Lightning, X } from '@phosphor-icons/react'
import type { AIAuditLog } from '@/hooks/use-ai-audit'
import { cn } from '@/lib/utils'

type Range = 'week' | 'month' | 'all'

const PROMPT_TYPE_PILL: Record<string, string> = {
  diet_chart: 'bg-emerald-100/70 text-emerald-700',
  food_log:   'bg-orange-100/70 text-accent',
  chat:       'bg-blue-100/60 text-blue-700',
}

export default function SuperAdminAudit() {
  const [range, setRange]                 = useState<Range>('month')
  const [promptType, setPromptType]       = useState('')
  const [adminFilter, setAdminFilter]     = useState('')
  const [page, setPage]                   = useState(1)
  const [selected, setSelected]           = useState<AIAuditLog | null>(null)

  const { from, to } = useMemo(() => {
    const now = new Date()
    if (range === 'week') {
      const start = new Date(now); start.setDate(now.getDate() - 7)
      return { from: start.toISOString(), to: now.toISOString() }
    }
    if (range === 'month') {
      const start = new Date(now); start.setDate(now.getDate() - 30)
      return { from: start.toISOString(), to: now.toISOString() }
    }
    return { from: undefined, to: undefined }
  }, [range])

  const { data: logsPage, isLoading: logsLoading } = useAIAuditLogs({
    admin_id:    adminFilter || undefined,
    prompt_type: promptType  || undefined,
    from, to, page, limit: 20,
  })
  const logs    = logsPage?.data ?? []
  const total   = logsPage?.meta?.total ?? 0
  const pages   = Math.ceil(total / 20)

  const { data: costByGym = [] }   = useAICostByGym({ from, to })
  const { data: heavyUsers = [] }  = useAIHeavyUsers({ from, to, threshold: 0, limit: 8 })

  const totalCost   = costByGym.reduce((s, r) => s + Number(r.total_cost), 0)
  const totalTokens = costByGym.reduce((s, r) => s + Number(r.total_tokens), 0)
  const totalCalls  = costByGym.reduce((s, r) => s + Number(r.total_executions), 0)

  return (
    <div className="p-4 md:p-8 max-w-6xl mx-auto space-y-6">
      <header>
        <div className="flex items-center gap-2 mb-1">
          <ClipboardText size={22} className="text-primary" />
          <h1 className="text-2xl md:text-3xl font-bold tracking-tight">AI Audit Ledger</h1>
        </div>
        <p className="text-sm text-muted-foreground">Every prompt, response, token and dollar — across every gym.</p>
      </header>

      {/* Range pills */}
      <div className="flex flex-wrap items-center gap-2">
        {([
          ['week',  'Last 7 days'],
          ['month', 'Last 30 days'],
          ['all',   'All time'],
        ] as const).map(([key, label]) => (
          <button
            key={key}
            onClick={() => { setRange(key); setPage(1) }}
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
      </div>

      {/* Stat tiles */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <StatTile label="Total AI Calls"   value={totalCalls.toLocaleString()}                          icon={<Lightning size={20} weight="bold" />} tint="info" />
        <StatTile label="Total Tokens"     value={totalTokens.toLocaleString()}                         icon={<Brain size={20} weight="bold" />}      tint="primary" />
        <StatTile label="Estimated Cost"   value={<>${totalCost.toFixed(4)}</>}                          icon={<Coins size={20} weight="bold" />}       tint="warning" />
      </div>

      {/* Cost by gym */}
      <GlassCard className="p-5">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <Buildings size={16} className="text-primary" />
            <h3 className="font-semibold text-sm">Cost by Gym</h3>
          </div>
          <span className="text-xs text-muted-foreground">{costByGym.length} gym{costByGym.length !== 1 ? 's' : ''}</span>
        </div>
        {costByGym.length === 0 ? (
          <p className="text-sm text-muted-foreground py-6 text-center">No AI activity in this window yet.</p>
        ) : (
          <div className="space-y-2">
            {costByGym.map((row) => {
              const ratio = totalCost > 0 ? (Number(row.total_cost) / totalCost) : 0
              return (
                <div key={row.admin_id} className="bg-white/40 rounded-xl px-4 py-3 border border-border/40">
                  <div className="flex items-center justify-between gap-3 mb-1.5">
                    <button
                      onClick={() => { setAdminFilter(row.admin_id); setPage(1) }}
                      className="text-sm font-medium hover:text-primary transition-colors text-left"
                    >
                      {row.admin_name}
                    </button>
                    <div className="flex items-center gap-3 shrink-0 text-xs">
                      <span className="numeric text-muted-foreground">{row.total_executions} calls</span>
                      <span className="numeric text-muted-foreground">{row.total_tokens.toLocaleString()} tok</span>
                      <span className="numeric font-semibold text-accent">${Number(row.total_cost).toFixed(4)}</span>
                    </div>
                  </div>
                  <div className="h-1.5 rounded-full bg-border/70 overflow-hidden">
                    <div className="h-full rounded-full bg-primary" style={{ width: `${ratio * 100}%` }} />
                  </div>
                </div>
              )
            })}
          </div>
        )}
      </GlassCard>

      {/* Heavy users */}
      <GlassCard className="p-5">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <Warning size={16} className="text-accent" />
            <h3 className="font-semibold text-sm">Heaviest AI Consumers</h3>
          </div>
        </div>
        {heavyUsers.length === 0 ? (
          <p className="text-sm text-muted-foreground py-4 text-center">No heavy consumers detected.</p>
        ) : (
          <div className="space-y-1">
            {heavyUsers.map((u) => (
              <div key={u.member_id} className="flex items-center gap-3 py-2 border-b border-border/30 last:border-0">
                <div className="w-7 h-7 rounded-full bg-orange-50 text-accent flex items-center justify-center shrink-0 text-[11px] font-bold">
                  {u.member_name.charAt(0).toUpperCase()}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium truncate">{u.member_name}</p>
                  <p className="text-[11px] text-muted-foreground">at {u.admin_name}</p>
                </div>
                <div className="text-right text-xs">
                  <p className="numeric font-semibold text-foreground">{u.total_tokens.toLocaleString()} tok</p>
                  <p className="numeric text-muted-foreground">{u.total_calls} calls · ${Number(u.total_cost).toFixed(4)}</p>
                </div>
              </div>
            ))}
          </div>
        )}
      </GlassCard>

      {/* Filters */}
      <GlassCard className="p-4 flex flex-wrap items-center gap-2">
        <div className="relative flex-1 min-w-[200px]">
          <MagnifyingGlass size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" />
          <Input
            value={adminFilter}
            onChange={(e) => { setAdminFilter(e.target.value); setPage(1) }}
            placeholder="Filter by admin UUID…"
            className="h-9 pl-9 bg-white/60 text-xs font-mono"
          />
        </div>
        <select
          value={promptType}
          onChange={(e) => { setPromptType(e.target.value); setPage(1) }}
          className="h-9 px-3 rounded-md border border-input bg-white/60 text-sm"
        >
          <option value="">All prompt types</option>
          <option value="diet_chart">Diet Chart</option>
          <option value="food_log">Food Log</option>
          <option value="chat">Chat</option>
        </select>
        {(adminFilter || promptType) && (
          <Button variant="outline" size="sm" onClick={() => { setAdminFilter(''); setPromptType(''); setPage(1) }}>
            Clear
          </Button>
        )}
      </GlassCard>

      {/* Log feed */}
      <GlassCard className="p-5">
        <div className="flex items-center justify-between mb-3">
          <h3 className="font-semibold text-sm">Recent Activity</h3>
          <span className="text-xs text-muted-foreground">{total.toLocaleString()} entries</span>
        </div>

        {logsLoading ? (
          <div className="space-y-2">{Array.from({ length: 5 }).map((_, i) => <Skeleton key={i} className="h-14 rounded-xl" />)}</div>
        ) : logs.length === 0 ? (
          <p className="text-sm text-muted-foreground py-8 text-center">No audit entries match your filters.</p>
        ) : (
          <div className="space-y-1.5">
            {logs.map((l) => (
              <button
                key={l.id}
                onClick={() => setSelected(l)}
                className="w-full flex items-start gap-3 bg-white/40 rounded-xl px-3 py-2.5 border border-border/40 hover:bg-white/70 text-left transition-colors"
              >
                <span className={cn('text-[10px] font-semibold px-2 py-0.5 rounded-full shrink-0', PROMPT_TYPE_PILL[l.prompt_type] ?? 'bg-muted text-muted-foreground')}>
                  {l.prompt_type}
                </span>
                <div className="flex-1 min-w-0">
                  <p className="text-sm text-foreground truncate">{l.prompt_text || '—'}</p>
                  <p className="text-[10px] text-muted-foreground">
                    {new Date(l.created_at).toLocaleString('en-GB', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })}
                    {' · '}
                    member <span className="font-mono">…{l.member_id.slice(-6)}</span>
                  </p>
                </div>
                <div className="text-right text-xs shrink-0">
                  <p className="numeric font-medium">{l.total_tokens.toLocaleString()} tok</p>
                  <p className="numeric text-muted-foreground">${Number(l.estimated_cost).toFixed(4)}</p>
                </div>
              </button>
            ))}
          </div>
        )}

        {pages > 1 && (
          <div className="flex items-center justify-between mt-4">
            <p className="text-xs text-muted-foreground">Page {page} of {pages}</p>
            <div className="flex gap-2">
              <Button size="sm" variant="outline" disabled={page <= 1}     onClick={() => setPage((p) => p - 1)}><ArrowLeft size={14} /></Button>
              <Button size="sm" variant="outline" disabled={page >= pages} onClick={() => setPage((p) => p + 1)}><ArrowRight size={14} /></Button>
            </div>
          </div>
        )}
      </GlassCard>

      {/* Inspector */}
      {selected && <AuditInspector log={selected} onClose={() => setSelected(null)} />}
    </div>
  )
}

// ── Inspector ────────────────────────────────────────────────────────────────

function AuditInspector({ log, onClose }: { log: AIAuditLog; onClose: () => void }) {
  return (
    <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-sm flex items-end sm:items-center justify-center p-4" onClick={onClose}>
      <div
        onClick={(e) => e.stopPropagation()}
        className="bg-card border border-border/60 rounded-2xl shadow-xl w-full max-w-2xl max-h-[85vh] overflow-y-auto"
      >
        <div className="sticky top-0 bg-card/95 backdrop-blur border-b border-border/40 px-5 py-3 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className={cn('text-[10px] font-semibold px-2 py-0.5 rounded-full', PROMPT_TYPE_PILL[log.prompt_type] ?? 'bg-muted text-muted-foreground')}>
              {log.prompt_type}
            </span>
            <h3 className="font-semibold text-sm">Audit entry #{log.id}</h3>
          </div>
          <button onClick={onClose} className="p-1.5 rounded-lg hover:bg-muted"><X size={14} /></button>
        </div>

        <div className="p-5 space-y-4 text-sm">
          <div className="grid grid-cols-2 gap-3">
            <Cell label="Member ID"  value={log.member_id} mono />
            <Cell label="Admin ID"   value={log.admin_id} mono />
            <Cell label="Created"    value={new Date(log.created_at).toLocaleString()} />
            <Cell label="Tokens"     value={`${log.prompt_tokens} prompt · ${log.completion_tokens} completion · ${log.total_tokens} total`} />
            <Cell label="Est. Cost"  value={`$${Number(log.estimated_cost).toFixed(6)}`} mono />
          </div>

          <div>
            <p className="text-[10px] uppercase tracking-wide text-muted-foreground mb-1">Prompt</p>
            <pre className="text-xs bg-muted/60 rounded-xl px-3 py-2.5 overflow-x-auto whitespace-pre-wrap font-mono">{log.prompt_text || '—'}</pre>
          </div>

          <div>
            <p className="text-[10px] uppercase tracking-wide text-muted-foreground mb-1">Response (JSON)</p>
            <pre className="text-[11px] bg-muted/60 rounded-xl px-3 py-2.5 overflow-x-auto whitespace-pre-wrap font-mono max-h-72">
              {(() => {
                const j = log.ai_response_json
                if (j == null) return '—'
                try {
                  return JSON.stringify(typeof j === 'string' ? JSON.parse(j) : j, null, 2)
                } catch {
                  return String(j)
                }
              })()}
            </pre>
          </div>
        </div>
      </div>
    </div>
  )
}

function Cell({ label, value, mono }: { label: string; value: string; mono?: boolean }) {
  return (
    <div>
      <p className="text-[10px] uppercase tracking-wide text-muted-foreground">{label}</p>
      <p className={cn('text-xs', mono ? 'font-mono break-all' : '')}>{value}</p>
    </div>
  )
}
