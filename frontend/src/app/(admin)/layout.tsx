'use client'

import { Shell } from '@/components/layout/shell'

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <Shell role="admin" userName="Admin">
      {children}
    </Shell>
  )
}
