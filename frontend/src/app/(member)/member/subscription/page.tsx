'use client'

import { useMemberSubscription, useMemberPayments } from '@/hooks/use-member'
import { SubscriptionCard } from '@/components/member/subscription-card'
import { Skeleton } from '@/components/ui/skeleton'

export default function MemberSubscription() {
  const { data: sub, isLoading }   = useMemberSubscription()
  const { data: payments = [] }    = useMemberPayments()

  return (
    <div className="p-4 md:p-6 max-w-lg mx-auto space-y-5">
      <h1 className="text-xl font-bold">Subscription</h1>

      {isLoading
        ? <Skeleton className="h-40 rounded-2xl" />
        : <SubscriptionCard subscription={sub ?? null} />
      }

      {payments.length > 0 && (
        <div>
          <p className="text-sm font-semibold mb-3">Payment History</p>
          <div className="space-y-2">
            {payments.map((p) => (
              <div key={p.id} className="flex justify-between items-center bg-card border border-border rounded-xl px-4 py-3">
                <div>
                  <p className="text-sm font-medium">৳{p.amount.toLocaleString()}</p>
                  <p className="text-xs text-muted-foreground">
                    {new Date(p.paid_at).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })}
                  </p>
                </div>
                {p.note && <p className="text-xs text-muted-foreground max-w-[140px] text-right truncate">{p.note}</p>}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}
