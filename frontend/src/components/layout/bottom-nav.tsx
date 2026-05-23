'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import * as Icons from '@phosphor-icons/react'
import { cn } from '@/lib/utils'
import type { Role } from '@/types'
import { NAV } from './nav-config'

interface BottomNavProps { role: Role }

export function BottomNav({ role }: BottomNavProps) {
  const pathname = usePathname()
  const items = NAV[role].slice(0, 5)

  return (
    <nav className="md:hidden fixed bottom-0 left-0 right-0 z-40 glass-strong border-t border-border/40 pb-[env(safe-area-inset-bottom)]">
      <div className="flex">
        {items.map((item) => {
          const Icon = (Icons as unknown as Record<string, React.ComponentType<{ size?: number; weight?: string }>>)[item.icon]
          const active = pathname.startsWith(item.href)
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                'flex-1 flex flex-col items-center justify-center gap-0.5 py-2.5 text-[10px] font-medium transition-colors',
                active ? 'text-primary' : 'text-muted-foreground',
              )}
            >
              {Icon && <Icon size={20} weight={active ? 'fill' : 'regular'} />}
              <span>{item.label}</span>
            </Link>
          )
        })}
      </div>
    </nav>
  )
}
