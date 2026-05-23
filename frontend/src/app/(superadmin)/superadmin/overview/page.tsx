'use client'

import { useSAStats, useSAMembers } from '@/hooks/use-superadmin'
import { Skeleton } from '@/components/ui/skeleton'
import { Users, Money, Brain, Warning } from '@phosphor-icons/react'
import Link from 'next/link'

export default function SuperAdminOverview() {
  const { data: stats, isLoading } = useSAStats()
  const { data: membersData } = useSAMembers({ status: 'active' })

  const expiringSoon = membersData?.data.filter((m) => {
    const sub = m.active_subscription
    if (!sub) return false
    const days = Math.ceil((new Date(sub.end_date).getTime() - Date.now()) / 86_400_000)
    return days >= 0 && days <= 7
  }) ?? []

  const tiles = [
    { label: 'Total Members',    value: stats?.total ?? '—',          icon: Users,  bg: 'bg-blue-50',   color: 'text-blue-600' },
    { label: 'AI-Enabled',       value: stats?.aiCount ?? '—',        icon: Brain,  bg: 'bg-purple-50', color: 'text-purple-600' },
    { label: `Revenue ${stats?.month ?? ''}`, value: stats?.revenue ? `৳${stats.revenue.toLocaleString()}` : '—', icon: Money, bg: 'bg-green-50', color: 'text-green-600' },
    { label: 'Expiring (7d)',    value: expiringSoon.length,           icon: Warning, bg: 'bg-amber-50', color: 'text-amber-600' },
  ]

  return (
    <div className="p-4 md:p-6 max-w-4xl mx-auto space-y-6">
      <div>
        <h1 className="text-2xl font-bold">System Overview</h1>
        <p className="text-sm text-muted-foreground mt-0.5">SuperAdmin — full access</p>
      </div>

      {/* Stat tiles */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        {isLoading
          ? Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="h-24 rounded-2xl" />)
          : tiles.map(({ label, value, icon: Icon, bg, color }) => (
              <div key={label} className="bg-card border border-border rounded-2xl p-4">
                <div className={`w-9 h-9 rounded-xl ${bg} flex items-center justify-center mb-3`}>
                  <Icon size={18} className={color} />
                </div>
                <p className="text-xl font-bold">{String(value)}</p>
                <p className="text-xs text-muted-foreground mt-0.5">{label}</p>
              </div>
            ))
        }
      </div>

      {/* Quick links */}
      <div className="grid sm:grid-cols-3 gap-3">
        {[
          { href: '/superadmin/members',    label: 'Member Inspector',   desc: 'View every member\'s full data',          icon: Users  },
          { href: '/superadmin/ai',         label: 'AI Usage',           desc: 'Token usage & image counts per member',   icon: Brain  },
          { href: '/superadmin/permissions',label: 'Permissions',        desc: 'Toggle features per admin/member',        icon: Warning },
        ].map(({ href, label, desc, icon: Icon }) => (
          <Link key={href} href={href}
            className="bg-card border border-border rounded-2xl p-4 hover:bg-muted transition-colors group">
            <Icon size={20} className="text-primary mb-2" />
            <p className="font-semibold text-sm">{label}</p>
            <p className="text-xs text-muted-foreground mt-0.5">{desc}</p>
          </Link>
        ))}
      </div>

      {/* Expiring soon */}
      {expiringSoon.length > 0 && (
        <div className="bg-card border border-amber-200 rounded-2xl p-4">
          <div className="flex items-center gap-2 mb-3">
            <Warning size={16} className="text-amber-500" />
            <p className="font-semibold text-sm">Members Expiring Soon</p>
          </div>
          <div className="space-y-1.5">
            {expiringSoon.slice(0, 8).map((m) => {
              const days = Math.ceil((new Date(m.active_subscription!.end_date).getTime() - Date.now()) / 86_400_000)
              return (
                <Link key={m.id} href={`/superadmin/members?id=${m.id}`}
                  className="flex justify-between items-center py-2 px-2 rounded-lg hover:bg-amber-50 transition-colors">
                  <div>
                    <p className="text-sm font-medium">{m.name}</p>
                    <p className="text-xs text-muted-foreground">{m.phone}</p>
                  </div>
                  <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ${days <= 2 ? 'bg-red-100 text-red-600' : 'bg-amber-100 text-amber-700'}`}>
                    {days === 0 ? 'Today' : `${days}d`}
                  </span>
                </Link>
              )
            })}
          </div>
        </div>
      )}
    </div>
  )
}
