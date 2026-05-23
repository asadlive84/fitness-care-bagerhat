'use client'

import { useAdminMembers, useAdminPlans, usePaymentSummary, useConversations } from '@/hooks/use-admin'
import { Skeleton } from '@/components/ui/skeleton'
import { Users, Scroll, Money, ChatTeardropDots, Warning } from '@phosphor-icons/react'
import Link from 'next/link'

export default function AdminDashboard() {
  const month = new Date().toISOString().slice(0, 7)
  const { data: membersData } = useAdminMembers({ status: 'all' })
  const { data: activeMembers } = useAdminMembers({ status: 'active' })
  const { data: plans = [] } = useAdminPlans()
  const { data: summary } = usePaymentSummary(month)
  const { data: conversations = [] } = useConversations()

  const total  = membersData?.meta?.total ?? membersData?.data.length ?? 0
  const active = activeMembers?.meta?.total ?? activeMembers?.data.length ?? 0

  // Members expiring within 7 days
  const expiringSoon = activeMembers?.data.filter((m) => {
    const sub = m.active_subscription
    if (!sub) return false
    const days = Math.ceil((new Date(sub.end_date).getTime() - Date.now()) / 86_400_000)
    return days >= 0 && days <= 7
  }) ?? []

  // Members with outstanding due
  const duePending = activeMembers?.data.filter((m) => {
    const sub = m.active_subscription
    return sub && sub.money_left > 0
  }) ?? []

  const stats = [
    { label: 'Total Members', value: total,            icon: Users,              color: 'text-blue-600',   bg: 'bg-blue-50'  },
    { label: 'Active Members', value: active,           icon: Users,              color: 'text-green-600',  bg: 'bg-green-50' },
    { label: 'Active Plans',   value: plans.length,     icon: Scroll,             color: 'text-purple-600', bg: 'bg-purple-50'},
    { label: 'Revenue ('+month+')', value: summary ? `৳${summary.total_amount.toLocaleString()}` : '—', icon: Money, color: 'text-amber-600', bg: 'bg-amber-50' },
  ]

  return (
    <div className="p-4 md:p-6 space-y-6 max-w-4xl mx-auto">
      <h1 className="text-2xl font-bold">Dashboard</h1>

      {/* Stats grid */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        {stats.map(({ label, value, icon: Icon, color, bg }) => (
          <div key={label} className="bg-card border border-border rounded-2xl p-4">
            <div className={`w-9 h-9 rounded-xl ${bg} flex items-center justify-center mb-3`}>
              <Icon size={18} className={color} />
            </div>
            <p className="text-xl font-bold">{String(value)}</p>
            <p className="text-xs text-muted-foreground mt-0.5">{label}</p>
          </div>
        ))}
      </div>

      <div className="grid md:grid-cols-2 gap-4">
        {/* Expiring soon */}
        <div className="bg-card border border-border rounded-2xl p-4">
          <div className="flex items-center gap-2 mb-3">
            <Warning size={16} className="text-amber-500" />
            <p className="font-semibold text-sm">Expiring Soon (7 days)</p>
            <span className="ml-auto text-xs bg-amber-100 text-amber-700 px-2 py-0.5 rounded-full">{expiringSoon.length}</span>
          </div>
          {expiringSoon.length === 0
            ? <p className="text-xs text-muted-foreground">No expiring subscriptions.</p>
            : expiringSoon.slice(0, 5).map((m) => {
                const days = Math.ceil((new Date(m.active_subscription!.end_date).getTime() - Date.now()) / 86_400_000)
                return (
                  <Link key={m.id} href={`/admin/members?id=${m.id}`} className="flex justify-between items-center py-2 border-b border-border last:border-0 hover:bg-muted -mx-2 px-2 rounded-lg transition-colors">
                    <div>
                      <p className="text-sm font-medium">{m.name}</p>
                      <p className="text-xs text-muted-foreground">{m.phone}</p>
                    </div>
                    <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ${days <= 2 ? 'bg-red-100 text-red-600' : 'bg-amber-100 text-amber-700'}`}>
                      {days === 0 ? 'Today' : `${days}d`}
                    </span>
                  </Link>
                )
              })
          }
        </div>

        {/* Due payments */}
        <div className="bg-card border border-border rounded-2xl p-4">
          <div className="flex items-center gap-2 mb-3">
            <Money size={16} className="text-red-500" />
            <p className="font-semibold text-sm">Pending Dues</p>
            <span className="ml-auto text-xs bg-red-100 text-red-600 px-2 py-0.5 rounded-full">{duePending.length}</span>
          </div>
          {duePending.length === 0
            ? <p className="text-xs text-muted-foreground">All payments cleared.</p>
            : duePending.slice(0, 5).map((m) => (
                <Link key={m.id} href={`/admin/members?id=${m.id}`} className="flex justify-between items-center py-2 border-b border-border last:border-0 hover:bg-muted -mx-2 px-2 rounded-lg transition-colors">
                  <div>
                    <p className="text-sm font-medium">{m.name}</p>
                    <p className="text-xs text-muted-foreground">{m.phone}</p>
                  </div>
                  <span className="text-xs font-semibold text-red-600">৳{m.active_subscription!.money_left.toLocaleString()}</span>
                </Link>
              ))
          }
        </div>
      </div>

      {/* Recent conversations */}
      {conversations.length > 0 && (
        <div className="bg-card border border-border rounded-2xl p-4">
          <div className="flex items-center gap-2 mb-3">
            <ChatTeardropDots size={16} className="text-primary" />
            <p className="font-semibold text-sm">Recent Messages</p>
            <Link href="/admin/messages" className="ml-auto text-xs text-primary">View all</Link>
          </div>
          <div className="space-y-1">
            {conversations.slice(0, 4).map((c) => (
              <Link key={c.member_id} href={`/admin/messages?id=${c.member_id}`} className="flex justify-between items-center py-2 hover:bg-muted -mx-2 px-2 rounded-lg transition-colors">
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-medium truncate">{c.member_name ?? c.member_id.slice(-8)}</p>
                  <p className="text-xs text-muted-foreground truncate">{c.last_message}</p>
                </div>
                <div className="flex items-center gap-2 shrink-0 ml-2">
                  {c.sender_role === 'member' && <span className="w-2 h-2 rounded-full bg-primary" />}
                  <p className="text-xs text-muted-foreground">{new Date(c.last_sent_at).toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' })}</p>
                </div>
              </Link>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}
