'use client'

import { use, useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import {
  useAdminMember, useUpdateMemberStatus, useDeleteMember, useResetPassword,
  useMemberSubscriptions, useMemberPaymentsAdmin,
  useApproveMember, useRejectMember,
  useGenerateDietChart, useApproveDietChart, useDeclineDietChart,
} from '@/hooks/use-admin'
import { GlassCard } from '@/components/glass-card'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import {
  ArrowLeft, Phone, Key, Trash, Check, X, Copy, ShieldCheck, ShieldSlash, Brain,
  Heart, Calendar, Ruler, GenderIntersex, Briefcase, MapPin, ChatTeardropDots,
  CheckCircle, XCircle, ForkKnife, Spinner,
} from '@phosphor-icons/react'
import { motion } from 'framer-motion'
import { cn } from '@/lib/utils'

interface PageProps { params: Promise<{ id: string }> }

export default function MemberDetailPage({ params }: PageProps) {
  const { id } = use(params)
  const router = useRouter()

  const { data: member, isLoading } = useAdminMember(id)
  const { data: subs = [] }         = useMemberSubscriptions(id)
  const { data: payments = [] }     = useMemberPaymentsAdmin(id)

  const updateStatus  = useUpdateMemberStatus(id)
  const deleteMember  = useDeleteMember()
  const resetPw       = useResetPassword()
  const approveMember = useApproveMember()
  const rejectMember  = useRejectMember()
  const genDiet       = useGenerateDietChart(id)
  const approveDiet   = useApproveDietChart(id)
  const declineDiet   = useDeclineDietChart(id)

  const [tempPw, setTempPw]         = useState<string | null>(null)
  const [copied, setCopied]         = useState(false)
  const [dietLang, setDietLang]     = useState<'bn' | 'en'>('bn')
  const [showApproveModal, setShowApproveModal] = useState(false)

  async function handleDelete() {
    if (!confirm(`Delete ${member?.name}? This cannot be undone.`)) return
    await deleteMember.mutateAsync(id)
    router.replace('/admin/members')
  }

  async function handleReset() {
    const pw = await resetPw.mutateAsync(id)
    setTempPw(pw)
  }

  async function handleApprove() {
    const result = await approveMember.mutateAsync(id)
    setTempPw(result.temp_password)
    setShowApproveModal(true)
  }

  async function handleReject() {
    if (!confirm(`Reject ${member?.name}'s registration?`)) return
    await rejectMember.mutateAsync(id)
  }

  function copyTempPw() {
    if (!tempPw) return
    navigator.clipboard.writeText(tempPw)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  if (isLoading || !member) {
    return (
      <div className="p-4 md:p-8 max-w-4xl mx-auto space-y-4">
        <Skeleton className="h-32 rounded-2xl" />
        <Skeleton className="h-48 rounded-2xl" />
        <Skeleton className="h-32 rounded-2xl" />
      </div>
    )
  }

  const sub = member.active_subscription
  const subProgress = sub && sub.final_price > 0 ? Math.min(sub.money_paid / sub.final_price, 1) : 0

  return (
    <div className="p-4 md:p-8 max-w-4xl mx-auto space-y-5">
      {/* Back link */}
      <Link href="/admin/members" className="inline-flex items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground transition-colors">
        <ArrowLeft size={14} /> Back to members
      </Link>

      {/* Header card */}
      <GlassCard className="p-5 md:p-6">
        <div className="flex flex-col sm:flex-row gap-4 sm:items-center">
          {/* Avatar */}
          <div className="w-16 h-16 rounded-2xl bg-primary/12 flex items-center justify-center shrink-0">
            {member.profile_picture
              ? <img src={member.profile_picture} alt="" className="w-full h-full rounded-2xl object-cover" />
              : <span className="text-2xl font-bold text-primary">{member.name.charAt(0).toUpperCase()}</span>
            }
          </div>

          <div className="flex-1 min-w-0">
            <h1 className="text-xl md:text-2xl font-bold tracking-tight">{member.name}</h1>
            <p className="text-sm text-muted-foreground flex items-center gap-1.5 mt-0.5">
              <Phone size={12} /> {member.phone}
            </p>
            <div className="flex flex-wrap gap-1.5 mt-2.5">
              <span className={cn(
                'text-[10px] font-semibold px-2.5 py-1 rounded-full',
                member.status === 'active'   && 'bg-emerald-100/70 text-emerald-700',
                member.status === 'inactive' && 'bg-gray-100/80 text-gray-500',
                member.status === 'pending'  && 'bg-amber-100/80 text-amber-700',
                member.status === 'rejected' && 'bg-red-100/70 text-red-600',
              )}>{member.status}</span>
              {member.gender && <span className="text-[10px] font-semibold px-2.5 py-1 rounded-full bg-blue-100/60 text-blue-700">{member.gender}</span>}
              {member.blood_group && <span className="text-[10px] font-semibold px-2.5 py-1 rounded-full bg-red-100/60 text-red-700">{member.blood_group}</span>}
              {member.bmi && <span className="text-[10px] font-semibold px-2.5 py-1 rounded-full bg-purple-100/60 text-purple-700">BMI {member.bmi}</span>}
              {member.is_ai_allowed && <span className="text-[10px] font-semibold px-2.5 py-1 rounded-full bg-orange-100/70 text-accent">AI enabled</span>}
            </div>
          </div>

          {/* Actions */}
          <div className="flex sm:flex-col gap-2 shrink-0">
            <Button
              size="sm"
              variant="outline"
              className="gap-1.5"
              onClick={() => updateStatus.mutate(member.status === 'active' ? 'inactive' : 'active')}
              disabled={updateStatus.isPending}
            >
              {member.status === 'active'
                ? <><ShieldSlash size={14} /> Deactivate</>
                : <><ShieldCheck size={14} /> Activate</>}
            </Button>
          </div>
        </div>

        {/* Pending approval actions */}
        {member.status === 'pending' && (
          <div className="mt-4 rounded-xl border border-amber-200/70 bg-amber-50/70 px-4 py-4">
            <p className="text-xs font-semibold text-amber-800 mb-3">Registration pending — review and approve or reject.</p>
            <div className="flex gap-2">
              <Button
                size="sm"
                className="gap-1.5 bg-emerald-600 hover:bg-emerald-700 text-white"
                onClick={handleApprove}
                disabled={approveMember.isPending}
              >
                {approveMember.isPending
                  ? <Spinner size={14} className="animate-spin" />
                  : <CheckCircle size={14} weight="fill" />}
                Approve
              </Button>
              <Button
                size="sm"
                variant="outline"
                className="gap-1.5 border-red-300 text-red-600 hover:bg-red-50"
                onClick={handleReject}
                disabled={rejectMember.isPending}
              >
                <XCircle size={14} weight="fill" /> Reject
              </Button>
            </div>
          </div>
        )}

        {/* Temp password banner */}
        {tempPw && (
          <motion.div
            initial={{ opacity: 0, y: -4 }}
            animate={{ opacity: 1, y: 0 }}
            className="mt-4 rounded-xl border border-amber-200/70 bg-amber-50/70 px-4 py-3 flex items-center gap-3"
          >
            <Key size={14} className="text-amber-700 shrink-0" />
            <div className="flex-1">
              <p className="text-[10px] font-semibold text-amber-700 uppercase tracking-wide">Temporary Password</p>
              <p className="font-mono font-bold text-amber-900">{tempPw}</p>
            </div>
            <button onClick={copyTempPw} className="p-1.5 rounded-lg hover:bg-amber-100">
              {copied ? <Check size={14} weight="bold" className="text-emerald-700" /> : <Copy size={14} className="text-amber-700" />}
            </button>
            <button onClick={() => setTempPw(null)} className="p-1.5 rounded-lg hover:bg-amber-100">
              <X size={14} className="text-amber-700" />
            </button>
          </motion.div>
        )}
      </GlassCard>

      {/* Quick action row */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
        <ActionTile
          icon={<ChatTeardropDots size={16} />}
          label="Message"
          href={`/admin/messages?id=${id}`}
          tint="primary"
        />
        <ActionTile
          icon={<Brain size={16} />}
          label="AI Tools"
          href={`/admin/ai?member=${id}`}
          tint="accent"
        />
        <ActionTile
          icon={<Key size={16} />}
          label={resetPw.isPending ? 'Resetting…' : 'Reset Password'}
          onClick={handleReset}
          tint="info"
          disabled={resetPw.isPending}
        />
        <ActionTile
          icon={<Trash size={16} />}
          label={deleteMember.isPending ? 'Deleting…' : 'Delete Member'}
          onClick={handleDelete}
          tint="error"
          disabled={deleteMember.isPending}
        />
      </div>

      {/* Active subscription */}
      {sub && (
        <GlassCard className="p-5">
          <h3 className="font-semibold text-sm mb-3 flex items-center gap-2">
            <Heart size={14} weight="fill" className="text-primary" /> Active Subscription
          </h3>
          <div className="flex justify-between items-start mb-3">
            <div>
              <p className="font-semibold">{sub.plan_name}</p>
              <p className="text-xs text-muted-foreground">
                {fmtDate(sub.start_date)} → {fmtDate(sub.end_date)}
              </p>
            </div>
            <div className="text-right">
              <p className="font-bold numeric text-primary">৳{sub.final_price.toLocaleString()}</p>
              <span className={cn(
                'text-[10px] font-semibold px-2 py-0.5 rounded-full',
                sub.billing_type === 'prepaid' ? 'bg-emerald-100/70 text-emerald-700' : 'bg-blue-100/60 text-blue-700',
              )}>{sub.billing_type}</span>
            </div>
          </div>
          <div className="h-2 rounded-full bg-border/70 overflow-hidden">
            <div
              className={cn('h-full rounded-full transition-all', sub.money_left <= 0 ? 'bg-emerald-500' : 'bg-amber-400')}
              style={{ width: `${subProgress * 100}%` }}
            />
          </div>
          <div className="flex justify-between text-xs mt-2 font-medium">
            <span className="text-emerald-700 numeric">Paid ৳{sub.money_paid.toLocaleString()}</span>
            <span className={sub.money_left > 0 ? 'text-red-600 numeric' : 'text-muted-foreground numeric'}>
              {sub.money_left > 0 ? `Due ৳${sub.money_left.toLocaleString()}` : 'Fully paid'}
            </span>
          </div>
        </GlassCard>
      )}

      {/* Personal info */}
      <GlassCard className="p-5">
        <h3 className="font-semibold text-sm mb-4">Personal Details</h3>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <InfoRow icon={<Phone size={12} />}            label="Phone"            value={member.phone} />
          <InfoRow icon={<GenderIntersex size={12} />}   label="Gender"           value={member.gender} />
          <InfoRow icon={<Calendar size={12} />}         label="Join Date"        value={fmtDate(member.join_date)} />
          <InfoRow icon={<Calendar size={12} />}         label="Date of Birth"    value={fmtDate(member.date_of_birth)} />
          <InfoRow icon={<Heart size={12} />}            label="Goal"             value={member.goal} />
          <InfoRow icon={<Ruler size={12} />}            label="Weight / Height"  value={[member.current_weight && `${member.current_weight} kg`, member.height_cm && `${member.height_cm} cm`].filter(Boolean).join(' · ') || undefined} />
          <InfoRow icon={<Briefcase size={12} />}        label="Occupation"       value={member.occupation} />
          <InfoRow icon={<Phone size={12} />}            label="Emergency Phone"  value={member.emergency_phone} />
          <InfoRow icon={<MapPin size={12} />}           label="Present Address"  value={member.present_address} colSpan />
          <InfoRow icon={<MapPin size={12} />}           label="Permanent Address" value={member.permanent_address} colSpan />
        </div>
      </GlassCard>

      {/* Subscription history */}
      {subs.length > 0 && (
        <GlassCard className="p-5">
          <h3 className="font-semibold text-sm mb-3">Subscription History</h3>
          <div className="space-y-2">
            {subs.map((s) => (
              <div key={s.id} className="flex items-center gap-3 bg-white/40 rounded-xl px-4 py-3 border border-border/40">
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium truncate">{s.plan_name}</p>
                  <p className="text-xs text-muted-foreground">{fmtDate(s.start_date)} → {fmtDate(s.end_date)}</p>
                </div>
                <div className="text-right shrink-0">
                  <p className="text-sm font-semibold numeric">৳{s.final_price.toLocaleString()}</p>
                  {s.money_left > 0
                    ? <p className="text-[11px] text-red-600 numeric">Due ৳{s.money_left.toLocaleString()}</p>
                    : <p className="text-[11px] text-emerald-700">Settled</p>}
                </div>
              </div>
            ))}
          </div>
        </GlassCard>
      )}

      {/* Payment history */}
      {payments.length > 0 && (
        <GlassCard className="p-5">
          <h3 className="font-semibold text-sm mb-3">Payment History</h3>
          <div className="space-y-2">
            {payments.map((p) => (
              <div key={p.id} className="flex items-center gap-3 bg-white/40 rounded-xl px-4 py-3 border border-border/40">
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-semibold numeric text-emerald-700">৳{p.amount.toLocaleString()}</p>
                  <p className="text-xs text-muted-foreground">{fmtDate(p.paid_at)}</p>
                </div>
                <span className="text-[10px] bg-muted px-2 py-0.5 rounded-full capitalize">{p.method}</span>
              </div>
            ))}
          </div>
        </GlassCard>
      )}

      {/* Diet Chart */}
      <GlassCard className="p-5">
        <div className="flex items-center justify-between mb-4">
          <h3 className="font-semibold text-sm flex items-center gap-2">
            <ForkKnife size={14} weight="fill" className="text-primary" /> Diet Chart
          </h3>
          <div className="flex items-center gap-2">
            {/* Language toggle */}
            <div className="flex gap-1 bg-muted/60 rounded-lg p-0.5">
              {(['bn', 'en'] as const).map((lang) => (
                <button
                  key={lang}
                  onClick={() => setDietLang(lang)}
                  className={cn(
                    'px-2.5 py-1 rounded-md text-xs font-semibold transition-all',
                    dietLang === lang ? 'bg-white shadow text-foreground' : 'text-muted-foreground',
                  )}
                >
                  {lang === 'bn' ? 'বাংলা' : 'English'}
                </button>
              ))}
            </div>
            <Button
              size="sm"
              className="gap-1.5 bg-primary text-white hover:bg-primary/90 text-xs h-8"
              onClick={() => genDiet.mutate(dietLang)}
              disabled={genDiet.isPending}
            >
              {genDiet.isPending
                ? <><Spinner size={12} className="animate-spin" /> Generating…</>
                : 'Generate Diet'}
            </Button>
          </div>
        </div>

        {/* Pending diet */}
        {member.pending_diet_chart_json && (
          <div className="mb-4 rounded-xl border border-amber-200/70 bg-amber-50/70 p-4">
            <div className="flex items-center justify-between mb-3">
              <p className="text-xs font-semibold text-amber-800">Pending Diet Chart (awaiting approval)</p>
              <div className="flex gap-2">
                <Button size="sm" className="h-7 text-xs bg-emerald-600 hover:bg-emerald-700 text-white gap-1" onClick={() => approveDiet.mutate()} disabled={approveDiet.isPending}>
                  <Check size={11} weight="bold" /> Approve
                </Button>
                <Button size="sm" variant="outline" className="h-7 text-xs border-red-300 text-red-600 hover:bg-red-50 gap-1" onClick={() => declineDiet.mutate()} disabled={declineDiet.isPending}>
                  <X size={11} weight="bold" /> Decline
                </Button>
              </div>
            </div>
            <DietChartPreview data={member.pending_diet_chart_json} />
          </div>
        )}

        {/* Approved diet */}
        {member.diet_chart_json ? (
          <div>
            <p className="text-[10px] uppercase tracking-wide text-muted-foreground mb-2">Current Approved Diet</p>
            <DietChartPreview data={member.diet_chart_json} />
          </div>
        ) : !member.pending_diet_chart_json && (
          <p className="text-sm text-muted-foreground text-center py-6">No diet chart yet. Generate one above.</p>
        )}
      </GlassCard>

      {/* Approve member modal */}
      {showApproveModal && tempPw && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm px-4">
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            className="glass rounded-2xl p-6 max-w-sm w-full space-y-4"
          >
            <div className="flex items-center gap-3">
              <CheckCircle size={28} weight="fill" className="text-emerald-600" />
              <h3 className="font-bold text-lg">Member Approved</h3>
            </div>
            <p className="text-sm text-muted-foreground">Share this temporary password with the member. They will be prompted to change it on first login.</p>
            <div className="rounded-xl bg-amber-50/80 border border-amber-200/70 px-4 py-3 flex items-center gap-3">
              <Key size={14} className="text-amber-700 shrink-0" />
              <p className="font-mono font-bold text-amber-900 flex-1 text-lg tracking-widest">{tempPw}</p>
              <button onClick={copyTempPw} className="p-1.5 rounded-lg hover:bg-amber-100">
                {copied ? <Check size={14} weight="bold" className="text-emerald-700" /> : <Copy size={14} className="text-amber-700" />}
              </button>
            </div>
            <Button
              className="w-full bg-primary text-white hover:bg-primary/90"
              onClick={() => { setShowApproveModal(false); setTempPw(null) }}
            >
              Done
            </Button>
          </motion.div>
        </div>
      )}
    </div>
  )
}

// ── Tiny helpers ──────────────────────────────────────────────────────────────

function DietChartPreview({ data }: { data: unknown }) {
  let parsed: Record<string, unknown> | null = null
  try {
    parsed = typeof data === 'string' ? JSON.parse(data) : (data as Record<string, unknown>)
  } catch { /* ignore */ }

  if (!parsed) return <pre className="text-xs text-muted-foreground overflow-auto max-h-64">{JSON.stringify(data, null, 2)}</pre>

  return (
    <div className="space-y-3 text-sm max-h-80 overflow-y-auto pr-1">
      {Object.entries(parsed).map(([key, val]) => (
        <div key={key} className="rounded-lg bg-white/50 border border-border/40 px-3 py-2.5">
          <p className="text-[10px] uppercase tracking-wide text-muted-foreground font-semibold mb-1">{key.replace(/_/g, ' ')}</p>
          {typeof val === 'object' && val !== null
            ? <pre className="text-xs text-foreground whitespace-pre-wrap">{JSON.stringify(val, null, 2)}</pre>
            : <p className="text-xs text-foreground">{String(val)}</p>
          }
        </div>
      ))}
    </div>
  )
}

function fmtDate(s?: string | null): string | undefined {
  if (!s) return undefined
  return new Date(s).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })
}

function InfoRow({ icon, label, value, colSpan }: { icon: React.ReactNode; label: string; value?: string | null; colSpan?: boolean }) {
  return (
    <div className={cn('flex items-start gap-2 py-1', colSpan && 'sm:col-span-2')}>
      <span className="text-muted-foreground mt-1 shrink-0">{icon}</span>
      <div className="flex-1 min-w-0">
        <p className="text-[10px] uppercase tracking-wide text-muted-foreground">{label}</p>
        <p className="text-sm text-foreground">{value ?? <span className="text-muted-foreground/70">—</span>}</p>
      </div>
    </div>
  )
}

interface ActionTileProps {
  icon: React.ReactNode
  label: string
  tint: 'primary' | 'accent' | 'info' | 'error'
  href?: string
  onClick?: () => void
  disabled?: boolean
}

const TILE_TINTS = {
  primary: 'hover:bg-primary/8 text-primary',
  accent:  'hover:bg-accent/10  text-accent',
  info:    'hover:bg-blue-50    text-blue-700',
  error:   'hover:bg-red-50     text-red-600',
}

function ActionTile({ icon, label, tint, href, onClick, disabled }: ActionTileProps) {
  const cls = cn(
    'glass rounded-2xl px-3 py-3 flex flex-col items-center justify-center gap-1.5 text-xs font-medium transition-all hover:-translate-y-[1px] disabled:opacity-50 disabled:pointer-events-none',
    TILE_TINTS[tint],
  )
  if (href) return <Link href={href} className={cls}>{icon}<span>{label}</span></Link>
  return <button onClick={onClick} disabled={disabled} className={cls}>{icon}<span>{label}</span></button>
}
