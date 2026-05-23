'use client'

import type { Subscription } from '@/types/member'
import { HandWaving, Warning, Clock, CalendarDot, BellRinging } from '@phosphor-icons/react'

interface Props { subscription: Subscription | null }

export function SubscriptionCard({ subscription: sub }: Props) {
  if (!sub) {
    return (
      <div className="bg-card border border-border rounded-2xl p-5 text-center space-y-2">
        <HandWaving size={32} className="text-primary mx-auto" />
        <p className="font-semibold">Welcome to Fitness Care!</p>
        <p className="text-sm text-muted-foreground">Visit the gym office to activate your membership plan.</p>
      </div>
    )
  }

  const paid     = sub.money_paid
  const total    = sub.final_price
  const due      = sub.money_left
  const progress = total > 0 ? Math.min(paid / total, 1) : 0
  const isPaid   = due <= 0

  const remaining = Math.ceil(
    (new Date(sub.end_date).getTime() - Date.now()) / 86_400_000,
  )

  const durationDays = Math.ceil(
    (new Date(sub.end_date).getTime() - new Date(sub.start_date).getTime()) / 86_400_000,
  )
  const durationLabel = durationDays >= 28
    ? `${Math.round(durationDays / 30)} Month${Math.round(durationDays / 30) > 1 ? 's' : ''}`
    : `${durationDays} Days`

  const remainingLabel = remaining > 0 ? `${remaining} days left`
    : remaining === 0 ? 'Expires today' : 'Expired'

  const billingInfo = resolveBilling(sub)

  return (
    <div className={`bg-card rounded-2xl border p-5 space-y-4 ${isPaid ? 'border-green-200' : 'border-border'}`}>
      <div className="flex justify-between items-start">
        <div>
          <p className="font-bold text-base">{sub.plan_name || sub.note || 'Membership Plan'}</p>
          <p className={`text-xs mt-0.5 font-medium ${remaining > 5 ? 'text-muted-foreground' : 'text-red-500'}`}>
            {durationLabel} · {remainingLabel}
          </p>
        </div>
        <div className="text-right">
          <p className="font-bold text-primary text-base">৳{total.toLocaleString()}</p>
          <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full ${
            sub.billing_type === 'prepaid' ? 'bg-green-100 text-green-700' : 'bg-blue-100 text-blue-700'
          }`}>
            {sub.billing_type === 'prepaid' ? 'Prepaid' : 'Postpaid'}
          </span>
        </div>
      </div>

      {billingInfo && (
        <div className={`flex items-center gap-2 text-xs px-3 py-2 rounded-lg ${billingInfo.bg}`}>
          <billingInfo.Icon size={14} className={billingInfo.color} />
          <span className={`font-medium ${billingInfo.color}`}>{billingInfo.text}</span>
        </div>
      )}

      {/* Progress bar */}
      <div>
        <div className="h-2 rounded-full bg-border overflow-hidden">
          <div
            className={`h-full rounded-full transition-all ${isPaid ? 'bg-green-500' : 'bg-amber-400'}`}
            style={{ width: `${progress * 100}%` }}
          />
        </div>
        <div className="flex justify-between mt-1.5 text-xs">
          <span className="text-green-600 font-medium">Paid ৳{paid.toLocaleString()}</span>
          <span className={`font-medium ${isPaid ? 'text-muted-foreground' : 'text-red-500'}`}>
            Due ৳{due.toLocaleString()}
          </span>
        </div>
      </div>
    </div>
  )
}

interface BillingInfo {
  Icon: React.ComponentType<{ size?: number; className?: string }>
  text: string
  color: string
  bg: string
}

function resolveBilling(sub: Subscription): BillingInfo | null {
  const fmt = (d: string) => new Date(d).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })
  switch (sub.billing_status) {
    case 'prepaid_overdue':
      return { Icon: Warning, text: `Overdue by ${Math.abs(sub.days_until_due ?? 0)} days`, color: 'text-red-600', bg: 'bg-red-50' }
    case 'prepaid_due':
      return { Icon: CalendarDot, text: sub.prepaid_due_date ? `Due by ${fmt(sub.prepaid_due_date)}` : `Due in ${sub.days_until_due ?? 0} days`, color: 'text-amber-600', bg: 'bg-amber-50' }
    case 'postpaid_window_open':
      return { Icon: BellRinging, text: `Payment window open — closes in ${sub.days_until_due ?? 0} days`, color: 'text-amber-600', bg: 'bg-amber-50' }
    case 'postpaid_overdue':
      return { Icon: Warning, text: `Grace period ended ${Math.abs(sub.days_until_due ?? 0)} days ago`, color: 'text-red-600', bg: 'bg-red-50' }
    case 'postpaid_not_due_yet':
      return { Icon: Clock, text: `Payment window opens in ${sub.days_until_due ?? 0} days`, color: 'text-muted-foreground', bg: 'bg-muted' }
    default:
      return null
  }
}
