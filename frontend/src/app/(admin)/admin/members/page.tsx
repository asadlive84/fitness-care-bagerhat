'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'
import { useAdminMembers } from '@/hooks/use-admin'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import { GlassCard } from '@/components/glass-card'
import { MagnifyingGlass, UserPlus, ArrowLeft, ArrowRight, CaretRight } from '@phosphor-icons/react'
import { useDebounce } from '@/hooks/use-debounce'
import { cn } from '@/lib/utils'

export default function AdminMembers() {
  const [search, setSearch] = useState('')
  const [status, setStatus] = useState('all')
  const [page, setPage]     = useState(1)
  const debouncedSearch     = useDebounce(search, 300)

  const { data, isLoading } = useAdminMembers({ page, search: debouncedSearch, status })
  const members = data?.data ?? []
  const total   = data?.meta?.total ?? members.length
  const pages   = Math.ceil(total / 20)

  useEffect(() => { setPage(1) }, [debouncedSearch, status])

  return (
    <div className="p-4 md:p-8 max-w-5xl mx-auto">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-end sm:justify-between gap-3 mb-6">
        <div>
          <h1 className="text-2xl md:text-3xl font-bold tracking-tight">Members</h1>
          <p className="text-sm text-muted-foreground mt-1">{total} {total === 1 ? 'member' : 'members'} on your roster.</p>
        </div>
        <Link href="/admin/members/create">
          <Button className="gap-1.5 bg-primary text-white hover:bg-primary/90">
            <UserPlus size={14} weight="bold" /> Add Member
          </Button>
        </Link>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-2 mb-5">
        <div className="relative flex-1">
          <MagnifyingGlass size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" />
          <Input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search name or phone…"
            className="pl-9 h-10 bg-white/60"
          />
        </div>
        <select
          value={status}
          onChange={(e) => setStatus(e.target.value)}
          className="h-10 px-3 rounded-md border border-input bg-white/60 text-sm"
        >
          <option value="all">All</option>
          <option value="active">Active</option>
          <option value="inactive">Inactive</option>
        </select>
      </div>

      {/* List */}
      {isLoading ? (
        <div className="space-y-2">{Array.from({ length: 6 }).map((_, i) => <Skeleton key={i} className="h-16 rounded-2xl" />)}</div>
      ) : members.length === 0 ? (
        <GlassCard className="py-16 text-center">
          <p className="text-sm text-muted-foreground">No members found.</p>
        </GlassCard>
      ) : (
        <>
          <div className="space-y-2">
            {members.map((m) => (
              <Link
                key={m.id}
                href={`/admin/members/${m.id}`}
                className="block"
              >
                <GlassCard hoverable className="flex items-center gap-3 px-4 py-3">
                  <div className="w-10 h-10 rounded-full bg-primary/12 flex items-center justify-center shrink-0">
                    {m.profile_picture
                      ? <img src={m.profile_picture} alt="" className="w-full h-full rounded-full object-cover" />
                      : <span className="text-sm font-bold text-primary">{m.name.charAt(0).toUpperCase()}</span>
                    }
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-sm truncate">{m.name}</p>
                    <p className="text-xs text-muted-foreground">{m.phone}</p>
                  </div>
                  <div className="flex items-center gap-2 shrink-0">
                    {m.active_subscription && (
                      <span className="hidden sm:block text-xs text-muted-foreground truncate max-w-[120px]">{m.active_subscription.plan_name}</span>
                    )}
                    <span className={cn(
                      'text-[10px] font-semibold px-2 py-0.5 rounded-full',
                      m.status === 'active'
                        ? 'bg-emerald-100/70 text-emerald-700'
                        : 'bg-gray-100/80 text-gray-500',
                    )}>
                      {m.status}
                    </span>
                    <CaretRight size={14} className="text-muted-foreground" />
                  </div>
                </GlassCard>
              </Link>
            ))}
          </div>

          {pages > 1 && (
            <div className="flex items-center justify-between mt-5">
              <p className="text-xs text-muted-foreground">Page {page} of {pages} · {total} total</p>
              <div className="flex gap-2">
                <Button size="sm" variant="outline" disabled={page <= 1} onClick={() => setPage(p => p - 1)}><ArrowLeft size={14} /></Button>
                <Button size="sm" variant="outline" disabled={page >= pages} onClick={() => setPage(p => p + 1)}><ArrowRight size={14} /></Button>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  )
}
