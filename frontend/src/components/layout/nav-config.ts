import type { Role } from '@/types'

export interface NavItem {
  label: string
  href: string
  icon: string  // phosphor icon name
}

export const NAV: Record<Role, NavItem[]> = {
  member: [
    { label: 'Home',         href: '/member/dashboard',     icon: 'House' },
    { label: 'Diet',         href: '/member/diet-chart',    icon: 'ForkKnife' },
    { label: 'Messages',     href: '/member/messages',      icon: 'ChatText' },
    { label: 'Subscription', href: '/member/subscription',  icon: 'CreditCard' },
    { label: 'Profile',      href: '/member/profile',       icon: 'User' },
    { label: 'Logs',         href: '/member/logs',          icon: 'ChartLine' },
  ],
  admin: [
    { label: 'Dashboard',    href: '/admin/dashboard',      icon: 'SquaresFour' },
    { label: 'Financials',   href: '/admin/financials',     icon: 'ChartLineUp' },
    { label: 'Members',      href: '/admin/members',        icon: 'Users' },
    { label: 'Plans',        href: '/admin/plans',          icon: 'Scroll' },
    { label: 'Messages',     href: '/admin/messages',       icon: 'ChatTeardropDots' },
    { label: 'Payments',     href: '/admin/payments',       icon: 'Money' },
    { label: 'AI',           href: '/admin/ai',             icon: 'Brain' },
    { label: 'Settings',     href: '/admin/settings',       icon: 'Gear' },
  ],
  superadmin: [
    { label: 'Overview',      href: '/superadmin/overview',     icon: 'PresentationChart' },
    { label: 'Provisioning',  href: '/superadmin/provisioning', icon: 'Buildings' },
    { label: 'Admins',        href: '/superadmin/admins',       icon: 'ShieldCheck' },
    { label: 'Members',       href: '/superadmin/members',      icon: 'Users' },
    { label: 'AI Usage',      href: '/superadmin/ai',           icon: 'Brain' },
    { label: 'Audit',         href: '/superadmin/audit',        icon: 'ClipboardText' },
  ],
}
