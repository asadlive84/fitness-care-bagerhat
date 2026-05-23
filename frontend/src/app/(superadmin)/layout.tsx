'use client'

import { Shell } from '@/components/layout/shell'

export default function SuperAdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <Shell role="superadmin" userName="Super Admin">
      {children}
    </Shell>
  )
}
