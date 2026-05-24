import { useQuery, useMutation, useQueryClient, keepPreviousData } from '@tanstack/react-query'
import { api } from '@/lib/api'
import type { ApiResponse } from '@/types'
import type {
  AdminMember, Plan, PlanWithSubscribers, PaymentSummary, AdminPayment,
  Conversation, Setting, MembersPage, Subscription,
} from '@/types/admin'
import type { ChatMessage } from '@/types/member'

const BASE = '/api/v1/admin'

// ── Members ───────────────────────────────────────────────────────────────────

export function useAdminMembers(params: { page?: number; search?: string; status?: string } = {}) {
  return useQuery({
    queryKey: ['admin', 'members', params],
    queryFn: async () => {
      const { data } = await api.get<{ success: boolean; data: AdminMember[]; meta?: { total: number; page: number; limit: number } }>(
        `${BASE}/members`,
        { params: { page: params.page ?? 1, ...(params.search ? { search: params.search } : {}), ...(params.status && params.status !== 'all' ? { status: params.status } : {}) } },
      )
      return { data: data.data ?? [], meta: data.meta } as MembersPage
    },
    placeholderData: keepPreviousData,
  })
}

export function useAdminMember(id: string) {
  return useQuery({
    queryKey: ['admin', 'members', id],
    queryFn: async () => {
      const { data } = await api.get<ApiResponse<AdminMember>>(`${BASE}/members/${id}`)
      return data.data!
    },
    enabled: !!id,
  })
}

export function useCreateMember() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (payload: Record<string, unknown>) => {
      const { data } = await api.post<{ success: boolean; data: { member: AdminMember; temp_password: string } }>(
        `${BASE}/members`, payload,
      )
      return data.data
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin', 'members'] }),
  })
}

export function useUpdateMember(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (payload: Partial<AdminMember>) => {
      const { data } = await api.patch<ApiResponse<AdminMember>>(`${BASE}/members/${id}`, payload)
      return data.data!
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin', 'members'] })
      qc.invalidateQueries({ queryKey: ['admin', 'members', id] })
    },
  })
}

export function useUpdateMemberStatus(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (status: 'active' | 'inactive') => {
      await api.patch(`${BASE}/members/${id}/status`, { status })
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin', 'members'] }),
  })
}

export function useDeleteMember() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (id: string) => { await api.delete(`${BASE}/members/${id}`) },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin', 'members'] }),
  })
}

export function useResetPassword() {
  return useMutation({
    mutationFn: async (id: string) => {
      const { data } = await api.post<{ success: boolean; data: { temp_password: string } }>(
        `${BASE}/members/${id}/password/reset`,
      )
      return data.data.temp_password
    },
  })
}

export function useApproveMember() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (id: string) => {
      const { data } = await api.post<{ success: boolean; data: { member: AdminMember; temp_password: string } }>(
        `${BASE}/members/${id}/approve`,
      )
      return data.data
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin', 'members'] }),
  })
}

export function useRejectMember() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (id: string) => {
      await api.post(`${BASE}/members/${id}/reject`)
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin', 'members'] }),
  })
}

export function usePendingMembersCount(enabled = true) {
  return useQuery({
    queryKey: ['admin', 'members', 'pending-count'],
    queryFn: async () => {
      const { data } = await api.get<{ success: boolean; data: AdminMember[]; meta?: { total: number } }>(
        `${BASE}/members`,
        { params: { status: 'pending', limit: 1 } },
      )
      return data.meta?.total ?? 0
    },
    enabled,
    refetchInterval: 60_000,
  })
}

export function useGenerateDietChart(memberId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (language: 'bn' | 'en') => {
      const { data } = await api.post(`${BASE}/members/${memberId}/diet-chart?language=${language}`)
      return data
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin', 'members', memberId] }),
  })
}

export function useApproveDietChart(memberId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async () => {
      await api.post(`${BASE}/members/${memberId}/diet-chart/approve`)
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin', 'members', memberId] }),
  })
}

export function useDeclineDietChart(memberId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async () => {
      await api.post(`${BASE}/members/${memberId}/diet-chart/decline`)
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin', 'members', memberId] }),
  })
}

// ── Member subscriptions ──────────────────────────────────────────────────────

export function useMemberSubscriptions(memberId: string) {
  return useQuery({
    queryKey: ['admin', 'members', memberId, 'subscriptions'],
    queryFn: async () => {
      const { data } = await api.get<ApiResponse<Subscription[]>>(`${BASE}/members/${memberId}/subscriptions`)
      return data.data ?? []
    },
    enabled: !!memberId,
  })
}

export function useAssignPlan(memberId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (payload: Record<string, unknown>) => {
      await api.post(`${BASE}/members/${memberId}/subscriptions`, payload)
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin', 'members', memberId] }),
  })
}

// ── Plans ─────────────────────────────────────────────────────────────────────

export function useAdminPlans(params: { month?: string } = {}) {
  return useQuery({
    queryKey: ['admin', 'plans', params],
    queryFn: async () => {
      const { data } = await api.get<{ success: boolean; data: PlanWithSubscribers[] | { plans: PlanWithSubscribers[] } }>(
        `${BASE}/plans`, { params },
      )
      const raw = data.data
      if (Array.isArray(raw)) return raw
      if (raw && 'plans' in raw) return raw.plans
      return [] as PlanWithSubscribers[]
    },
  })
}

export function useCreatePlan() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (payload: Omit<Plan, 'id' | 'member_count' | 'created_at'>) => {
      const { data } = await api.post<ApiResponse<Plan>>(`${BASE}/plans`, payload)
      return data.data!
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin', 'plans'] }),
  })
}

export function useUpdatePlan(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (payload: Partial<Plan>) => {
      const { data } = await api.patch<ApiResponse<Plan>>(`${BASE}/plans/${id}`, payload)
      return data.data!
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin', 'plans'] }),
  })
}

export function useDeletePlan() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (id: string) => { await api.delete(`${BASE}/plans/${id}`) },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin', 'plans'] }),
  })
}

// ── Payments ──────────────────────────────────────────────────────────────────

export function usePaymentSummary(month: string) {
  return useQuery({
    queryKey: ['admin', 'payments', 'summary', month],
    queryFn: async () => {
      const { data } = await api.get<ApiResponse<PaymentSummary>>(`${BASE}/payments/summary`, { params: { month } })
      return data.data!
    },
  })
}

export function useRecordPayment() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (payload: { member_id: string; amount: number; method: string; note?: string }) => {
      await api.post(`${BASE}/payments`, payload)
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin', 'payments'] }),
  })
}

export function useMemberPaymentsAdmin(memberId: string) {
  return useQuery({
    queryKey: ['admin', 'members', memberId, 'payments'],
    queryFn: async () => {
      const { data } = await api.get<ApiResponse<AdminPayment[]>>(`${BASE}/members/${memberId}/payments`)
      return data.data ?? []
    },
    enabled: !!memberId,
  })
}

// ── Messages ──────────────────────────────────────────────────────────────────

export function useConversations() {
  return useQuery({
    queryKey: ['admin', 'conversations'],
    queryFn: async () => {
      const { data } = await api.get<ApiResponse<Conversation[]>>(`${BASE}/messages/conversations`)
      return data.data ?? []
    },
    refetchInterval: 15_000,
  })
}

export function useConversation(memberId: string) {
  return useQuery({
    queryKey: ['admin', 'conversations', memberId],
    queryFn: async () => {
      const { data } = await api.get<ApiResponse<ChatMessage[]>>(`${BASE}/messages/conversations/${memberId}`)
      return data.data ?? []
    },
    enabled: !!memberId,
    refetchInterval: 8_000,
  })
}

export function useSendDirect() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async ({ memberId, content }: { memberId: string; content: string }) => {
      await api.post(`${BASE}/messages/direct`, { member_id: memberId, content })
    },
    onSuccess: (_, v) => qc.invalidateQueries({ queryKey: ['admin', 'conversations', v.memberId] }),
  })
}

export function useSendBroadcast() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (payload: { content: string; broadcast_filter: string }) => {
      await api.post(`${BASE}/messages/broadcast`, payload)
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin', 'conversations'] }),
  })
}

// ── Settings ──────────────────────────────────────────────────────────────────

export function useAdminSettings() {
  return useQuery({
    queryKey: ['admin', 'settings'],
    queryFn: async () => {
      const { data } = await api.get<ApiResponse<Setting[]>>(`${BASE}/settings`)
      return data.data ?? []
    },
  })
}

export function useUpsertSetting() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async ({ key, value }: { key: string; value: unknown }) => {
      await api.patch(`${BASE}/settings`, { key, value })
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin', 'settings'] }),
  })
}
