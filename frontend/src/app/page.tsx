'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { getRole, roleHomePath } from '@/lib/auth'

export default function RootPage() {
  const router = useRouter()
  useEffect(() => {
    const role = getRole()
    router.replace(role ? roleHomePath(role) : '/login')
  }, [router])
  return null
}
