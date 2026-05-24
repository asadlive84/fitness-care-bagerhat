'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { Barbell, List, X } from '@phosphor-icons/react'
import { getRole, roleHomePath } from '@/lib/auth'

export function PublicHeader() {
  const [dashPath, setDashPath] = useState<string | null>(null)
  const [menuOpen, setMenuOpen] = useState(false)

  useEffect(() => {
    const role = getRole()
    if (role) setDashPath(roleHomePath(role))
  }, [])

  return (
    <header className="fixed top-0 inset-x-0 z-50 glass-strong border-b border-white/30">
      <nav className="max-w-6xl mx-auto px-4 h-14 flex items-center justify-between">
        <Link href="/" className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-lg bg-[#1B5E20] flex items-center justify-center">
            <Barbell size={18} weight="bold" className="text-white" />
          </div>
          <span className="font-bold text-[#1B5E20] text-sm leading-tight">
            ফিটনেস কেয়ার<br />
            <span className="text-xs font-medium text-[#4C7A4F]">বাগেরহাট</span>
          </span>
        </Link>

        {/* Desktop nav */}
        <div className="hidden sm:flex items-center gap-4 text-sm font-medium text-[#3a5c3f]">
          <Link href="/#services" className="hover:text-[#1B5E20]">সেবাসমূহ</Link>
          <Link href="/#plans" className="hover:text-[#1B5E20]">মেম্বারশিপ</Link>
          <Link href="/#contact" className="hover:text-[#1B5E20]">যোগাযোগ</Link>
          {dashPath ? (
            <Link
              href={dashPath}
              className="px-4 py-1.5 rounded-full bg-[#1B5E20] text-white text-xs font-semibold hover:bg-[#155218] transition"
            >
              ড্যাশবোর্ড
            </Link>
          ) : (
            <>
              <Link
                href="/register"
                className="px-4 py-1.5 rounded-full border border-[#1B5E20] text-[#1B5E20] text-xs font-semibold hover:bg-[#1B5E20] hover:text-white transition"
              >
                নিবন্ধন
              </Link>
              <Link
                href="/login"
                className="px-4 py-1.5 rounded-full bg-[#1B5E20] text-white text-xs font-semibold hover:bg-[#155218] transition"
              >
                লগইন
              </Link>
            </>
          )}
        </div>

        {/* Mobile hamburger */}
        <button
          className="sm:hidden p-2 rounded-lg text-[#1B5E20]"
          onClick={() => setMenuOpen(v => !v)}
          aria-label="মেনু"
        >
          {menuOpen ? <X size={22} /> : <List size={22} />}
        </button>
      </nav>

      {/* Mobile menu */}
      {menuOpen && (
        <div className="sm:hidden glass-strong border-t border-white/30 px-4 pb-4 flex flex-col gap-2 text-sm font-medium text-[#3a5c3f]">
          <Link href="/#services" onClick={() => setMenuOpen(false)} className="py-2 border-b border-[#e0e8e1]">সেবাসমূহ</Link>
          <Link href="/#plans" onClick={() => setMenuOpen(false)} className="py-2 border-b border-[#e0e8e1]">মেম্বারশিপ</Link>
          <Link href="/#contact" onClick={() => setMenuOpen(false)} className="py-2 border-b border-[#e0e8e1]">যোগাযোগ</Link>
          {dashPath ? (
            <Link href={dashPath} className="py-2.5 rounded-full bg-[#1B5E20] text-white text-center text-xs font-semibold mt-1">
              ড্যাশবোর্ড
            </Link>
          ) : (
            <div className="flex flex-col gap-2 mt-1">
              <Link href="/register" className="py-2.5 rounded-full border border-[#1B5E20] text-[#1B5E20] text-center text-xs font-semibold">
                নিবন্ধন করুন
              </Link>
              <Link href="/login" className="py-2.5 rounded-full bg-[#1B5E20] text-white text-center text-xs font-semibold">
                লগইন করুন
              </Link>
            </div>
          )}
        </div>
      )}
    </header>
  )
}
