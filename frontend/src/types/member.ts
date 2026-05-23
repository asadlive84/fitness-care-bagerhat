export interface Member {
  id: string
  name: string
  phone: string
  gender: string
  status: string
  goal?: string
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
  join_date?: string
  profile_picture?: string
  diet_chart?: Record<string, unknown>
  bmi?: number
  age?: number
}

export interface Subscription {
  id: string
  plan_name: string
  billing_type: 'prepaid' | 'postpaid'
  start_date: string
  end_date: string
  final_price: number
  money_paid: number
  money_left: number
  note?: string
  billing_status: string
  days_until_due?: number
  prepaid_due_date?: string
  payment_window_start?: string
  payment_window_end?: string
}

export interface Payment {
  id: string
  amount: number
  paid_at: string
  method?: string
  note?: string
}

export interface WeightLog {
  id: string
  weight_kg: number
  logged_at: string
  note?: string
}

export interface WorkoutLog {
  id: string
  exercise_name: string
  sets?: number
  reps?: number
  duration_minutes?: number
  logged_at: string
  note?: string
}

export interface DietLog {
  id: string
  meal_type: string
  food_items: string
  calories?: number
  logged_at: string
  note?: string
}

export interface ChatMessage {
  id: string
  content: string
  sender_role: 'admin' | 'member'
  sent_at: string
  is_broadcast: boolean
}
