'use client'

import { Sidebar } from './sidebar'
import { BottomNav } from './bottom-nav'
import { Header } from './header'
import type { Role } from '@/types'
import { motion, AnimatePresence } from 'framer-motion'
import { usePathname } from 'next/navigation'

interface ShellProps {
  role: Role
  userName: string
  children: React.ReactNode
}

export function Shell({ role, userName, children }: ShellProps) {
  const pathname = usePathname()

  return (
    <div className="flex h-screen overflow-hidden">
      <Sidebar role={role} userName={userName} />

      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        <Header role={role} userName={userName} />

        <main className="flex-1 overflow-y-auto pb-20 md:pb-0">
          <AnimatePresence mode="wait">
            <motion.div
              key={pathname}
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -8 }}
              transition={{ duration: 0.15, ease: 'easeInOut' }}
              className="h-full"
            >
              {children}
            </motion.div>
          </AnimatePresence>
        </main>
      </div>

      <BottomNav role={role} />
    </div>
  )
}
