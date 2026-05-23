import { cn } from '@/lib/utils'
import { forwardRef } from 'react'

interface GlassCardProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: 'default' | 'strong' | 'subtle'
  hoverable?: boolean
}

export const GlassCard = forwardRef<HTMLDivElement, GlassCardProps>(
  ({ className, variant = 'default', hoverable = false, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn(
          'rounded-2xl',
          variant === 'default' && 'glass',
          variant === 'strong' && 'glass-strong',
          variant === 'subtle' && 'bg-white/40 backdrop-blur-sm border border-border/60',
          hoverable && 'hover:shadow-md hover:-translate-y-[1px] cursor-pointer',
          'transition-all duration-200',
          className,
        )}
        {...props}
      />
    )
  },
)
GlassCard.displayName = 'GlassCard'

interface StatTileProps {
  label: string
  value: React.ReactNode
  delta?: { value: number; positive?: boolean }
  icon?: React.ReactNode
  tint?: 'primary' | 'accent' | 'success' | 'warning' | 'error' | 'info'
  className?: string
}

const TINT_MAP: Record<NonNullable<StatTileProps['tint']>, { bg: string; text: string }> = {
  primary: { bg: 'bg-primary/8',     text: 'text-primary' },
  accent:  { bg: 'bg-accent/10',     text: 'text-accent' },
  success: { bg: 'bg-emerald-100/60', text: 'text-emerald-700' },
  warning: { bg: 'bg-orange-100/70', text: 'text-orange-600' },
  error:   { bg: 'bg-red-100/60',    text: 'text-red-600' },
  info:    { bg: 'bg-blue-100/60',   text: 'text-blue-600' },
}

export function StatTile({ label, value, delta, icon, tint = 'primary', className }: StatTileProps) {
  const t = TINT_MAP[tint]
  return (
    <GlassCard className={cn('p-5', className)}>
      <div className="flex items-start justify-between mb-3">
        {icon && (
          <div className={cn('w-10 h-10 rounded-xl flex items-center justify-center', t.bg, t.text)}>
            {icon}
          </div>
        )}
        {delta && (
          <span className={cn(
            'text-[10px] font-semibold px-2 py-0.5 rounded-full',
            delta.positive
              ? 'bg-emerald-100/70 text-emerald-700'
              : 'bg-red-100/60 text-red-600',
          )}>
            {delta.positive ? '+' : ''}{delta.value.toFixed(1)}%
          </span>
        )}
      </div>
      <p className={cn('text-2xl font-bold numeric text-foreground')}>{value}</p>
      <p className="text-xs text-muted-foreground mt-1">{label}</p>
    </GlassCard>
  )
}
