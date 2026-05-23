'use client'

import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts'
import type { WeightLog } from '@/types/member'

interface Props { logs: WeightLog[] }

export function WeightChart({ logs }: Props) {
  const data = logs.slice(-12).map((l) => ({
    date: new Date(l.logged_at).toLocaleDateString('en-GB', { day: 'numeric', month: 'short' }),
    kg: l.weight_kg,
  }))

  return (
    <div className="bg-card border border-border rounded-2xl p-4">
      <p className="text-sm font-semibold mb-3">Weight Journey</p>
      <ResponsiveContainer width="100%" height={140}>
        <LineChart data={data} margin={{ top: 4, right: 4, bottom: 0, left: -20 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
          <XAxis dataKey="date" tick={{ fontSize: 10, fill: '#94a3b8' }} axisLine={false} tickLine={false} />
          <YAxis tick={{ fontSize: 10, fill: '#94a3b8' }} axisLine={false} tickLine={false} domain={['auto', 'auto']} />
          <Tooltip
            contentStyle={{ fontSize: 12, borderRadius: 8, border: '1px solid #e2e8f0' }}
            formatter={(v) => [`${v} kg`, 'Weight']}
          />
          <Line
            type="monotone"
            dataKey="kg"
            stroke="#22c55e"
            strokeWidth={2}
            dot={{ fill: '#22c55e', r: 3 }}
            activeDot={{ r: 5 }}
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  )
}
