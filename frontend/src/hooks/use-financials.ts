import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '@/lib/api'
import type { ApiResponse } from '@/types'

const ADMIN = '/api/v1/admin'

export interface Expense {
  id: string
  amount: number
  description: string
  category: string
  spent_at: string
  recorded_by: string
  created_at: string
  updated_at?: string
}

export interface ExpensesSummary {
  today_total:     number
  yesterday_total: number
  month_total:     number
}

export interface RevenueByMethod   { payment_method: string; total_amount: number; transaction_count: number }
export interface RevenueByPlan     { plan_name: string; plan_price: number; total_amount: number; transaction_count: number }
export interface ExpenseByCategory { category: string; total_amount: number; expense_count: number }
export interface TimelinePoint     { date: string; earnings: number; expenses: number; net: number }

export interface FinancialsReport {
  start_date:           string
  end_date:             string
  total_income:         number
  total_cost:           number
  net_profit:           number
  revenue_by_method:    RevenueByMethod[]
  revenue_by_plan:      RevenueByPlan[]
  expenses_by_category: ExpenseByCategory[]
  timeline:             TimelinePoint[]
}

// ── Expenses ──────────────────────────────────────────────────────────────────

export function useExpenses(params: { page?: number; from?: string; to?: string; category?: string } = {}) {
  return useQuery({
    queryKey: ['admin', 'expenses', params],
    queryFn: async () => {
      const { data } = await api.get<ApiResponse<Expense[]>>(`${ADMIN}/expenses`, {
        params: { page: params.page ?? 1, ...(params.from ? { from: params.from } : {}), ...(params.to ? { to: params.to } : {}), ...(params.category ? { category: params.category } : {}) },
      })
      return data.data ?? []
    },
  })
}

export function useExpensesSummary() {
  return useQuery({
    queryKey: ['admin', 'expenses', 'summary'],
    queryFn: async () => {
      const { data } = await api.get<ApiResponse<ExpensesSummary>>(`${ADMIN}/expenses/summary`)
      return data.data ?? { today_total: 0, yesterday_total: 0, month_total: 0 }
    },
  })
}

export function useRecordExpense() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (payload: { amount: number; description: string; category: string; spent_at?: string }) => {
      await api.post(`${ADMIN}/expenses`, payload)
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin', 'expenses'] })
      qc.invalidateQueries({ queryKey: ['admin', 'financials'] })
    },
  })
}

// ── Financials report ─────────────────────────────────────────────────────────

export function useFinancialsReport(params: { from?: string; to?: string } = {}) {
  return useQuery({
    queryKey: ['admin', 'financials', 'report', params],
    queryFn: async () => {
      const { data } = await api.get<ApiResponse<FinancialsReport>>(`${ADMIN}/financials/report`, { params })
      return data.data ?? null
    },
    enabled: !!params.from && !!params.to,
  })
}

export function useFinancialsCalendar(month: string) {
  return useQuery({
    queryKey: ['admin', 'financials', 'calendar', month],
    queryFn: async () => {
      const { data } = await api.get<ApiResponse<TimelinePoint[]>>(`${ADMIN}/financials/calendar`, { params: { month } })
      return data.data ?? []
    },
  })
}

// ── SuperAdmin: provision a new gym admin via M2M ────────────────────────────

export function useProvisionGymAdmin(apiKey: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (payload: { name: string; email: string; phone?: string; password: string }) => {
      const { data } = await api.post<ApiResponse<{ id: string; name: string; email: string; phone?: string }>>(
        '/api/v1/sa/admins',
        payload,
        { headers: { 'X-API-KEY': apiKey } },
      )
      return data.data!
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['sa', 'admins'] })
      qc.invalidateQueries({ queryKey: ['superadmin', 'admins'] })
    },
  })
}
