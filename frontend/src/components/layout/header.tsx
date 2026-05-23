'use client'

import { usePathname, useRouter } from 'next/navigation'
import { User, SignOut } from '@phosphor-icons/react'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import { clearToken } from '@/lib/auth'
import type { Role } from '@/types'

interface HeaderProps {
  role: Role
  userName: string
}

function prettyName(pathname: string): string {
  const segment = pathname.split('/').filter(Boolean).at(-1) ?? ''
  return segment.replace(/-/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase()) || 'Dashboard'
}

const ROLE_PILL: Record<Role, string> = {
  member:     'bg-primary/8 text-primary',
  admin:      'bg-blue-100/60 text-blue-700',
  superadmin: 'bg-orange-100/70 text-accent',
}
const ROLE_LABEL: Record<Role, string> = {
  member: 'Member', admin: 'Admin', superadmin: 'Super Admin',
}

export function Header({ role, userName }: HeaderProps) {
  const pathname = usePathname()
  const router   = useRouter()
  const initials = userName.slice(0, 2).toUpperCase()

  return (
    <header className="sticky top-0 z-20 glass-strong border-b border-border/40 px-4 md:px-6 h-14 flex items-center justify-between">
      <div className="flex items-center gap-2">
        <span className="md:hidden font-bold text-sm tracking-tight">Fitness Care</span>
        <span className="hidden md:block text-sm font-semibold text-foreground tracking-tight">
          {prettyName(pathname)}
        </span>
      </div>

      <div className="flex items-center gap-3">
        <span className={`hidden sm:inline-block text-[10px] font-semibold px-2.5 py-1 rounded-full ${ROLE_PILL[role]}`}>
          {ROLE_LABEL[role]}
        </span>

        <DropdownMenu>
          <DropdownMenuTrigger className="outline-none cursor-pointer">
            <Avatar className="w-8 h-8">
              <AvatarFallback className="bg-primary/12 text-primary text-xs font-bold">
                {initials}
              </AvatarFallback>
            </Avatar>
          </DropdownMenuTrigger>

          <DropdownMenuContent align="end" className="w-48">
            <div className="px-3 py-2">
              <p className="text-sm font-semibold truncate">{userName}</p>
              <p className="text-[11px] text-muted-foreground">{ROLE_LABEL[role]}</p>
            </div>
            <DropdownMenuSeparator />
            <DropdownMenuItem
              className="cursor-pointer flex items-center gap-2"
              onClick={() => router.push(`/${role}/profile`)}
            >
              <User size={14} />
              Profile
            </DropdownMenuItem>
            <DropdownMenuSeparator />
            <DropdownMenuItem
              className="text-destructive cursor-pointer flex items-center gap-2"
              onClick={() => { clearToken(); document.cookie = 'fc_token=; path=/; max-age=0'; router.replace('/login') }}
            >
              <SignOut size={14} />
              Sign out
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </header>
  )
}
