'use client'

import { useMemberProfile, useMemberSubscription, useWeightLogs, useMemberMessages } from '@/hooks/use-member'
import { Skeleton } from '@/components/ui/skeleton'
import { SubscriptionCard } from '@/components/member/subscription-card'
import { WeightChart } from '@/components/member/weight-chart'
import { MessageBanners } from '@/components/member/message-banners'
import { Leaf, ChatText } from '@phosphor-icons/react'
import Link from 'next/link'

export default function MemberDashboard() {
  const { data: member, isLoading: loadingMember } = useMemberProfile()
  const { data: sub } = useMemberSubscription()
  const { data: logs = [] } = useWeightLogs()
  const { data: messages = [] } = useMemberMessages()

  const adminMessages = messages.filter((m) => m.sender_role === 'admin')
  const lastDirect    = adminMessages.filter((m) => !m.is_broadcast).at(-1)
  const lastBroadcast = adminMessages.filter((m) =>  m.is_broadcast).at(-1)
  const banners = [lastDirect, lastBroadcast].filter(Boolean) as typeof messages

  function greeting() {
    const h = new Date().getHours()
    const rel = member?.religion?.toLowerCase() ?? ''
    if (rel.includes('islam') || rel.includes('muslim')) return 'Assalamu Alaikum'
    if (h < 12) return 'Good morning'
    if (h < 17) return 'Good afternoon'
    return 'Good evening'
  }

  return (
    <div className="p-4 md:p-6 max-w-2xl mx-auto space-y-5">

      {/* Banners */}
      {banners.length > 0 && <MessageBanners messages={banners} />}

      {/* Greeting */}
      {loadingMember ? (
        <div className="space-y-2">
          <Skeleton className="h-8 w-48" />
          <Skeleton className="h-5 w-32" />
        </div>
      ) : (
        <div>
          <p className="text-muted-foreground text-sm">{greeting()},</p>
          <h1 className="text-2xl font-bold text-foreground">{member?.name} 🌿</h1>
          <p className="text-xs text-muted-foreground mt-0.5">
            {new Date().toLocaleDateString('en-GB', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })}
          </p>
        </div>
      )}

      {/* Subscription */}
      <SubscriptionCard subscription={sub ?? null} />

      {/* Weight chart */}
      {logs.length > 1 && <WeightChart logs={logs} />}

      {/* Quick stats */}
      {member && (
        <div className="grid grid-cols-3 gap-3">
          {[
            { label: 'Height', value: member.height_cm ? `${member.height_cm} cm` : '—' },
            { label: 'Age',    value: member.age ?? '—' },
            { label: 'Gender', value: member.gender ?? '—' },
          ].map(({ label, value }) => (
            <div key={label} className="bg-card rounded-xl border border-border p-3 text-center">
              <p className="text-xs text-muted-foreground">{label}</p>
              <p className="text-base font-semibold mt-0.5">{String(value)}</p>
            </div>
          ))}
        </div>
      )}

      {/* Diet plan quick card */}
      {member?.diet_chart && Object.keys(member.diet_chart).length > 0 ? (
        <div className="bg-green-50 border border-green-200 rounded-xl p-4 flex items-center gap-3">
          <Leaf size={20} className="text-green-600 shrink-0" />
          <div className="flex-1 min-w-0">
            <p className="text-sm font-semibold text-green-800">Active Nutrition Plan</p>
            <p className="text-xs text-green-600 truncate">
              {(member.diet_chart as { daily_calories?: number }).daily_calories
                ? `${(member.diet_chart as { daily_calories: number }).daily_calories} kcal daily`
                : 'View your diet chart'}
            </p>
          </div>
        </div>
      ) : null}

      {/* Messages shortcut */}
      <Link
        href="/member/messages"
        className="flex items-center gap-3 bg-card border border-border rounded-xl p-4 hover:bg-muted transition-colors"
      >
        <ChatText size={20} className="text-primary shrink-0" />
        <div className="flex-1 min-w-0">
          <p className="text-sm font-semibold">Messages</p>
          <p className="text-xs text-muted-foreground">
            {messages.filter(m => m.sender_role === 'admin').length > 0
              ? 'You have messages from your trainer'
              : 'Chat with your admin / trainer'}
          </p>
        </div>
      </Link>
    </div>
  )
}
