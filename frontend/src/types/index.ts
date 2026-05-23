export type Role = 'member' | 'admin' | 'superadmin'

export interface JWTPayload {
  user_id: string
  role: Role
  exp: number
}

export interface ApiResponse<T> {
  success: boolean
  data?: T
  error?: {
    code: string
    message: string
    details?: Record<string, string>
  }
}

export interface LoginResponse {
  token: string
  role: Role
  must_change_password?: boolean
}
