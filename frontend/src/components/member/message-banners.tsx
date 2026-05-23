'use client'

import { useState, useEffect, useRef } from 'react'
import { ChatText, Megaphone, X } from '@phosphor-icons/react'
import type { ChatMessage } from '@/types/member'
import Link from 'next/link'

interface Props { messages: ChatMessage[] }

export function MessageBanners({ messages }: Props) {
  const [dismissed, setDismissed] = useState<Set<string>>(new Set())
  const visible = messages.filter((m) => !dismissed.has(m.id))
  if (visible.length === 0) return null

  return (
    <div className="space-y-2">
      {visible.map((msg) => (
        <Banner
          key={msg.id}
          message={msg}
          onDismiss={() => setDismissed((s) => new Set(s).add(msg.id))}
        />
      ))}
    </div>
  )
}

function Banner({ message, onDismiss }: { message: ChatMessage; onDismiss: () => void }) {
  const isBroadcast = message.is_broadcast
  const ref = useRef<HTMLSpanElement>(null)
  const [offset, setOffset] = useState(0)

  useEffect(() => {
    const el = ref.current
    if (!el) return
    const textW = el.scrollWidth
    const containerW = el.parentElement?.clientWidth ?? 300
    if (textW <= containerW) return

    let frame: number
    let pos = containerW
    const speed = 0.6 // px per frame

    function tick() {
      pos -= speed
      if (pos < -textW) pos = containerW
      setOffset(pos)
      frame = requestAnimationFrame(tick)
    }
    frame = requestAnimationFrame(tick)
    return () => cancelAnimationFrame(frame)
  }, [])

  const content = (
    <div className={`flex items-center gap-2 h-10 rounded-xl border px-3 overflow-hidden ${
      isBroadcast
        ? 'bg-orange-50 border-orange-200'
        : 'bg-green-50 border-green-200'
    }`}>
      {isBroadcast
        ? <Megaphone size={14} className="text-orange-500 shrink-0" />
        : <ChatText  size={14} className="text-green-600 shrink-0" />
      }
      <div className="flex-1 overflow-hidden relative h-full flex items-center">
        <span
          ref={ref}
          className={`text-xs font-medium whitespace-nowrap ${isBroadcast ? 'text-orange-700' : 'text-green-700'}`}
          style={{ transform: `translateX(${offset}px)` }}
        >
          {message.content}
        </span>
      </div>
      <button
        onClick={(e) => { e.preventDefault(); onDismiss() }}
        className={`shrink-0 p-0.5 rounded hover:bg-black/5 transition-colors ${isBroadcast ? 'text-orange-400' : 'text-green-500'}`}
      >
        <X size={12} />
      </button>
    </div>
  )

  if (isBroadcast) return content
  return <Link href="/member/messages">{content}</Link>
}
