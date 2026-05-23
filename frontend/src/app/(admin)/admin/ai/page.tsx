'use client'

import { useState } from 'react'
import { useAdminMember, useAdminMembers } from '@/hooks/use-admin'
import { useGenerateDietChart, useApproveDietChart, useDeclineDietChart, useUpdateMemberAI } from '@/hooks/use-ai'
import { DietChartView } from '@/components/admin/diet-chart-view'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Skeleton } from '@/components/ui/skeleton'
import { Brain, Sparkle, Check, X, ToggleLeft, ToggleRight, MagnifyingGlass } from '@phosphor-icons/react'
import { useDebounce } from '@/hooks/use-debounce'
import type { AdminMember } from '@/types/admin'

type Tab = 'diet' | 'settings'

export default function AdminAI() {
  const [tab, setTab]               = useState<Tab>('diet')
  const [memberId, setMemberId]     = useState<string | null>(null)
  const [search, setSearch]         = useState('')
  const [showResults, setShowResults] = useState(false)
  const debouncedSearch             = useDebounce(search, 300)

  const { data: results } = useAdminMembers({ search: debouncedSearch, status: 'active' })
  const members            = debouncedSearch.length >= 2 ? (results?.data ?? []) : []

  function selectMember(m: AdminMember) {
    setMemberId(m.id)
    setSearch(m.name)
    setShowResults(false)
  }

  return (
    <div className="p-4 md:p-6 max-w-2xl mx-auto space-y-5">
      <div className="flex items-center gap-2">
        <Brain size={22} className="text-primary" />
        <h1 className="text-xl font-bold">AI Tools</h1>
      </div>

      {/* Tab bar */}
      <div className="flex gap-1 bg-muted rounded-xl p-1">
        {(['diet', 'settings'] as Tab[]).map((t) => (
          <button key={t} onClick={() => setTab(t)}
            className={`flex-1 py-1.5 text-sm font-medium rounded-lg transition-all capitalize ${
              tab === t ? 'bg-card shadow-sm text-foreground' : 'text-muted-foreground'
            }`}>
            {t === 'diet' ? 'Diet Chart Builder' : 'AI Settings'}
          </button>
        ))}
      </div>

      {/* Member search */}
      <div className="relative">
        <div className="relative">
          <MagnifyingGlass size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" />
          <Input
            value={search}
            onChange={(e) => { setSearch(e.target.value); setShowResults(true); if (!e.target.value) setMemberId(null) }}
            onFocus={() => setShowResults(true)}
            placeholder="Search member by name or phone…"
            className="pl-9 h-10"
          />
        </div>
        {showResults && members.length > 0 && (
          <div className="absolute z-10 mt-1 w-full bg-card border border-border rounded-xl shadow-lg max-h-48 overflow-y-auto">
            {members.map((m) => (
              <button key={m.id} onClick={() => selectMember(m)}
                className="w-full flex justify-between items-center px-4 py-2.5 hover:bg-muted text-sm transition-colors">
                <div className="text-left">
                  <p className="font-medium">{m.name}</p>
                  <p className="text-xs text-muted-foreground">{m.phone}</p>
                </div>
                <div className="flex gap-1">
                  {m.is_ai_allowed && <span className="text-[10px] bg-green-100 text-green-700 px-1.5 py-0.5 rounded-full">AI on</span>}
                </div>
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Tab content */}
      {memberId && (
        tab === 'diet'
          ? <DietTab memberId={memberId} />
          : <SettingsTab memberId={memberId} />
      )}

      {!memberId && (
        <div className="text-center py-12 text-muted-foreground">
          <Sparkle size={36} className="mx-auto mb-3 opacity-30" />
          <p className="text-sm">Search for a member to get started.</p>
        </div>
      )}
    </div>
  )
}

// ── Diet Chart Tab ────────────────────────────────────────────────────────────

function DietTab({ memberId }: { memberId: string }) {
  const { data: member, isLoading } = useAdminMember(memberId)
  const generate = useGenerateDietChart(memberId)
  const approve  = useApproveDietChart(memberId)
  const decline  = useDeclineDietChart(memberId)

  if (isLoading) return <Skeleton className="h-64 rounded-2xl" />
  if (!member)   return null

  const hasPending = member.pending_diet_chart && Object.keys(member.pending_diet_chart).length > 0
  const hasActive  = member.diet_chart && Object.keys(member.diet_chart).length > 0

  return (
    <div className="space-y-4">
      {/* Member AI status banner */}
      {!member.is_ai_allowed && (
        <div className="flex items-center gap-2 bg-amber-50 border border-amber-200 rounded-xl px-3 py-2.5 text-sm text-amber-700">
          <Brain size={14} className="shrink-0" />
          AI is <strong>disabled</strong> for this member. Enable it in AI Settings tab first.
        </div>
      )}

      {/* Generate button */}
      <Button
        onClick={() => generate.mutate()}
        disabled={generate.isPending || !member.is_ai_allowed}
        className="w-full gap-2 bg-primary text-white hover:bg-primary/90"
      >
        <Sparkle size={16} weight={generate.isPending ? 'regular' : 'fill'} />
        {generate.isPending ? 'Generating…' : hasPending ? 'Regenerate Diet Chart' : 'Generate Diet Chart'}
      </Button>

      {/* Pending chart — awaiting approval */}
      {hasPending && (
        <div className="space-y-3">
          <DietChartView
            chart={member.pending_diet_chart!}
            label="Pending — awaiting approval"
            variant="pending"
          />
          <div className="flex gap-2">
            <Button onClick={() => approve.mutate()} disabled={approve.isPending}
              className="flex-1 gap-1.5 bg-green-600 text-white hover:bg-green-700">
              <Check size={14} /> {approve.isPending ? 'Approving…' : 'Approve & Activate'}
            </Button>
            <Button onClick={() => decline.mutate()} disabled={decline.isPending}
              variant="outline" className="flex-1 gap-1.5 text-red-600 hover:bg-red-50 border-red-200">
              <X size={14} /> {decline.isPending ? 'Declining…' : 'Decline'}
            </Button>
          </div>
        </div>
      )}

      {/* Active chart */}
      {hasActive && (
        <div className="space-y-2">
          <p className="text-sm font-semibold text-muted-foreground">Active Diet Plan</p>
          <DietChartView chart={member.diet_chart!} label="Active" />
        </div>
      )}

      {!hasActive && !hasPending && (
        <p className="text-center text-sm text-muted-foreground py-6">
          No diet chart generated yet. Click the button above to create one.
        </p>
      )}
    </div>
  )
}

// ── AI Settings Tab ───────────────────────────────────────────────────────────

function SettingsTab({ memberId }: { memberId: string }) {
  const { data: member, isLoading } = useAdminMember(memberId)
  const updateAI = useUpdateMemberAI(memberId)
  const [budget, setBudget] = useState<string>('')

  if (isLoading) return <Skeleton className="h-48 rounded-2xl" />
  if (!member)   return null

  const currentBudget = budget || member.budget_level || 'Medium'

  async function toggle(field: 'ai' | 'food_log') {
    if (field === 'ai') {
      await updateAI.mutateAsync({
        is_ai_allowed: !member!.is_ai_allowed,
        is_ai_food_log_allowed: member!.is_ai_food_log_allowed,
        budget_level: currentBudget,
      })
    } else {
      await updateAI.mutateAsync({
        is_ai_allowed: member!.is_ai_allowed!,
        is_ai_food_log_allowed: !member!.is_ai_food_log_allowed,
        budget_level: currentBudget,
      })
    }
  }

  async function saveBudget() {
    await updateAI.mutateAsync({
      is_ai_allowed: member!.is_ai_allowed!,
      is_ai_food_log_allowed: member!.is_ai_food_log_allowed,
      budget_level: currentBudget,
    })
  }

  const Row = ({ label, desc, active, onToggle }: { label: string; desc: string; active: boolean; onToggle: () => void }) => (
    <div className="flex items-center justify-between gap-4 bg-card border border-border rounded-xl px-4 py-3">
      <div>
        <p className="text-sm font-medium">{label}</p>
        <p className="text-xs text-muted-foreground">{desc}</p>
      </div>
      <button onClick={onToggle} disabled={updateAI.isPending} className="shrink-0 transition-colors">
        {active
          ? <ToggleRight size={28} weight="fill" className="text-primary" />
          : <ToggleLeft size={28} className="text-muted-foreground" />
        }
      </button>
    </div>
  )

  return (
    <div className="space-y-3">
      <Row
        label="AI Diet Chart"
        desc="Allow admin to generate AI diet charts for this member"
        active={!!member.is_ai_allowed}
        onToggle={() => toggle('ai')}
      />
      <Row
        label="AI Food Log"
        desc="Allow member to analyze food photos with AI"
        active={!!member.is_ai_food_log_allowed}
        onToggle={() => toggle('food_log')}
      />

      {/* Budget level */}
      <div className="bg-card border border-border rounded-xl p-4 space-y-2">
        <p className="text-sm font-medium">Budget Level</p>
        <p className="text-xs text-muted-foreground">Used to personalize AI diet chart recommendations</p>
        <div className="flex gap-2 mt-2">
          {['Low', 'Medium', 'High'].map((lvl) => (
            <button key={lvl} onClick={() => setBudget(lvl)}
              className={`flex-1 py-1.5 text-sm font-medium rounded-lg border transition-all ${
                currentBudget === lvl
                  ? 'bg-primary text-white border-primary'
                  : 'bg-background border-border text-muted-foreground hover:border-primary/40'
              }`}>
              {lvl}
            </button>
          ))}
        </div>
        <Button onClick={saveBudget} disabled={updateAI.isPending} size="sm"
          className="w-full mt-1 bg-primary text-white hover:bg-primary/90">
          {updateAI.isPending ? 'Saving…' : 'Save Budget Level'}
        </Button>
      </div>
    </div>
  )
}
