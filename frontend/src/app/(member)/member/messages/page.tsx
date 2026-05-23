'use client'

import { useState, useRef, useEffect } from 'react'
import { useMemberMessages, useSendMessage } from '@/hooks/use-member'
import { Skeleton } from '@/components/ui/skeleton'
import { Input } from '@/components/ui/input'
import { PaperPlaneRight } from '@phosphor-icons/react'

export default function MemberMessages() {
  const { data: messages = [], isLoading } = useMemberMessages()
  const send = useSendMessage()
  const [text, setText] = useState('')
  const bottomRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  async function handleSend() {
    const t = text.trim()
    if (!t) return
    setText('')
    await send.mutateAsync(t)
  }

  return (
    <div className="flex flex-col h-[calc(100vh-56px)] md:h-[calc(100vh-56px)]">
      {/* Header */}
      <div className="px-4 py-3 border-b border-border bg-card">
        <p className="font-semibold text-sm">Gym Support</p>
        <p className="text-xs text-muted-foreground">Admin · usually replies within an hour</p>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-4 space-y-3">
        {isLoading
          ? Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className={`flex ${i % 2 === 0 ? 'justify-end' : 'justify-start'}`}>
                <Skeleton className="h-10 w-48 rounded-2xl" />
              </div>
            ))
          : messages.length === 0
            ? <p className="text-center text-sm text-muted-foreground pt-12">No messages yet. Say hello!</p>
            : messages.map((msg) => {
                const isMe = msg.sender_role === 'member'
                return (
                  <div key={msg.id} className={`flex ${isMe ? 'justify-end' : 'justify-start'}`}>
                    <div className={`max-w-[75%] px-4 py-2.5 rounded-2xl text-sm leading-relaxed ${
                      isMe
                        ? 'bg-primary text-white rounded-br-sm'
                        : 'bg-card border border-border text-foreground rounded-bl-sm'
                    }`}>
                      <p>{msg.content}</p>
                      <p className={`text-[10px] mt-1 ${isMe ? 'text-white/60 text-right' : 'text-muted-foreground'}`}>
                        {new Date(msg.sent_at).toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' })}
                      </p>
                    </div>
                  </div>
                )
              })
        }
        <div ref={bottomRef} />
      </div>

      {/* Input bar */}
      <div className="px-4 py-3 border-t border-border bg-card flex gap-2 items-center pb-safe">
        <Input
          value={text}
          onChange={(e) => setText(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && !e.shiftKey && handleSend()}
          placeholder="Type a message…"
          className="flex-1 h-10 rounded-full bg-muted border-0 focus-visible:ring-1"
        />
        <button
          onClick={handleSend}
          disabled={!text.trim() || send.isPending}
          className="w-10 h-10 rounded-full bg-primary flex items-center justify-center disabled:opacity-50 transition-opacity shrink-0"
        >
          <PaperPlaneRight size={16} weight="fill" className="text-white" />
        </button>
      </div>
    </div>
  )
}
