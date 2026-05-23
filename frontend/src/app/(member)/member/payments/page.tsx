'use client'

import { useMemberPayments } from '@/hooks/use-member'
import { Skeleton } from '@/components/ui/skeleton'
import { Receipt } from '@phosphor-icons/react'

export default function MemberPayments() {
  const { data: payments = [], isLoading } = useMemberPayments()

  return (
    <div className="p-4 md:p-6 max-w-lg mx-auto">
      <h1 className="text-xl font-bold mb-5">Payments</h1>

      {isLoading ? (
        <div className="space-y-3">
          {Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="h-16 rounded-xl" />)}
        </div>
      ) : payments.length === 0 ? (
        <div className="text-center py-16">
          <Receipt size={40} className="text-muted-foreground mx-auto mb-3" />
          <p className="text-sm text-muted-foreground">No payments recorded yet.</p>
        </div>
      ) : (
        <div className="space-y-2">
          {payments.map((p) => (
            <div key={p.id} className="flex justify-between items-center bg-card border border-border rounded-xl px-4 py-3">
              <div>
                <p className="text-sm font-semibold text-green-600">৳{p.amount.toLocaleString()}</p>
                <p className="text-xs text-muted-foreground">
                  {new Date(p.paid_at).toLocaleDateString('en-GB', { weekday: 'short', day: 'numeric', month: 'short', year: 'numeric' })}
                </p>
              </div>
              {p.note && <p className="text-xs text-muted-foreground text-right max-w-[140px] truncate">{p.note}</p>}
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
