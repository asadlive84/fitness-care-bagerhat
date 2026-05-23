'use client'

import { useState, Suspense } from 'react'
import { useSearchParams } from 'next/navigation'
import { useSAMembers, useSAMember, useSAMemberMessages, useSAMemberSubscriptions, useSAMemberPayments, useSADisableMember, useSADeleteMember, useSAResetPassword } from '@/hooks/use-superadmin'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import { Sheet, SheetContent } from '@/components/ui/sheet'
import { DietChartView } from '@/components/admin/diet-chart-view'
import { WeightChart } from '@/components/member/weight-chart'
import { MagnifyingGlass, ArrowLeft, ArrowRight, X, Key, Trash, ShieldSlash, ShieldCheck } from '@phosphor-icons/react'
import { useDebounce } from '@/hooks/use-debounce'
import type { AdminMember } from '@/types/admin'
import type { WeightLog } from '@/types/member'

export default function SAMembersPage() {
  return <Suspense><SAMembers /></Suspense>
}

type InspectorTab = 'identity' | 'messages' | 'diet' | 'subscription' | 'payments' | 'images'

function SAMembers() {
  const searchParams = useSearchParams()
  const [search, setSearch] = useState('')
  const [status, setStatus] = useState('all')
  const [page, setPage]     = useState(1)
  const [selectedId, setSelectedId] = useState<string | null>(searchParams.get('id'))

  const debouncedSearch = useDebounce(search, 300)
  const { data, isLoading } = useSAMembers({ page, search: debouncedSearch, status })
  const members = data?.data ?? []
  const total   = data?.meta?.total ?? members.length
  const pages   = Math.ceil(total / 20)

  return (
    <div className="p-4 md:p-6 max-w-5xl mx-auto">
      <div className="flex items-center justify-between mb-5">
        <div>
          <h1 className="text-xl font-bold">Member Inspector</h1>
          <p className="text-xs text-muted-foreground mt-0.5">Full access — all member data</p>
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-2 mb-4">
        <div className="relative flex-1">
          <MagnifyingGlass size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" />
          <Input value={search} onChange={(e) => { setSearch(e.target.value); setPage(1) }}
            placeholder="Search name or phone…" className="pl-9 h-9" />
        </div>
        <select value={status} onChange={(e) => { setStatus(e.target.value); setPage(1) }}
          className="h-9 px-3 rounded-md border border-input bg-background text-sm">
          <option value="all">All</option>
          <option value="active">Active</option>
          <option value="inactive">Inactive</option>
        </select>
      </div>

      {/* Member list */}
      {isLoading
        ? <div className="space-y-2">{Array.from({ length: 8 }).map((_, i) => <Skeleton key={i} className="h-16 rounded-xl" />)}</div>
        : members.length === 0
          ? <p className="text-center py-16 text-sm text-muted-foreground">No members found.</p>
          : <>
              <div className="space-y-2">
                {members.map((m) => (
                  <button key={m.id} onClick={() => setSelectedId(m.id)}
                    className="w-full flex items-center gap-3 bg-card border border-border rounded-xl px-4 py-3 hover:bg-muted transition-colors text-left">
                    {/* Avatar */}
                    <div className="w-9 h-9 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
                      {m.profile_picture
                        ? <img src={m.profile_picture} alt="" className="w-full h-full rounded-full object-cover" />
                        : <span className="text-sm font-bold text-primary">{m.name.charAt(0)}</span>
                      }
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="font-medium text-sm truncate">{m.name}</p>
                      <p className="text-xs text-muted-foreground">{m.phone}</p>
                    </div>
                    <div className="flex items-center gap-1.5 shrink-0">
                      {m.is_ai_allowed && <span className="text-[9px] bg-purple-100 text-purple-700 px-1.5 py-0.5 rounded-full font-semibold">AI</span>}
                      <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full ${m.status === 'active' ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>{m.status}</span>
                    </div>
                  </button>
                ))}
              </div>
              {pages > 1 && (
                <div className="flex items-center justify-between mt-4">
                  <p className="text-xs text-muted-foreground">{page} / {pages} · {total} total</p>
                  <div className="flex gap-2">
                    <Button size="sm" variant="outline" disabled={page <= 1} onClick={() => setPage(p => p - 1)}><ArrowLeft size={14} /></Button>
                    <Button size="sm" variant="outline" disabled={page >= pages} onClick={() => setPage(p => p + 1)}><ArrowRight size={14} /></Button>
                  </div>
                </div>
              )}
            </>
      }

      {/* Inspector sheet */}
      <MemberInspector memberId={selectedId} onClose={() => setSelectedId(null)} />
    </div>
  )
}

// ── Inspector sheet ───────────────────────────────────────────────────────────

function MemberInspector({ memberId, onClose }: { memberId: string | null; onClose: () => void }) {
  const [tab, setTab] = useState<InspectorTab>('identity')
  const { data: member, isLoading } = useSAMember(memberId ?? '')
  const disable  = useSADisableMember()
  const del      = useSADeleteMember()
  const resetPw  = useSAResetPassword()
  const [tempPw, setTempPw] = useState<string | null>(null)

  const TABS: { id: InspectorTab; label: string }[] = [
    { id: 'identity',     label: 'Identity' },
    { id: 'messages',     label: 'Messages' },
    { id: 'diet',         label: 'Diet Plan' },
    { id: 'subscription', label: 'Subscription' },
    { id: 'payments',     label: 'Payments' },
    { id: 'images',       label: 'Images' },
  ]

  async function handleDelete() {
    if (!memberId || !confirm(`Permanently delete ${member?.name}?`)) return
    await del.mutateAsync(memberId); onClose()
  }

  async function handleReset() {
    if (!memberId) return
    const pw = await resetPw.mutateAsync(memberId); setTempPw(pw)
  }

  return (
    <Sheet open={!!memberId} onOpenChange={(o) => !o && onClose()}>
      <SheetContent className="w-full sm:max-w-2xl overflow-y-auto p-0">
        {isLoading || !member ? (
          <div className="p-5 space-y-3">{Array.from({ length: 6 }).map((_, i) => <Skeleton key={i} className="h-10 rounded-xl" />)}</div>
        ) : (
          <div className="flex flex-col h-full">
            {/* Header */}
            <div className="sticky top-0 bg-card border-b border-border z-10">
              <div className="flex items-center gap-3 px-4 py-3">
                <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
                  {member.profile_picture
                    ? <img src={member.profile_picture} alt="" className="w-full h-full rounded-full object-cover" />
                    : <span className="font-bold text-primary">{member.name.charAt(0)}</span>
                  }
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-bold truncate">{member.name}</p>
                  <p className="text-xs text-muted-foreground">{member.phone}</p>
                </div>
                {/* Quick actions */}
                <div className="flex items-center gap-1">
                  <button onClick={() => disable.mutate({ id: member.id, status: member.status === 'active' ? 'inactive' : 'active' })}
                    title={member.status === 'active' ? 'Disable' : 'Enable'}
                    className="p-1.5 rounded-lg hover:bg-muted transition-colors">
                    {member.status === 'active'
                      ? <ShieldSlash size={16} className="text-amber-500" />
                      : <ShieldCheck size={16} className="text-green-500" />
                    }
                  </button>
                  <button onClick={handleReset} title="Reset password" className="p-1.5 rounded-lg hover:bg-muted transition-colors">
                    <Key size={16} className="text-muted-foreground" />
                  </button>
                  <button onClick={handleDelete} title="Delete" className="p-1.5 rounded-lg hover:bg-muted transition-colors">
                    <Trash size={16} className="text-destructive" />
                  </button>
                  <button onClick={onClose} className="p-1.5 rounded-lg hover:bg-muted transition-colors ml-1">
                    <X size={16} />
                  </button>
                </div>
              </div>

              {/* Temp password banner */}
              {tempPw && (
                <div className="mx-4 mb-3 bg-amber-50 border border-amber-200 rounded-xl px-3 py-2 flex justify-between items-center">
                  <div>
                    <p className="text-xs text-amber-600 font-medium">Temporary Password</p>
                    <p className="font-mono font-bold">{tempPw}</p>
                  </div>
                  <button onClick={() => setTempPw(null)}><X size={12} /></button>
                </div>
              )}

              {/* Status badges */}
              <div className="px-4 pb-3 flex gap-1.5 flex-wrap">
                <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full ${member.status === 'active' ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>{member.status}</span>
                {member.is_ai_allowed && <span className="text-[10px] font-semibold bg-purple-100 text-purple-700 px-2 py-0.5 rounded-full">AI enabled</span>}
                {member.bmi && <span className="text-[10px] bg-blue-100 text-blue-700 px-2 py-0.5 rounded-full font-semibold">BMI {member.bmi}</span>}
              </div>

              {/* Scrollable tab bar */}
              <div className="flex gap-0.5 overflow-x-auto px-4 pb-3 scrollbar-hide">
                {TABS.map((t) => (
                  <button key={t.id} onClick={() => setTab(t.id)}
                    className={`shrink-0 px-3 py-1 text-xs font-medium rounded-lg transition-colors ${
                      tab === t.id ? 'bg-primary text-white' : 'text-muted-foreground hover:bg-muted'
                    }`}>
                    {t.label}
                  </button>
                ))}
              </div>
            </div>

            {/* Tab content */}
            <div className="flex-1 overflow-y-auto p-4">
              {tab === 'identity'     && <IdentityTab     member={member} />}
              {tab === 'messages'     && <MessagesTab     memberId={member.id} />}
              {tab === 'diet'         && <DietTab         member={member} />}
              {tab === 'subscription' && <SubscriptionTab memberId={member.id} />}
              {tab === 'payments'     && <PaymentsTab     memberId={member.id} />}
              {tab === 'images'       && <ImagesTab       member={member} />}
            </div>
          </div>
        )}
      </SheetContent>
    </Sheet>
  )
}

// ── Tab: Identity ─────────────────────────────────────────────────────────────

function IdentityTab({ member }: { member: AdminMember }) {
  const fields: [string, unknown][] = [
    ['ID',               member.id],
    ['Phone',            member.phone],
    ['Gender',           member.gender],
    ['Date of Birth',    member.date_of_birth],
    ['Age',              member.age],
    ['Religion',         member.religion],
    ['Blood Group',      member.blood_group],
    ['Weight',           member.current_weight ? `${member.current_weight} kg` : null],
    ['Height',           member.height_cm ? `${member.height_cm} cm` : null],
    ['BMI',              member.bmi],
    ['Goal',             member.goal],
    ['Occupation',       member.occupation],
    ['NID',              member.nid],
    ['Budget Level',     member.budget_level],
    ['Emergency Phone',  member.emergency_phone],
    ['Present Address',  member.present_address],
    ['Permanent Address',member.permanent_address],
    ['Hobbies',          member.hobbies?.join(', ')],
    ['Join Date',        member.join_date],
    ['AI Allowed',       member.is_ai_allowed ? 'Yes' : 'No'],
    ['Food Log AI',      member.is_ai_food_log_allowed ? 'Yes' : 'No'],
  ]

  return (
    <div className="space-y-2.5">
      {fields.filter(([, v]) => v !== null && v !== undefined && v !== '').map(([label, value]) => (
        <div key={String(label)} className="flex justify-between gap-4 py-1.5 border-b border-border/50 last:border-0">
          <p className="text-xs text-muted-foreground shrink-0">{label}</p>
          <p className="text-sm text-right break-all">{String(value)}</p>
        </div>
      ))}
    </div>
  )
}

// ── Tab: Messages ─────────────────────────────────────────────────────────────

function MessagesTab({ memberId }: { memberId: string }) {
  const { data: messages = [], isLoading } = useSAMemberMessages(memberId)

  if (isLoading) return <div className="space-y-2">{Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="h-12 rounded-xl" />)}</div>
  if (messages.length === 0) return <p className="text-sm text-muted-foreground py-8 text-center">No messages yet.</p>

  return (
    <div className="space-y-2">
      {messages.map((msg) => {
        const isAdmin = msg.sender_role === 'admin'
        return (
          <div key={msg.id} className={`flex ${isAdmin ? 'justify-end' : 'justify-start'}`}>
            <div className={`max-w-[80%] px-3 py-2 rounded-2xl text-sm ${isAdmin ? 'bg-primary text-white rounded-br-sm' : 'bg-muted rounded-bl-sm'}`}>
              <p>{msg.content}</p>
              <p className={`text-[10px] mt-0.5 ${isAdmin ? 'text-white/60 text-right' : 'text-muted-foreground'}`}>
                {new Date(msg.sent_at).toLocaleString('en-GB', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })}
                {msg.is_broadcast && ' · broadcast'}
              </p>
            </div>
          </div>
        )
      })}
    </div>
  )
}

// ── Tab: Diet Plan ────────────────────────────────────────────────────────────

function DietTab({ member }: { member: AdminMember }) {
  const hasPending = member.pending_diet_chart && Object.keys(member.pending_diet_chart).length > 0
  const hasActive  = member.diet_chart && Object.keys(member.diet_chart).length > 0

  if (!hasActive && !hasPending) {
    return <p className="text-sm text-muted-foreground py-8 text-center">No diet chart found. Use the Admin AI page to generate one.</p>
  }

  return (
    <div className="space-y-4">
      {hasPending && <DietChartView chart={member.pending_diet_chart!} label="Pending Approval" variant="pending" />}
      {hasActive  && <DietChartView chart={member.diet_chart!} label="Active Plan" />}
    </div>
  )
}

// ── Tab: Subscription ─────────────────────────────────────────────────────────

function SubscriptionTab({ memberId }: { memberId: string }) {
  const { data: subs = [], isLoading } = useSAMemberSubscriptions(memberId)

  if (isLoading) return <Skeleton className="h-32 rounded-2xl" />
  if (subs.length === 0) return <p className="text-sm text-muted-foreground py-8 text-center">No subscriptions found.</p>

  return (
    <div className="space-y-3">
      {subs.map((s, i) => (
        <div key={s.id} className={`rounded-2xl border p-4 ${i === 0 ? 'border-green-200 bg-green-50/40' : 'border-border'}`}>
          <div className="flex justify-between items-start mb-2">
            <div>
              <p className="font-semibold text-sm">{s.plan_name}</p>
              <p className="text-xs text-muted-foreground">{s.start_date} → {s.end_date}</p>
            </div>
            <div className="text-right">
              <p className="font-bold text-primary text-sm">৳{s.final_price.toLocaleString()}</p>
              <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full ${s.billing_type === 'prepaid' ? 'bg-green-100 text-green-700' : 'bg-blue-100 text-blue-700'}`}>{s.billing_type}</span>
            </div>
          </div>
          <div className="flex justify-between text-xs text-muted-foreground">
            <span>Paid: ৳{s.money_paid.toLocaleString()}</span>
            <span className={s.money_left > 0 ? 'text-red-500 font-medium' : 'text-green-600'}>
              {s.money_left > 0 ? `Due: ৳${s.money_left.toLocaleString()}` : 'Fully paid'}
            </span>
          </div>
          {/* Mini progress bar */}
          <div className="h-1.5 rounded-full bg-border mt-2 overflow-hidden">
            <div className="h-full rounded-full bg-primary" style={{ width: `${Math.min((s.money_paid / s.final_price) * 100, 100)}%` }} />
          </div>
        </div>
      ))}
    </div>
  )
}

// ── Tab: Payments ─────────────────────────────────────────────────────────────

function PaymentsTab({ memberId }: { memberId: string }) {
  const { data: payments = [], isLoading } = useSAMemberPayments(memberId)

  if (isLoading) return <div className="space-y-2">{Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="h-12 rounded-xl" />)}</div>
  if (payments.length === 0) return <p className="text-sm text-muted-foreground py-8 text-center">No payment records.</p>

  const total = payments.reduce((sum, p) => sum + p.amount, 0)

  return (
    <div className="space-y-2">
      <div className="bg-green-50 border border-green-200 rounded-xl px-4 py-2.5 flex justify-between">
        <p className="text-sm font-semibold text-green-700">Total Paid</p>
        <p className="text-sm font-bold text-green-700">৳{total.toLocaleString()}</p>
      </div>
      {payments.map((p) => (
        <div key={p.id} className="flex justify-between items-center bg-card border border-border rounded-xl px-4 py-3">
          <div>
            <p className="text-sm font-semibold">৳{p.amount.toLocaleString()}</p>
            <p className="text-xs text-muted-foreground">{new Date(p.paid_at).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })}</p>
          </div>
          <span className="text-xs bg-muted px-2 py-0.5 rounded-full capitalize">{p.method}</span>
        </div>
      ))}
    </div>
  )
}

// ── Tab: Images ───────────────────────────────────────────────────────────────

function ImagesTab({ member }: { member: AdminMember }) {
  const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:9000'
  const profilePic = member.profile_picture

  return (
    <div className="space-y-4">
      <div>
        <p className="text-xs font-semibold text-muted-foreground mb-2">Profile Picture</p>
        {profilePic ? (
          <img
            src={profilePic.startsWith('http') ? profilePic : `${API_BASE}${profilePic}`}
            alt={member.name}
            className="w-24 h-24 rounded-2xl object-cover border border-border"
          />
        ) : (
          <div className="w-24 h-24 rounded-2xl bg-muted flex items-center justify-center border border-border">
            <span className="text-3xl font-bold text-primary">{member.name.charAt(0)}</span>
          </div>
        )}
      </div>
      <p className="text-xs text-muted-foreground">Food log images are stored per AI analysis. Viewing requires a dedicated superadmin API endpoint (planned).</p>
    </div>
  )
}
