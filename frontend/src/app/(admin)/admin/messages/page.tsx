'use client'

import { useState, useRef, useEffect, Suspense } from 'react'
import { useSearchParams } from 'next/navigation'
import { useConversations, useConversation, useSendDirect, useSendBroadcast } from '@/hooks/use-admin'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import { Sheet, SheetContent, SheetHeader, SheetTitle } from '@/components/ui/sheet'
import { PaperPlaneRight, Megaphone, Users, ChatTeardropDots } from '@phosphor-icons/react'
import { cn } from '@/lib/utils'

export default function AdminMessagesPage() {
  return <Suspense><AdminMessages /></Suspense>
}

function AdminMessages() {
  const searchParams  = useSearchParams()
  const [activeId, setActiveId] = useState<string | null>(searchParams.get('id'))
  const [broadcast, setBroadcast] = useState(false)

  const { data: conversations = [], isLoading } = useConversations()

  const unreadConvs  = conversations.filter((c) => c.sender_role === 'member')
  const sortedConvs  = [...unreadConvs, ...conversations.filter((c) => c.sender_role !== 'member')]
    .filter((c, i, a) => a.findIndex((x) => x.member_id === c.member_id) === i)

  return (
    <div className="flex h-[calc(100vh-56px)]">
      {/* Sidebar: conversation list */}
      <div className={cn('flex flex-col border-r border-border bg-card', activeId ? 'hidden md:flex w-72 shrink-0' : 'flex-1 md:w-72 md:flex-none md:shrink-0')}>
        <div className="p-3 border-b border-border flex items-center gap-2">
          <p className="font-semibold text-sm flex-1">Messages</p>
          <button onClick={() => setBroadcast(true)} className="p-1.5 hover:bg-muted rounded-lg transition-colors" title="Broadcast">
            <Megaphone size={16} className="text-accent" />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto">
          {isLoading ? (
            <div className="p-3 space-y-2">{Array.from({ length: 5 }).map((_, i) => <Skeleton key={i} className="h-14 rounded-lg" />)}</div>
          ) : sortedConvs.length === 0 ? (
            <div className="flex flex-col items-center justify-center h-full text-center p-6">
              <ChatTeardropDots size={32} className="text-muted-foreground/40 mb-2" />
              <p className="text-sm text-muted-foreground">No conversations yet.</p>
            </div>
          ) : sortedConvs.map((c) => (
            <button key={c.member_id} onClick={() => setActiveId(c.member_id)}
              className={cn('w-full flex items-center gap-3 px-3 py-3 border-b border-border hover:bg-muted transition-colors text-left', activeId === c.member_id && 'bg-muted')}>
              <div className="w-9 h-9 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
                <span className="text-sm font-bold text-primary">{(c.member_name ?? 'M').charAt(0).toUpperCase()}</span>
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-1">
                  <p className="text-sm font-medium truncate flex-1">{c.member_name ?? `…${c.member_id.slice(-6)}`}</p>
                  {c.sender_role === 'member' && <span className="w-2 h-2 rounded-full bg-primary shrink-0" />}
                </div>
                <p className="text-xs text-muted-foreground truncate">{c.last_message}</p>
              </div>
              <p className="text-[10px] text-muted-foreground shrink-0">
                {new Date(c.last_sent_at).toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' })}
              </p>
            </button>
          ))}
        </div>
      </div>

      {/* Chat view */}
      {activeId ? (
        <ChatPane memberId={activeId} onBack={() => setActiveId(null)} />
      ) : (
        <div className="hidden md:flex flex-1 items-center justify-center text-muted-foreground text-sm">
          Select a conversation to start chatting
        </div>
      )}

      {/* Broadcast sheet */}
      <BroadcastSheet open={broadcast} onClose={() => setBroadcast(false)} />
    </div>
  )
}

// ── Chat pane ─────────────────────────────────────────────────────────────────

function ChatPane({ memberId, onBack }: { memberId: string; onBack: () => void }) {
  const { data: messages = [], isLoading } = useConversation(memberId)
  const send = useSendDirect()
  const [text, setText] = useState('')
  const bottomRef = useRef<HTMLDivElement>(null)

  useEffect(() => { bottomRef.current?.scrollIntoView({ behavior: 'smooth' }) }, [messages])

  async function handleSend() {
    const t = text.trim(); if (!t) return
    setText('')
    await send.mutateAsync({ memberId, content: t })
  }

  return (
    <div className="flex-1 flex flex-col min-w-0">
      {/* Header */}
      <div className="h-12 px-4 border-b border-border bg-card flex items-center gap-3 shrink-0">
        <button onClick={onBack} className="md:hidden p-1 hover:bg-muted rounded-lg"><span className="text-xs">←</span></button>
        <p className="font-semibold text-sm">{memberId.slice(-8)}…</p>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-4 space-y-2">
        {isLoading
          ? Array.from({ length: 3 }).map((_, i) => <Skeleton key={i} className="h-10 w-48 rounded-2xl" />)
          : messages.map((msg) => {
              const isAdmin = msg.sender_role === 'admin'
              return (
                <div key={msg.id} className={`flex ${isAdmin ? 'justify-end' : 'justify-start'}`}>
                  <div className={`max-w-[70%] px-4 py-2.5 rounded-2xl text-sm ${isAdmin ? 'bg-primary text-white rounded-br-sm' : 'bg-card border border-border rounded-bl-sm'}`}>
                    <p>{msg.content}</p>
                    <p className={`text-[10px] mt-1 ${isAdmin ? 'text-white/60 text-right' : 'text-muted-foreground'}`}>
                      {new Date(msg.sent_at).toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' })}
                    </p>
                  </div>
                </div>
              )
            })
        }
        <div ref={bottomRef} />
      </div>

      {/* Input */}
      <div className="px-4 py-3 border-t border-border bg-card flex gap-2 items-center">
        <Input value={text} onChange={(e) => setText(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && !e.shiftKey && handleSend()}
          placeholder="Type a message…" className="flex-1 h-10 rounded-full bg-muted border-0 focus-visible:ring-1" />
        <button onClick={handleSend} disabled={!text.trim() || send.isPending}
          className="w-10 h-10 rounded-full bg-primary flex items-center justify-center disabled:opacity-50 shrink-0">
          <PaperPlaneRight size={16} weight="fill" className="text-white" />
        </button>
      </div>
    </div>
  )
}

// ── Broadcast sheet ───────────────────────────────────────────────────────────

function BroadcastSheet({ open, onClose }: { open: boolean; onClose: () => void }) {
  const send = useSendBroadcast()
  const [content, setContent] = useState('')
  const [filter, setFilter]   = useState('all')

  async function handleSend() {
    if (!content.trim()) return
    await send.mutateAsync({ content: content.trim(), broadcast_filter: filter })
    setContent('')
    onClose()
  }

  return (
    <Sheet open={open} onOpenChange={(o) => !o && onClose()}>
      <SheetContent className="max-w-sm">
        <SheetHeader>
          <SheetTitle className="flex items-center gap-2"><Megaphone size={16} className="text-accent" /> Broadcast Message</SheetTitle>
        </SheetHeader>
        <div className="space-y-4 mt-4">
          <div className="flex items-center gap-2 bg-orange-50 border border-orange-200 rounded-xl px-3 py-2">
            <Users size={14} className="text-orange-500" />
            <p className="text-xs text-orange-700">This will be sent to all selected members.</p>
          </div>
          <div>
            <label className="text-xs text-muted-foreground font-medium">Send To</label>
            <select value={filter} onChange={(e) => setFilter(e.target.value)}
              className="mt-1 h-10 w-full rounded-md border border-input bg-background px-3 text-sm">
              <option value="all">All Members</option>
              <option value="active">Active Members</option>
              <option value="expired">Expired Members</option>
              <option value="expiring">Expiring Soon</option>
            </select>
          </div>
          <div>
            <label className="text-xs text-muted-foreground font-medium">Message</label>
            <textarea value={content} onChange={(e) => setContent(e.target.value)}
              placeholder="Write your broadcast message…"
              className="mt-1 w-full rounded-xl border border-input bg-background px-3 py-2.5 text-sm resize-none h-28 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring" />
          </div>
          <Button onClick={handleSend} disabled={!content.trim() || send.isPending} className="w-full bg-accent text-white hover:bg-accent/90">
            {send.isPending ? 'Sending…' : 'Send Broadcast'}
          </Button>
        </div>
      </SheetContent>
    </Sheet>
  )
}
