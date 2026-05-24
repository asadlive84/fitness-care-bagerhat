'use client'

import Link from 'next/link'
import { usePathname, useRouter } from 'next/navigation'
import { useState } from 'react'
import * as Icons from '@phosphor-icons/react'
import { cn } from '@/lib/utils'
import { clearToken } from '@/lib/auth'
import type { Role } from '@/types'
import { NAV } from './nav-config'
import { usePendingMembersCount } from '@/hooks/use-admin'

interface SidebarProps {
  role: Role
  userName: string
}

const ROLE_META: Record<Role, { label: string; ring: string; dot: string }> = {
  member:     { label: 'Member',      ring: 'ring-primary/20',    dot: 'bg-primary' },
  admin:      { label: 'Admin',       ring: 'ring-blue-300/30',   dot: 'bg-blue-600' },
  superadmin: { label: 'Super Admin', ring: 'ring-orange-300/30', dot: 'bg-accent' },
}

export function Sidebar({ role, userName }: SidebarProps) {
  const pathname = usePathname()
  const router   = useRouter()
  const [collapsed, setCollapsed] = useState(false)
  const items = NAV[role]
  const meta  = ROLE_META[role]
  const { data: pendingCount } = usePendingMembersCount(role === 'admin')

  function logout() {
    clearToken()
    document.cookie = 'fc_token=; path=/; max-age=0'
    router.replace('/login')
  }

  return (
    <aside
      className={cn(
        'hidden md:flex flex-col h-screen sticky top-0 glass-strong transition-all duration-300 z-30 border-r border-border/60',
        collapsed ? 'w-16' : 'w-60',
      )}
    >
      {/* Logo + collapse */}
      <div className={cn('flex items-center px-3 py-4 border-b border-border/40', collapsed ? 'justify-center' : 'justify-between')}>
        {!collapsed && (
          <div className="flex items-center gap-2">
            <div className="w-7 h-7 rounded-lg bg-primary flex items-center justify-center">
              <Icons.Plant size={15} weight="fill" className="text-white" />
            </div>
            <span className="font-bold text-sm tracking-tight">Fitness Care</span>
          </div>
        )}
        <button
          onClick={() => setCollapsed(!collapsed)}
          className="p-1.5 rounded-lg hover:bg-muted/60 transition-colors"
          aria-label={collapsed ? 'Expand' : 'Collapse'}
        >
          {collapsed
            ? <Icons.CaretRight size={14} />
            : <Icons.CaretLeft  size={14} />
          }
        </button>
      </div>

      {/* Role chip */}
      {!collapsed && (
        <div className="px-3 py-3">
          <div className={cn('inline-flex items-center gap-2 text-[10px] font-semibold px-2.5 py-1 rounded-full bg-white/60 border border-border/60 ring-2', meta.ring)}>
            <span className={cn('w-1.5 h-1.5 rounded-full', meta.dot)} />
            {meta.label}
          </div>
        </div>
      )}

      {/* Nav */}
      <nav className="flex-1 overflow-y-auto px-2 py-1 space-y-0.5">
        {items.map((item) => {
          const Icon = (Icons as unknown as Record<string, React.ComponentType<{ size?: number; weight?: string }>>)[item.icon]
          const active = pathname.startsWith(item.href)
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                'flex items-center gap-3 px-2.5 py-2 rounded-lg text-sm font-medium transition-all relative',
                active
                  ? 'bg-primary/8 text-primary'
                  : 'text-muted-foreground hover:bg-muted/50 hover:text-foreground',
              )}
            >
              {active && !collapsed && (
                <span className="absolute left-0 top-1.5 bottom-1.5 w-0.5 rounded-r-full bg-primary" />
              )}
              {Icon && <Icon size={17} weight={active ? 'fill' : 'regular'} />}
              {!collapsed && <span className="truncate flex-1">{item.label}</span>}
              {!collapsed && role === 'admin' && item.href === '/admin/members' && (pendingCount ?? 0) > 0 && (
                <span className="ml-auto min-w-[18px] h-[18px] flex items-center justify-center rounded-full bg-accent text-white text-[10px] font-bold px-1">
                  {pendingCount! > 99 ? '99+' : pendingCount}
                </span>
              )}
            </Link>
          )
        })}
      </nav>

      {/* User */}
      <div className="border-t border-border/40 px-2 py-3">
        <div className={cn('flex items-center gap-2 px-1', collapsed && 'justify-center')}>
          <div className="w-8 h-8 rounded-full bg-primary/12 flex items-center justify-center shrink-0">
            <span className="text-[11px] font-bold text-primary">{userName.charAt(0).toUpperCase()}</span>
          </div>
          {!collapsed && (
            <div className="flex-1 min-w-0">
              <p className="text-xs font-medium truncate">{userName}</p>
              <p className="text-[10px] text-muted-foreground">{meta.label}</p>
            </div>
          )}
          <button
            onClick={logout}
            className="p-1.5 rounded-lg hover:bg-muted/60 transition-colors"
            title="Sign out"
          >
            <Icons.SignOut size={14} className="text-muted-foreground" />
          </button>
        </div>
      </div>
    </aside>
  )
}
