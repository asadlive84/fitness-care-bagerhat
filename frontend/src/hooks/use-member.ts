import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '@/lib/api'
import type { ApiResponse } from '@/types'
import type { Member, Subscription, Payment, WeightLog, WorkoutLog, DietLog, ChatMessage } from '@/types/member'

const BASE = '/api/v1/member'

// ── Profile ──────────────────────────────────────────────────────────────────

export function useMemberProfile() {
  return useQuery({
    queryKey: ['member', 'profile'],
    queryFn: async () => {
      const { data } = await api.get<ApiResponse<Member>>(`${BASE}/profile`)
      return data.data!
    },
  })
}

export function useUpdateProfile() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (payload: Partial<Member>) => {
      const { data } = await api.patch<ApiResponse<Member>>(`${BASE}/profile`, payload)
      return data.data!
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['member', 'profile'] }),
  })
}

// ── Subscription ──────────────────────────────────────────────────────────────

export function useMemberSubscription() {
  return useQuery({
    queryKey: ['member', 'subscription'],
    queryFn: async () => {
      try {
        const { data } = await api.get<ApiResponse<Subscription>>(`${BASE}/subscription`)
        return data.data ?? null
      } catch {
        return null
      }
    },
  })
}

// ── Payments ──────────────────────────────────────────────────────────────────

export function useMemberPayments() {
  return useQuery({
    queryKey: ['member', 'payments'],
    queryFn: async () => {
      const { data } = await api.get<ApiResponse<Payment[]>>(`${BASE}/payments`)
      return data.data ?? []
    },
  })
}

// ── Weight logs ───────────────────────────────────────────────────────────────

export function useWeightLogs() {
  return useQuery({
    queryKey: ['member', 'weight-logs'],
    queryFn: async () => {
      const { data } = await api.get<ApiResponse<WeightLog[]>>(`${BASE}/weight-logs`)
      return (data.data ?? []).reverse()
    },
  })
}

export function useLogWeight() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (payload: { weight_kg: number; note?: string }) => {
      await api.post(`${BASE}/weight-logs`, payload)
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['member', 'weight-logs'] }),
  })
}

// ── Workout logs ──────────────────────────────────────────────────────────────

export function useWorkoutLogs() {
  return useQuery({
    queryKey: ['member', 'workout-logs'],
    queryFn: async () => {
      const { data } = await api.get<ApiResponse<WorkoutLog[]>>(`${BASE}/workout-logs`)
      return data.data ?? []
    },
  })
}

export function useLogWorkout() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (payload: Omit<WorkoutLog, 'id' | 'logged_at'>) => {
      await api.post(`${BASE}/workout-logs`, payload)
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['member', 'workout-logs'] }),
  })
}

// ── Diet logs ─────────────────────────────────────────────────────────────────

export function useDietLogs() {
  return useQuery({
    queryKey: ['member', 'diet-logs'],
    queryFn: async () => {
      const { data } = await api.get<ApiResponse<DietLog[]>>(`${BASE}/diet-logs`)
      return data.data ?? []
    },
  })
}

export function useLogDiet() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (payload: Omit<DietLog, 'id' | 'logged_at'>) => {
      await api.post(`${BASE}/diet-logs`, payload)
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['member', 'diet-logs'] }),
  })
}

// ── Messages ──────────────────────────────────────────────────────────────────

export function useMemberMessages() {
  return useQuery({
    queryKey: ['member', 'messages'],
    queryFn: async () => {
      const { data } = await api.get<ApiResponse<ChatMessage[]>>(`${BASE}/messages`)
      return data.data ?? []
    },
    refetchInterval: 10_000,
  })
}

export function useSendMessage() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (content: string) => {
      await api.post(`${BASE}/messages`, { content })
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['member', 'messages'] }),
  })
}
