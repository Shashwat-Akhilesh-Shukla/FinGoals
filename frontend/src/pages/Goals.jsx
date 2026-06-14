import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Plus, Trash2, Target, TrendingUp, Shield, X } from 'lucide-react'
import { api } from '../lib/api'
import { formatINR } from '../lib/formatters'
import Skeleton from '../components/Skeleton'

const GOAL_TYPES = [
  { value: 'emergency', label: 'Emergency Fund', Icon: Shield,    color: '#3b82f6' },
  { value: 'sip',       label: 'SIP / Invest',   Icon: TrendingUp, color: '#10b981' },
  { value: 'custom',    label: 'Custom Goal',    Icon: Target,    color: '#8b5cf6' },
]

// ─── Goal Card ─────────────────────────────────────────────
function GoalCard({ goal, onUpdateAmount, onDelete }) {
  const pct  = goal.progress_pct
  const gCfg = GOAL_TYPES.find(t => t.value === goal.type) || GOAL_TYPES[2]
  const Icon  = gCfg.Icon
  const color = pct >= 100 ? '#10b981' : pct >= 60 ? '#f59e0b' : '#ef4444'
  const rem   = Math.max(0, goal.target_amount - goal.current_amount)
  const [amount, setAmount] = useState('')

  return (
    <div style={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: '18px', padding: '18px' }}>
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: '14px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <div style={{
            width: '40px', height: '40px', borderRadius: '12px',
            background: `${gCfg.color}18`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon size={18} color={gCfg.color} strokeWidth={1.8} />
          </div>
          <div>
            <div style={{ fontSize: '14px', fontWeight: 600, color: 'var(--text-1)' }}>{goal.name}</div>
            <div style={{ fontSize: '11px', color: 'var(--text-3)', marginTop: '2px', textTransform: 'capitalize' }}>
              {gCfg.label}
            </div>
          </div>
        </div>
        <button
          onClick={onDelete}
          style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-3)', opacity: 0.5, display: 'flex', padding: '2px' }}
          aria-label="Delete goal"
        >
          <Trash2 size={14} />
        </button>
      </div>

      {/* Progress bar */}
      <div style={{ background: 'var(--surface-3)', borderRadius: '4px', height: '6px', overflow: 'hidden', marginBottom: '10px' }}>
        <div style={{
          height: '100%',
          width: `${Math.min(pct, 100)}%`,
          background: color,
          borderRadius: '4px',
          transition: 'width 0.6s cubic-bezier(.4,0,.2,1)',
        }} />
      </div>

      {/* Amounts */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '10px' }}>
        <div>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: '15px', fontWeight: 700, color: 'var(--text-1)' }}>
            {formatINR(goal.current_amount)}
          </span>
          <span style={{ fontSize: '12px', color: 'var(--text-3)' }}>
            {' '}/ {formatINR(goal.target_amount)}
          </span>
        </div>
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: '22px', fontWeight: 800, color }}>
          {pct >= 100 ? '✓' : `${pct.toFixed(1)}%`}
        </div>
      </div>

      {rem > 0 && (
        <div style={{ fontSize: '11px', color: 'var(--text-3)', marginBottom: '12px' }}>
          {formatINR(rem)} remaining
          {goal.monthly_target ? ` · ${formatINR(goal.monthly_target)}/mo target` : ''}
        </div>
      )}

      {/* Quick add amount */}
      <div style={{ display: 'flex', gap: '8px' }}>
        <input
          type="number"
          placeholder="Add amount..."
          value={amount}
          onChange={e => setAmount(e.target.value)}
          className="field-input"
          style={{ flex: 1, fontSize: '13px' }}
          min="0"
        />
        <button
          onClick={() => {
            if (!amount) return
            onUpdateAmount(goal.current_amount + parseFloat(amount))
            setAmount('')
          }}
          style={{
            padding: '0 16px', borderRadius: '10px',
            background: amount ? gCfg.color : 'var(--surface-3)',
            color: amount ? '#000' : 'var(--text-3)',
            border: 'none', cursor: amount ? 'pointer' : 'not-allowed',
            fontSize: '13px', fontWeight: 600, whiteSpace: 'nowrap',
          }}
        >
          + Add
        </button>
      </div>
    </div>
  )
}

// ─── New Goal Form ─────────────────────────────────────────
function GoalForm({ onSubmit, onCancel, isLoading }) {
  const [form, setForm] = useState({
    name: '', type: 'custom',
    target_amount: '', current_amount: '', monthly_target: '', description: '',
  })
  const s = (k, v) => setForm(p => ({ ...p, [k]: v }))

  return (
    <div style={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: '18px', padding: '18px', margin: '0 0 12px' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '14px' }}>
        <span style={{ fontSize: '14px', fontWeight: 600 }}>New Goal</span>
        <button onClick={onCancel} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-3)', display: 'flex' }}>
          <X size={16} />
        </button>
      </div>

      <form onSubmit={e => { e.preventDefault(); onSubmit(form) }} style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
        <input className="field-input" placeholder="Goal name *" value={form.name} onChange={e => s('name', e.target.value)} required />

        {/* Type selector */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '7px' }}>
          {GOAL_TYPES.map(t => (
            <button
              key={t.value}
              type="button"
              onClick={() => s('type', t.value)}
              style={{
                padding: '9px 6px', borderRadius: '10px', fontSize: '11px', fontWeight: 600,
                cursor: 'pointer',
                background: form.type === t.value ? `${t.color}18` : 'var(--surface-2)',
                border: `1px solid ${form.type === t.value ? t.color : 'var(--border)'}`,
                color: form.type === t.value ? t.color : 'var(--text-3)',
              }}
            >
              {t.label}
            </button>
          ))}
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
          <input className="field-input" type="number" min="0" placeholder="Target ₹ *" value={form.target_amount} onChange={e => s('target_amount', e.target.value)} required />
          <input className="field-input" type="number" min="0" placeholder="Current ₹" value={form.current_amount} onChange={e => s('current_amount', e.target.value)} />
        </div>

        {form.type === 'sip' && (
          <input className="field-input" type="number" min="0" placeholder="Monthly target ₹" value={form.monthly_target} onChange={e => s('monthly_target', e.target.value)} />
        )}

        <button
          type="submit"
          disabled={isLoading}
          style={{
            padding: '12px', borderRadius: '12px',
            background: 'var(--green)', color: '#000',
            fontWeight: 700, fontSize: '14px',
            border: 'none', cursor: 'pointer',
            marginTop: '2px',
          }}
        >
          {isLoading ? 'Creating...' : 'Create Goal'}
        </button>
      </form>
    </div>
  )
}

// ─── Goals Page ────────────────────────────────────────────
export default function Goals() {
  const qc = useQueryClient()
  const [showForm, setShowForm] = useState(false)

  const { data: goals, isLoading } = useQuery({
    queryKey: ['goals'],
    queryFn:  api.getGoals,
  })

  const createM = useMutation({
    mutationFn: api.createGoal,
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['goals'] }); setShowForm(false) },
  })
  const updateM = useMutation({
    mutationFn: ({ id, data }) => api.updateGoal(id, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['goals'] }),
  })
  const deleteM = useMutation({
    mutationFn: api.deleteGoal,
    onSuccess: () => qc.invalidateQueries({ queryKey: ['goals'] }),
  })

  function handleCreate(form) {
    createM.mutate({
      ...form,
      target_amount:  parseFloat(form.target_amount) || 0,
      current_amount: parseFloat(form.current_amount) || 0,
      monthly_target: form.monthly_target ? parseFloat(form.monthly_target) : null,
    })
  }

  return (
    <div className="page-enter">
      <div style={{ padding: '20px 16px 14px', display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
        <div>
          <h1 style={{ fontSize: '20px', fontWeight: 700, margin: 0 }}>Goals</h1>
          <div style={{ fontSize: '12px', color: 'var(--text-3)', marginTop: '3px' }}>
            {goals?.length ?? '—'} active goals
          </div>
        </div>
        <button
          id="add-goal-btn"
          onClick={() => setShowForm(f => !f)}
          style={{
            display: 'flex', alignItems: 'center', gap: '5px',
            padding: '8px 14px', borderRadius: '10px',
            background: showForm ? 'var(--surface-3)' : 'var(--green)',
            color: showForm ? 'var(--text-2)' : '#000',
            fontSize: '12px', fontWeight: 600, border: 'none', cursor: 'pointer',
          }}
        >
          <Plus size={14} strokeWidth={2.5} />
          New Goal
        </button>
      </div>

      <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: '10px' }}>
        {showForm && (
          <GoalForm
            onSubmit={handleCreate}
            onCancel={() => setShowForm(false)}
            isLoading={createM.isPending}
          />
        )}

        {isLoading ? (
          Array.from({ length: 3 }).map((_, i) => <Skeleton key={i} height={160} radius={18} />)
        ) : goals?.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '56px 20px', color: 'var(--text-3)' }}>
            <Target size={36} style={{ margin: '0 auto 14px', opacity: 0.25 }} />
            <div style={{ fontSize: '14px', fontWeight: 500, color: 'var(--text-2)' }}>No goals set</div>
            <div style={{ fontSize: '12px', marginTop: '6px' }}>Define financial targets and track progress</div>
          </div>
        ) : (
          goals?.map(goal => (
            <GoalCard
              key={goal.id}
              goal={goal}
              onUpdateAmount={(amt) => updateM.mutate({ id: goal.id, data: { current_amount: amt } })}
              onDelete={() => { if (window.confirm(`Delete goal "${goal.name}"?`)) deleteM.mutate(goal.id) }}
            />
          ))
        )}

        <div style={{ height: '4px' }} />
      </div>
    </div>
  )
}
