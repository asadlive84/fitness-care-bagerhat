/**
 * SuperAdmin uses the same admin API surface for now. A dedicated
 * /api/v1/superadmin route group will be added to the backend in a later step.
 * Until then, we call admin endpoints with the superadmin JWT (same structure).
 */

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '@/lib/api'
import type { ApiResponse } from '@/types'
import type { AdminMember, Subscription, AdminPayment } from '@/types/admin'
import type { WeightLog, WorkoutLog, DietLog, ChatMessage } from '@/types/member'

const ADMIN = '/api/v1/admin'

// ── Re-exports wrapped with superadmin query keys ─────────────────────────────

export function useSAMembers(params: { page?: number; search?: string; status?: string } = {}) {
  return useQuery({
    queryKey: ['sa', 'members', params],
    queryFn: async () => {
      const { data } = await api.get<{ success: boolean; data: AdminMember[]; meta?: { total: number; page: number; limit: number } }>(
        `${ADMIN}/members`,
        { params: { page: params.page ?? 1, ...(params.search ? { search: params.search } : {}), ...(params.status && params.status !== 'all' ? { status: params.status } : {}) } },
      )
      return { data: data.data ?? [], meta: data.meta }
    },
  })
}

export function useSAMember(id: string) {
  return useQuery({
    queryKey: ['sa', 'members', id],
    queryFn: async () => {
      const { data } = await api.get<ApiResponse<AdminMember>>(`${ADMIN}/members/${id}`)
      return data.data!
    },
    enabled: !!id,
  })
}

export function useSAMemberMessages(memberId: string) {
  return useQuery({
    queryKey: ['sa', 'members', memberId, 'messages'],
    queryFn: async () => {
      const { data } = await api.get<ApiResponse<ChatMessage[]>>(
        `${ADMIN}/messages/conversations/${memberId}`,
      )
      return data.data ?? []
    },
    enabled: !!memberId,
  })
}

export function useSAMemberSubscriptions(memberId: string) {
  return useQuery({
    queryKey: ['sa', 'members', memberId, 'subscriptions'],
    queryFn: async () => {
      const { data } = await api.get<ApiResponse<Subscription[]>>(
        `${ADMIN}/members/${memberId}/subscriptions`,
      )
      return data.data ?? []
    },
    enabled: !!memberId,
  })
}

export function useSAMemberPayments(memberId: string) {
  return useQuery({
    queryKey: ['sa', 'members', memberId, 'payments'],
    queryFn: async () => {
      const { data } = await api.get<ApiResponse<AdminPayment[]>>(
        `${ADMIN}/members/${memberId}/payments`,
      )
      return data.data ?? []
    },
    enabled: !!memberId,
  })
}

export function useSAMemberWeightLogs(memberId: string) {
  return useQuery({
    queryKey: ['sa', 'members', memberId, 'weight-logs'],
    // Weight logs are on the member API, scoped by the JWT. In a real superadmin
    // setup the backend would expose GET /superadmin/members/:id/weight-logs.
    // Until that route exists we mark it as pending.
    queryFn: async () => [] as WeightLog[],
    enabled: false,
  })
}

export function useSAMemberWorkoutLogs(memberId: string) {
  return useQuery({
    queryKey: ['sa', 'members', memberId, 'workout-logs'],
    queryFn: async () => [] as WorkoutLog[],
    enabled: false,
  })
}

export function useSAMemberDietLogs(memberId: string) {
  return useQuery({
    queryKey: ['sa', 'members', memberId, 'diet-logs'],
    queryFn: async () => [] as DietLog[],
    enabled: false,
  })
}

// ── Disable / delete member ───────────────────────────────────────────────────

export function useSADisableMember() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async ({ id, status }: { id: string; status: 'active' | 'inactive' }) => {
      await api.patch(`${ADMIN}/members/${id}/status`, { status })
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['sa', 'members'] }),
  })
}

export function useSADeleteMember() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (id: string) => { await api.delete(`${ADMIN}/members/${id}`) },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['sa', 'members'] }),
  })
}

export function useSAResetPassword() {
  return useMutation({
    mutationFn: async (id: string) => {
      const { data } = await api.post<{ success: boolean; data: { temp_password: string } }>(
        `${ADMIN}/members/${id}/password/reset`,
      )
      return data.data.temp_password
    },
  })
}

// ── Toggle AI per member ──────────────────────────────────────────────────────

export function useSAToggleAI() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async ({ id, is_ai_allowed }: { id: string; is_ai_allowed: boolean }) => {
      await api.patch(`${ADMIN}/members/${id}/ai`, {
        is_ai_allowed,
        is_ai_food_log_allowed: is_ai_allowed,
      })
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['sa', 'members'] }),
  })
}

// ── Stats helpers ─────────────────────────────────────────────────────────────

export function useSAStats() {
  return useQuery({
    queryKey: ['sa', 'stats'],
    queryFn: async () => {
      const month = new Date().toISOString().slice(0, 7)
      const [membersRes, paymentRes] = await Promise.all([
        api.get<{ success: boolean; data: AdminMember[]; meta?: { total: number } }>(`${ADMIN}/members`, { params: { status: 'all', page: 1 } }),
        api.get<ApiResponse<{ total_amount: number; payment_count: number }>>(`${ADMIN}/payments/summary`, { params: { month } }),
      ])
      const total    = membersRes.data.meta?.total ?? membersRes.data.data?.length ?? 0
      const revenue  = paymentRes.data.data?.total_amount ?? 0
      const aiCount  = membersRes.data.data?.filter((m) => m.is_ai_allowed).length ?? 0
      return { total, revenue, aiCount, month }
    },
  })
}
