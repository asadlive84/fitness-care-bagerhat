import type { Subscription, Payment, WeightLog, WorkoutLog, DietLog, ChatMessage } from './member'

export interface AdminMember {
  id: string
  name: string
  phone: string
  gender: string
  status: 'active' | 'inactive' | 'pending' | 'rejected'
  email?: string
  join_date?: string
  current_weight?: number
  height_cm?: number
  date_of_birth?: string
  religion?: string
  blood_group?: string
  hobbies?: string[]
  present_address?: string
  permanent_address?: string
  occupation?: string
  nid?: string
  emergency_phone?: string
  goal?: string
  profile_picture?: string
  bmi?: number
  age?: number
  budget_level?: string
  is_ai_allowed?: boolean
  is_ai_food_log_allowed?: boolean
  active_subscription?: Subscription
  diet_chart?: Record<string, unknown>
  pending_diet_chart?: Record<string, unknown>
  diet_chart_json?: Record<string, unknown>
  pending_diet_chart_json?: Record<string, unknown>
}

export interface Plan {
  id: string
  name: string
  default_price: number
  duration_days: number
  billing_type: 'prepaid' | 'postpaid'
  is_public: boolean
  member_count?: number
  created_at?: string
}

export interface PlanSubscriber {
  member_id: string
  member_name: string
  start_date: string
  end_date: string
  final_price: number
  money_left: number
  billing_status: string
}

export interface PlanWithSubscribers extends Plan {
  subscribers: PlanSubscriber[]
}

export interface PaymentSummary {
  total_amount: number
  payment_count: number
  month: string
}

export interface AdminPayment {
  id: string
  member_id: string
  subscription_id: string
  amount: number
  method: string
  paid_at: string
  created_at: string
  member_name?: string
}

export interface Conversation {
  member_id: string
  member_name?: string
  last_message: string
  last_sent_at: string
  sender_role: 'admin' | 'member'
}

export interface Setting {
  key: string
  value: unknown
  description?: string
}

export interface MembersPage {
  data: AdminMember[]
  meta?: { total: number; page: number; limit: number }
}

// Re-export for convenience
export type { Subscription, Payment, WeightLog, WorkoutLog, DietLog, ChatMessage }
