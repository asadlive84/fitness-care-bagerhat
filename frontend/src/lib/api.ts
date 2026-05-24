import axios from 'axios'
import { getToken, setToken, setRefreshToken, getRefreshToken, clearAllTokens } from '@/lib/auth'

const BASE = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:9000'

export const api = axios.create({
  baseURL: BASE,
  headers: { 'Content-Type': 'application/json' },
})

// Attach access token from localStorage
api.interceptors.request.use((config) => {
  if (typeof window !== 'undefined') {
    const token = getToken()
    if (token) config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// Silent token refresh on 401 — queues concurrent requests until refresh completes
let isRefreshing = false
let pendingQueue: Array<{ resolve: (token: string) => void; reject: (err: unknown) => void }> = []

function drainQueue(err: unknown, token: string | null) {
  pendingQueue.forEach(p => (token ? p.resolve(token) : p.reject(err)))
  pendingQueue = []
}

api.interceptors.response.use(
  (res) => res,
  async (err) => {
    const original = err.config

    // Not a 401, or already retried, or the refresh call itself failed → bail out
    if (err.response?.status !== 401 || original._retry || original.url?.includes('/auth/refresh')) {
      return Promise.reject(err)
    }

    if (isRefreshing) {
      // Another request is already refreshing — queue this one
      return new Promise((resolve, reject) => {
        pendingQueue.push({
          resolve: (token) => {
            original.headers.Authorization = `Bearer ${token}`
            resolve(api(original))
          },
          reject,
        })
      })
    }

    original._retry = true
    isRefreshing = true

    const refreshToken = getRefreshToken()
    if (!refreshToken) {
      isRefreshing = false
      if (typeof window !== 'undefined') {
        clearAllTokens()
        window.location.href = '/'
      }
      return Promise.reject(err)
    }

    try {
      const { data } = await axios.post(`${BASE}/api/v1/auth/refresh`, {
        refresh_token: refreshToken,
      })
      const newAccess: string = data.data.access_token
      const newRefresh: string = data.data.refresh_token

      setToken(newAccess)
      setRefreshToken(newRefresh)
      document.cookie = `fc_token=${newAccess}; path=/; max-age=${60 * 60 * 24 * 7}; SameSite=Lax`

      api.defaults.headers.common.Authorization = `Bearer ${newAccess}`
      drainQueue(null, newAccess)

      original.headers.Authorization = `Bearer ${newAccess}`
      return api(original)
    } catch (refreshErr) {
      drainQueue(refreshErr, null)
      if (typeof window !== 'undefined') {
        clearAllTokens()
        window.location.href = '/'
      }
      return Promise.reject(refreshErr)
    } finally {
      isRefreshing = false
    }
  },
)
