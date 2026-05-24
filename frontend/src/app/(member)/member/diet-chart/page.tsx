'use client'

import { useMemberProfile } from '@/hooks/use-member'
import { DietChartView } from '@/components/admin/diet-chart-view'
import { Skeleton } from '@/components/ui/skeleton'
import { ForkKnife, Clock, Leaf } from '@phosphor-icons/react'

export default function MemberDietChartPage() {
  const { data: member, isLoading } = useMemberProfile()

  if (isLoading) {
    return (
      <div className="p-4 md:p-6 max-w-2xl mx-auto space-y-4">
        <Skeleton className="h-8 w-40" />
        <Skeleton className="h-32 rounded-2xl" />
        <Skeleton className="h-48 rounded-2xl" />
        <Skeleton className="h-48 rounded-2xl" />
      </div>
    )
  }

  const chart = member?.diet_chart
  const hasChart = chart && Object.keys(chart).length > 0

  const isNew = hasChart && 'detailed_diet_chart' in chart
  const totalCalories = isNew
    ? (chart as { daily_targets?: { target_calories?: number } }).daily_targets?.target_calories
    : (chart as { daily_calories?: number } | undefined)?.daily_calories

  return (
    <div className="p-4 md:p-6 max-w-2xl mx-auto space-y-5">
      {/* Page header */}
      <div className="flex items-center gap-2.5">
        <div className="w-9 h-9 rounded-xl bg-primary/10 flex items-center justify-center">
          <ForkKnife size={18} weight="fill" className="text-primary" />
        </div>
        <div>
          <h1 className="text-xl font-bold leading-tight">আমার ডায়েট চার্ট</h1>
          {totalCalories && (
            <p className="text-xs text-muted-foreground">{totalCalories} kcal daily target</p>
          )}
        </div>
      </div>

      {!hasChart ? (
        <NoPlanCard />
      ) : (
        <DietChartView chart={chart} />
      )}
    </div>
  )
}

function NoPlanCard() {
  return (
    <div className="flex flex-col items-center justify-center py-16 text-center space-y-4">
      <div className="w-16 h-16 rounded-2xl bg-muted flex items-center justify-center">
        <Leaf size={28} className="text-muted-foreground" />
      </div>
      <div>
        <p className="font-semibold text-foreground">কোনো ডায়েট চার্ট নেই</p>
        <p className="text-sm text-muted-foreground mt-1 max-w-xs">
          আপনার ট্রেইনার এখনো ডায়েট চার্ট তৈরি করেননি।
          অনুগ্রহ করে অপেক্ষা করুন।
        </p>
      </div>
      <div className="flex items-center gap-1.5 text-xs text-muted-foreground bg-muted/60 px-3 py-1.5 rounded-full">
        <Clock size={12} /> আপনার ট্রেইনার শীঘ্রই আপডেট করবেন
      </div>
    </div>
  )
}
