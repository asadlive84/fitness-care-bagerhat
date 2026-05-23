'use client'

import { Shell } from '@/components/layout/shell'
import { useEffect, useState } from 'react'
import { decodeToken, getToken } from '@/lib/auth'

export default function MemberLayout({ children }: { children: React.ReactNode }) {
  const [userName, setUserName] = useState('Member')

  useEffect(() => {
    const token = getToken()
    if (token) {
      const payload = decodeToken(token)
      if (payload?.user_id) setUserName('Member')
    }
  }, [])

  return (
    <Shell role="member" userName={userName}>
      {children}
    </Shell>
  )
}
