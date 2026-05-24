'use client'

import { useState } from 'react'
import { SunHorizon, Sun, Moon, Cookie, Plant, CaretDown, CaretUp, Wallet, Lightbulb, Barbell, Heartbeat } from '@phosphor-icons/react'

// ── Old schema (backward compat) ─────────────────────────────────────────────

interface OldMeal {
  name: string
  time?: string
  foods?: string[]
  calories?: number
  items?: string[]
}

interface OldChart {
  daily_calories?: number
  macros?: { protein?: number; carbs?: number; fats?: number }
  meals?: OldMeal[]
  notes?: string
}

// ── New schema ────────────────────────────────────────────────────────────────

interface FoodItem {
  item_name: string
  quantity?: string
  estimated_price?: string
  price_range?: string
  ingredients_and_nature?: string
  preparation_steps?: string
  nutritional_benefit?: string
}

interface NewMeal {
  meal_name: string
  ideal_time?: string
  estimated_meal_cost_range_bdt?: string
  estimated_meal_calories?: number
  foods?: FoodItem[]
}

interface WorkoutItem {
  exercise_name?: string
  equipment_used?: string
  target_muscle?: string
  sets_and_reps?: string
  form_and_benefit?: string
}

interface NewChart {
  customer_profile?: { name?: string; gender?: string; age?: number; height_cm?: number; weight_kg?: number }
  target_summary?: string
  daily_targets?: { target_calories?: number; protein_g?: number; carbs_g?: number; fat_g?: number }
  detailed_diet_chart?: NewMeal[]
  workout_recommendations?: WorkoutItem[]
  health_and_medical_tips?: string[]
  overall_budget_and_hydration_tips?: string[]
  total_calories?: number
  total_cost?: number
}

// ── Shared helpers ────────────────────────────────────────────────────────────

const MEAL_ICONS: Record<string, React.ReactNode> = {
  breakfast:  <SunHorizon size={14} />,
  সকালের:    <SunHorizon size={14} />,
  lunch:      <Sun size={14} />,
  দুপুরের:   <Sun size={14} />,
  dinner:     <Moon size={14} />,
  রাতের:     <Moon size={14} />,
  snack:      <Cookie size={14} />,
  নাস্তা:    <Cookie size={14} />,
}

function mealIcon(name: string) {
  for (const k of Object.keys(MEAL_ICONS)) if (name.includes(k)) return MEAL_ICONS[k]
  return <Plant size={14} />
}

interface Props {
  chart: Record<string, unknown>
  label?: string
  variant?: 'default' | 'pending'
}

export function DietChartView({ chart, label, variant = 'default' }: Props) {
  const isNew = 'detailed_diet_chart' in chart

  const borderClass = variant === 'pending'
    ? 'border-amber-300 bg-amber-50'
    : 'border-green-200 bg-green-50/40'

  return (
    <div className={`rounded-2xl border p-4 space-y-3 ${borderClass}`}>
      {label && (
        <span className={`text-xs font-semibold px-2 py-0.5 rounded-full inline-block ${
          variant === 'pending' ? 'bg-amber-200 text-amber-800' : 'bg-green-200 text-green-800'
        }`}>{label}</span>
      )}
      {isNew
        ? <NewDietChartBody chart={chart as unknown as NewChart} />
        : <OldDietChartBody chart={chart as unknown as OldChart} />
      }
    </div>
  )
}

// ── New schema renderer ───────────────────────────────────────────────────────

function NewDietChartBody({ chart }: { chart: NewChart }) {
  const targets  = chart.daily_targets
  const meals    = chart.detailed_diet_chart ?? []
  const workouts = chart.workout_recommendations ?? []
  const healthTips = chart.health_and_medical_tips ?? []
  const tips     = chart.overall_budget_and_hydration_tips ?? []

  return (
    <div className="space-y-4">
      {/* Target summary */}
      {chart.target_summary && (
        <p className="text-xs text-muted-foreground leading-relaxed bg-white rounded-xl p-3 border border-border">
          {chart.target_summary}
        </p>
      )}

      {/* Daily targets */}
      {targets && (
        <div className="grid grid-cols-4 gap-2">
          {targets.target_calories !== undefined && (
            <MacroBox value={`${targets.target_calories}`} label="kcal" />
          )}
          {targets.protein_g !== undefined && (
            <MacroBox value={`${targets.protein_g}g`} label="প্রোটিন" />
          )}
          {targets.carbs_g !== undefined && (
            <MacroBox value={`${targets.carbs_g}g`} label="কার্বস" />
          )}
          {targets.fat_g !== undefined && (
            <MacroBox value={`${targets.fat_g}g`} label="ফ্যাট" />
          )}
        </div>
      )}

      {/* Meal list */}
      {meals.length > 0 && (
        <div className="space-y-2">
          {meals.map((meal, i) => <NewMealCard key={i} meal={meal} />)}
        </div>
      )}

      {/* Workout recommendations */}
      {workouts.length > 0 && (
        <div className="bg-white rounded-xl border border-border p-3 space-y-2">
          <div className="flex items-center gap-1.5 mb-1">
            <Barbell size={14} weight="duotone" className="text-primary" />
            <p className="text-xs font-semibold">ওয়ার্কআউট পরিকল্পনা</p>
          </div>
          {workouts.map((w, i) => (
            <div key={i} className="border border-border/60 rounded-lg p-2.5 space-y-0.5">
              <div className="flex items-center justify-between">
                <p className="text-xs font-semibold text-foreground">{w.exercise_name}</p>
                {w.sets_and_reps && <span className="text-[10px] text-amber-600 font-medium">{w.sets_and_reps}</span>}
              </div>
              {w.equipment_used && <p className="text-[10px] text-muted-foreground">🏋️ {w.equipment_used}</p>}
              {w.target_muscle  && <p className="text-[10px] text-primary/70">💪 {w.target_muscle}</p>}
              {w.form_and_benefit && <p className="text-[10px] text-muted-foreground leading-relaxed mt-1">{w.form_and_benefit}</p>}
            </div>
          ))}
        </div>
      )}

      {/* Health & medical tips */}
      {healthTips.length > 0 && (
        <div className="bg-white rounded-xl border border-border p-3 space-y-1.5">
          <div className="flex items-center gap-1.5 mb-1">
            <Heartbeat size={14} weight="duotone" className="text-red-500" />
            <p className="text-xs font-semibold">স্বাস্থ্য ও চিকিৎসা পরামর্শ</p>
          </div>
          {healthTips.map((tip, i) => (
            <p key={i} className="text-xs text-muted-foreground leading-relaxed">• {tip}</p>
          ))}
        </div>
      )}

      {/* Budget & hydration tips */}
      {tips.length > 0 && (
        <div className="bg-white rounded-xl border border-border p-3 space-y-1.5">
          <div className="flex items-center gap-1.5 mb-2">
            <Lightbulb size={14} className="text-amber-500" />
            <p className="text-xs font-semibold">টিপস</p>
          </div>
          {tips.map((tip, i) => (
            <p key={i} className="text-xs text-muted-foreground leading-relaxed">• {tip}</p>
          ))}
        </div>
      )}

      {/* Footer totals */}
      {(chart.total_calories !== undefined || chart.total_cost !== undefined) && (
        <div className="flex gap-2">
          {chart.total_calories !== undefined && (
            <div className="flex-1 bg-white rounded-xl border border-border p-2 text-center">
              <p className="text-sm font-bold text-primary">{chart.total_calories}</p>
              <p className="text-[10px] text-muted-foreground">মোট ক্যালরি</p>
            </div>
          )}
          {chart.total_cost !== undefined && (
            <div className="flex-1 bg-white rounded-xl border border-border p-2 text-center">
              <div className="flex items-center justify-center gap-1">
                <Wallet size={12} className="text-green-600" />
                <p className="text-sm font-bold text-green-700">৳{chart.total_cost}</p>
              </div>
              <p className="text-[10px] text-muted-foreground">মোট খরচ</p>
            </div>
          )}
        </div>
      )}
    </div>
  )
}

function NewMealCard({ meal }: { meal: NewMeal }) {
  const [open, setOpen] = useState(false)
  const foods = meal.foods ?? []

  return (
    <div className="bg-white rounded-xl border border-border overflow-hidden">
      <button
        className="w-full flex items-center gap-2 p-3 text-left"
        onClick={() => setOpen(v => !v)}
      >
        <span className="text-muted-foreground">{mealIcon(meal.meal_name)}</span>
        <div className="flex-1 min-w-0">
          <p className="text-sm font-semibold truncate">{meal.meal_name}</p>
          <div className="flex items-center gap-2 mt-0.5">
            {meal.ideal_time && (
              <span className="text-[10px] text-muted-foreground">{meal.ideal_time}</span>
            )}
            {meal.estimated_meal_cost_range_bdt && (
              <span className="text-[10px] text-green-600 font-medium">{meal.estimated_meal_cost_range_bdt}</span>
            )}
          </div>
        </div>
        <div className="flex items-center gap-2 shrink-0">
          {meal.estimated_meal_calories !== undefined && (
            <span className="text-xs text-amber-600 font-medium">{meal.estimated_meal_calories} kcal</span>
          )}
          {open ? <CaretUp size={12} /> : <CaretDown size={12} />}
        </div>
      </button>

      {open && foods.length > 0 && (
        <div className="border-t border-border divide-y divide-border/50">
          {foods.map((food, i) => <FoodItemRow key={i} food={food} />)}
        </div>
      )}
    </div>
  )
}

function FoodItemRow({ food }: { food: FoodItem }) {
  const [open, setOpen] = useState(false)

  return (
    <div className="px-3 py-2">
      <button className="w-full flex items-start justify-between gap-2 text-left" onClick={() => setOpen(v => !v)}>
        <div className="min-w-0">
          <p className="text-xs font-medium">{food.item_name}</p>
          <div className="flex gap-2 mt-0.5">
            {food.quantity && <span className="text-[10px] text-muted-foreground">{food.quantity}</span>}
            {food.estimated_price && (
              <span className="text-[10px] text-green-600 font-medium">{food.estimated_price}</span>
            )}
          </div>
        </div>
        {(food.preparation_steps || food.ingredients_and_nature || food.nutritional_benefit) && (
          open ? <CaretUp size={10} className="mt-1 shrink-0 text-muted-foreground" />
               : <CaretDown size={10} className="mt-1 shrink-0 text-muted-foreground" />
        )}
      </button>
      {open && (
        <div className="mt-2 space-y-1.5 pl-1 border-l-2 border-primary/20">
          {food.ingredients_and_nature && (
            <p className="text-[10px] text-muted-foreground"><span className="font-medium text-foreground/70">উপাদান: </span>{food.ingredients_and_nature}</p>
          )}
          {food.preparation_steps && (
            <p className="text-[10px] text-muted-foreground"><span className="font-medium text-foreground/70">প্রস্তুতি: </span>{food.preparation_steps}</p>
          )}
          {food.nutritional_benefit && (
            <p className="text-[10px] text-muted-foreground"><span className="font-medium text-foreground/70">উপকারিতা: </span>{food.nutritional_benefit}</p>
          )}
        </div>
      )}
    </div>
  )
}

function MacroBox({ value, label }: { value: string; label: string }) {
  return (
    <div className="bg-white rounded-xl p-2 text-center border border-border">
      <p className="text-base font-bold text-primary">{value}</p>
      <p className="text-[10px] text-muted-foreground">{label}</p>
    </div>
  )
}

// ── Old schema renderer (backward compat) ─────────────────────────────────────

function OldDietChartBody({ chart }: { chart: OldChart }) {
  const meals = chart.meals ?? []

  return (
    <div className="space-y-3">
      {(chart.daily_calories || chart.macros) && (
        <div className="grid grid-cols-4 gap-2">
          {chart.daily_calories && <MacroBox value={`${chart.daily_calories}`} label="kcal" />}
          {chart.macros?.protein !== undefined && <MacroBox value={`${chart.macros.protein}g`} label="protein" />}
          {chart.macros?.carbs   !== undefined && <MacroBox value={`${chart.macros.carbs}g`}   label="carbs"   />}
          {chart.macros?.fats    !== undefined && <MacroBox value={`${chart.macros.fats}g`}    label="fats"    />}
        </div>
      )}
      {meals.length > 0 && (
        <div className="space-y-2">
          {meals.map((meal, i) => {
            const foods = meal.foods ?? meal.items ?? []
            return (
              <div key={i} className="bg-white rounded-xl border border-border p-3">
                <div className="flex items-center gap-2 mb-1">
                  <span className="text-muted-foreground">{mealIcon(meal.name)}</span>
                  <p className="text-sm font-semibold">{meal.name}</p>
                  {meal.time     && <span className="text-xs text-muted-foreground ml-auto">{meal.time}</span>}
                  {meal.calories && <span className="text-xs text-amber-600 font-medium">{meal.calories} kcal</span>}
                </div>
                {foods.length > 0 && (
                  <p className="text-xs text-muted-foreground leading-relaxed">{foods.join(' · ')}</p>
                )}
              </div>
            )
          })}
        </div>
      )}
      {chart.notes && (
        <p className="text-xs text-muted-foreground italic border-t border-border/50 pt-2">{chart.notes}</p>
      )}
    </div>
  )
}
