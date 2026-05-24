import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '@/lib/api'
import type { ApiResponse } from '@/types'
import type { AdminMember } from '@/types/admin'

const ADMIN = '/api/v1/admin'

// ── Diet chart (admin → member) ───────────────────────────────────────────────

export interface GenerateDietChartParams {
  gym_time?: string
  location?: string
  max_budget_bdt?: string
  language?: string
}

export function useGenerateDietChart(memberId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (params: GenerateDietChartParams = {}) => {
      const { data } = await api.post<ApiResponse<unknown>>(
        `${ADMIN}/members/${memberId}/diet-chart`,
        { language: 'bn', ...params },
      )
      return data.data
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin', 'members', memberId] }),
  })
}

export function useApproveDietChart(memberId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async () => {
      await api.post(`${ADMIN}/members/${memberId}/diet-chart/approve`)
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin', 'members', memberId] }),
  })
}

export function useDeclineDietChart(memberId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async () => {
      await api.post(`${ADMIN}/members/${memberId}/diet-chart/decline`)
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin', 'members', memberId] }),
  })
}

// ── AI settings (admin toggle per member) ────────────────────────────────────

export function useUpdateMemberAI(memberId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (payload: {
      is_ai_allowed: boolean
      is_ai_food_log_allowed?: boolean
      budget_level?: string
    }) => {
      const { data } = await api.patch<ApiResponse<AdminMember>>(
        `${ADMIN}/members/${memberId}/ai`, payload,
      )
      return data.data!
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin', 'members', memberId] })
      qc.invalidateQueries({ queryKey: ['admin', 'members'] })
    },
  })
}

// ── Profile picture (admin → member) ─────────────────────────────────────────

export function useUpdateMemberProfilePicture(memberId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (profile_picture_url: string) => {
      await api.patch(`${ADMIN}/members/${memberId}/profile-picture`, { profile_picture_url })
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin', 'members', memberId] }),
  })
}

// ── Food logs per member (superadmin inspector) ───────────────────────────────

export interface FoodLog {
  id: string
  member_id: string
  image_url: string
  ai_response_json?: Record<string, unknown>
  created_at: string
}

export function useMemberFoodLogs(memberId: string) {
  return useQuery({
    queryKey: ['admin', 'members', memberId, 'food-logs'],
    queryFn: async () => {
      // Member food logs come from the member's own AI endpoint; admin proxies via the
      // superadmin inspector. For now call the member API scoped by the token.
      const { data } = await api.get<ApiResponse<FoodLog[]>>(
        `/api/v1/ai/food-logs`,
        { params: { member_id: memberId, limit: 50 } },
      )
      return data.data ?? []
    },
    enabled: !!memberId,
  })
}
