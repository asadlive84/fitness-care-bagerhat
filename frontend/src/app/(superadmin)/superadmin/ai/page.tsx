'use client'

import { useState } from 'react'
import { useSAMembers, useSAToggleAI } from '@/hooks/use-superadmin'
import { Skeleton } from '@/components/ui/skeleton'
import { Brain, ToggleLeft, ToggleRight, MagnifyingGlass } from '@phosphor-icons/react'
import { useDebounce } from '@/hooks/use-debounce'
import type { AdminMember } from '@/types/admin'

export default function SuperAdminAI() {
  const [search, setSearch] = useState('')
  const debouncedSearch     = useDebounce(search, 300)
  const { data, isLoading } = useSAMembers({ search: debouncedSearch, status: 'all' })
  const toggleAI            = useSAToggleAI()

  const members = data?.data ?? []
  const aiEnabled  = members.filter((m) => m.is_ai_allowed).length
  const foodEnabled = members.filter((m) => m.is_ai_food_log_allowed).length

  return (
    <div className="p-4 md:p-6 max-w-3xl mx-auto space-y-5">
      <div className="flex items-center gap-2">
        <Brain size={22} className="text-purple-600" />
        <h1 className="text-xl font-bold">AI Usage Control</h1>
      </div>

      {/* Summary */}
      <div className="grid grid-cols-3 gap-3">
        {[
          { label: 'Total Members',  value: data?.meta?.total ?? members.length },
          { label: 'AI Diet Enabled', value: aiEnabled },
          { label: 'Food Log AI',    value: foodEnabled },
        ].map(({ label, value }) => (
          <div key={label} className="bg-card border border-border rounded-2xl p-4 text-center">
            <p className="text-2xl font-bold text-purple-600">{value}</p>
            <p className="text-xs text-muted-foreground mt-0.5">{label}</p>
          </div>
        ))}
      </div>

      {/* Note: token-level breakdown needs a dedicated backend endpoint */}
      <div className="bg-amber-50 border border-amber-200 rounded-xl px-4 py-3 text-sm text-amber-700">
        <strong>Note:</strong> Per-member token counts require a <code className="text-xs bg-amber-100 px-1 rounded">/api/v1/superadmin/ai/usage</code> endpoint (planned for backend).
        Current view shows AI enable/disable per member.
      </div>

      {/* Search */}
      <div className="relative">
        <MagnifyingGlass size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" />
        <input value={search} onChange={(e) => setSearch(e.target.value)}
          placeholder="Filter by name or phone…"
          className="w-full pl-9 h-9 rounded-md border border-input bg-background text-sm px-3 focus:outline-none focus:ring-1 focus:ring-ring" />
      </div>

      {/* Per-member AI toggles */}
      {isLoading
        ? <div className="space-y-2">{Array.from({ length: 6 }).map((_, i) => <Skeleton key={i} className="h-16 rounded-xl" />)}</div>
        : members.length === 0
          ? <p className="text-sm text-muted-foreground py-8 text-center">No members found.</p>
          : <div className="space-y-2">
              {members.map((m) => <MemberAIRow key={m.id} member={m} onToggle={(id, val) => toggleAI.mutate({ id, is_ai_allowed: val })} />)}
            </div>
      }
    </div>
  )
}

function MemberAIRow({ member, onToggle }: { member: AdminMember; onToggle: (id: string, val: boolean) => void }) {
  return (
    <div className="flex items-center gap-3 bg-card border border-border rounded-xl px-4 py-3">
      <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
        <span className="text-sm font-bold text-primary">{member.name.charAt(0)}</span>
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium truncate">{member.name}</p>
        <p className="text-xs text-muted-foreground">{member.phone} · {member.budget_level ?? 'no budget set'}</p>
      </div>
      <div className="flex items-center gap-3 shrink-0">
        <div className="text-center hidden sm:block">
          <p className="text-[10px] text-muted-foreground">Diet AI</p>
          <button onClick={() => onToggle(member.id, !member.is_ai_allowed)} className="mt-0.5">
            {member.is_ai_allowed
              ? <ToggleRight size={24} weight="fill" className="text-primary" />
              : <ToggleLeft  size={24} className="text-muted-foreground" />
            }
          </button>
        </div>
        <div className="text-center hidden sm:block">
          <p className="text-[10px] text-muted-foreground">Food Log</p>
          <div className="mt-0.5">
            {member.is_ai_food_log_allowed
              ? <ToggleRight size={24} weight="fill" className="text-purple-500" />
              : <ToggleLeft  size={24} className="text-muted-foreground" />
            }
          </div>
        </div>
        {/* Mobile compact */}
        <button onClick={() => onToggle(member.id, !member.is_ai_allowed)} className="sm:hidden">
          {member.is_ai_allowed
            ? <ToggleRight size={24} weight="fill" className="text-primary" />
            : <ToggleLeft  size={24} className="text-muted-foreground" />
          }
        </button>
      </div>
    </div>
  )
}
