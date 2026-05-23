'use client'

import { SunHorizon, Sun, Moon, Cookie, Plant } from '@phosphor-icons/react'

interface Meal {
  name: string
  time?: string
  foods?: string[]
  calories?: number
  items?: string[]
}

interface DietChart {
  daily_calories?: number
  macros?: { protein?: number; carbs?: number; fats?: number }
  meals?: Meal[]
  notes?: string
}

const MEAL_ICONS: Record<string, React.ReactNode> = {
  breakfast: <SunHorizon size={14} />,
  lunch:     <Sun size={14} />,
  dinner:    <Moon size={14} />,
  snack:     <Cookie size={14} />,
}

function mealIcon(name: string) {
  const key = name.toLowerCase()
  for (const k of Object.keys(MEAL_ICONS)) if (key.includes(k)) return MEAL_ICONS[k]
  return <Plant size={14} />
}

interface Props {
  chart: Record<string, unknown>
  label?: string
  variant?: 'default' | 'pending'
}

export function DietChartView({ chart, label, variant = 'default' }: Props) {
  const c = chart as DietChart
  const meals = c.meals ?? []

  const borderClass = variant === 'pending'
    ? 'border-amber-300 bg-amber-50'
    : 'border-green-200 bg-green-50/40'

  return (
    <div className={`rounded-2xl border p-4 space-y-3 ${borderClass}`}>
      {label && (
        <div className="flex items-center gap-2">
          <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ${
            variant === 'pending' ? 'bg-amber-200 text-amber-800' : 'bg-green-200 text-green-800'
          }`}>{label}</span>
        </div>
      )}

      {/* Macro summary */}
      {(c.daily_calories || c.macros) && (
        <div className="grid grid-cols-4 gap-2">
          {c.daily_calories && (
            <div className="bg-white rounded-xl p-2 text-center border border-border">
              <p className="text-base font-bold text-primary">{c.daily_calories}</p>
              <p className="text-[10px] text-muted-foreground">kcal</p>
            </div>
          )}
          {c.macros?.protein !== undefined && (
            <div className="bg-white rounded-xl p-2 text-center border border-border">
              <p className="text-base font-bold">{c.macros.protein}g</p>
              <p className="text-[10px] text-muted-foreground">protein</p>
            </div>
          )}
          {c.macros?.carbs !== undefined && (
            <div className="bg-white rounded-xl p-2 text-center border border-border">
              <p className="text-base font-bold">{c.macros.carbs}g</p>
              <p className="text-[10px] text-muted-foreground">carbs</p>
            </div>
          )}
          {c.macros?.fats !== undefined && (
            <div className="bg-white rounded-xl p-2 text-center border border-border">
              <p className="text-base font-bold">{c.macros.fats}g</p>
              <p className="text-[10px] text-muted-foreground">fats</p>
            </div>
          )}
        </div>
      )}

      {/* Meal list */}
      {meals.length > 0 && (
        <div className="space-y-2">
          {meals.map((meal, i) => {
            const foods = meal.foods ?? meal.items ?? []
            return (
              <div key={i} className="bg-white rounded-xl border border-border p-3">
                <div className="flex items-center gap-2 mb-1">
                  <span className="text-muted-foreground">{mealIcon(meal.name)}</span>
                  <p className="text-sm font-semibold">{meal.name}</p>
                  {meal.time && <span className="text-xs text-muted-foreground ml-auto">{meal.time}</span>}
                  {meal.calories && <span className="text-xs text-amber-600 font-medium">{meal.calories} kcal</span>}
                </div>
                {foods.length > 0 && (
                  <p className="text-xs text-muted-foreground leading-relaxed">
                    {foods.join(' · ')}
                  </p>
                )}
              </div>
            )
          })}
        </div>
      )}

      {c.notes && (
        <p className="text-xs text-muted-foreground italic border-t border-border/50 pt-2">{c.notes}</p>
      )}
    </div>
  )
}
