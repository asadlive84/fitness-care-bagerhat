import { useQuery } from '@tanstack/react-query'
import { api } from '@/lib/api'
import type { ApiResponse } from '@/types'

const SA = '/api/v1/superadmin'

export interface AIAuditLog {
  id:                number
  member_id:         string
  admin_id:          string
  prompt_type:       string
  prompt_text:       string
  ai_response_json:  unknown
  prompt_tokens:     number
  completion_tokens: number
  total_tokens:      number
  estimated_cost:    number | string
  created_at:        string
}

export interface AuditPage {
  data: AIAuditLog[]
  meta?: { page: number; limit: number; total: number }
}

export interface AICostByGymRow {
  admin_id:         string
  admin_name:       string
  total_executions: number
  total_tokens:     number
  total_cost:       number
}

export interface AIHeavyUserRow {
  member_id:   string
  member_name: string
  admin_id:    string
  admin_name:  string
  total_calls: number
  total_tokens: number
  total_cost:  number
}

interface AuditFilters {
  admin_id?:    string
  member_id?:   string
  prompt_type?: string
  from?:        string
  to?:          string
  page?:        number
  limit?:       number
}

export function useAIAuditLogs(filters: AuditFilters = {}) {
  return useQuery({
    queryKey: ['sa', 'audit', 'ai', filters],
    queryFn: async () => {
      const { data } = await api.get<{ success: boolean; data: AIAuditLog[]; meta?: { page: number; limit: number; total: number } }>(
        `${SA}/audit/ai`,
        { params: { ...filters, page: filters.page ?? 1, limit: filters.limit ?? 20 } },
      )
      return { data: data.data ?? [], meta: data.meta } as AuditPage
    },
  })
}

export function useAICostByGym(params: { from?: string; to?: string } = {}) {
  return useQuery({
    queryKey: ['sa', 'audit', 'ai', 'cost-by-gym', params],
    queryFn: async () => {
      const { data } = await api.get<ApiResponse<AICostByGymRow[]>>(`${SA}/audit/ai/cost-by-gym`, { params })
      return data.data ?? []
    },
  })
}

export function useAIHeavyUsers(params: { from?: string; to?: string; threshold?: number; limit?: number } = {}) {
  return useQuery({
    queryKey: ['sa', 'audit', 'ai', 'heavy', params],
    queryFn: async () => {
      const { data } = await api.get<ApiResponse<AIHeavyUserRow[]>>(`${SA}/audit/ai/heavy-users`, { params })
      return data.data ?? []
    },
  })
}
