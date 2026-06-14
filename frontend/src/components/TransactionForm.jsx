import { useState, useEffect, useRef } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { X, Check } from 'lucide-react'
import { motion, AnimatePresence } from 'framer-motion'
import { api } from '../lib/api'
import { TYPE_META } from '../lib/formatters'

const ACCOUNTS = ['Bank', 'Cash', 'Credit Card', 'UPI / Wallet', 'Other']

export default function TransactionForm({ transaction, onClose }) {
  const qc        = useQueryClient()
  const isEdit    = !!transaction
  const amountRef = useRef(null)

  const [form, setForm] = useState({
    amount:    transaction?.amount?.toString() || '',
    type:      transaction?.type   || 'expense',
    category:  transaction?.category || '',
    account:   transaction?.account  || 'Bank',
    note:      transaction?.note     || '',
    timestamp: transaction?.timestamp
      ? new Date(transaction.timestamp).toISOString().slice(0, 16)
      : new Date().toISOString().slice(0, 16),
  })

  const { data: allCategories = [] } = useQuery({
    queryKey: ['categories'],
    queryFn:  api.getCategories,
    staleTime: Infinity,
  })

  useEffect(() => {
    const t = setTimeout(() => amountRef.current?.focus(), 120)
    return () => clearTimeout(t)
  }, [])

  // Filtered categories for current type
  const cats = allCategories.filter(c => c.transaction_type === form.type)

  function invalidate() {
    qc.invalidateQueries({ queryKey: ['transactions'] })
    qc.invalidateQueries({ queryKey: ['summary'] })
    qc.invalidateQueries({ queryKey: ['verdicts'] })
    qc.invalidateQueries({ queryKey: ['breakdown'] })
    qc.invalidateQueries({ queryKey: ['trends'] })
  }

  const createM = useMutation({
    mutationFn: api.createTransaction,
    onSuccess: () => { invalidate(); onClose() },
  })
  const updateM = useMutation({
    mutationFn: ({ id, data }) => api.updateTransaction(id, data),
    onSuccess: () => { invalidate(); onClose() },
  })

  function setField(key, val) {
    setForm(p => ({ ...p, [key]: val }))
  }

  function handleSubmit(e) {
    e.preventDefault()
    if (!form.amount || !form.category) return
    const payload = {
      ...form,
      amount:    parseFloat(form.amount),
      timestamp: new Date(form.timestamp).toISOString(),
    }
    if (isEdit) updateM.mutate({ id: transaction.id, data: payload })
    else        createM.mutate(payload)
  }

  const meta    = TYPE_META[form.type] || TYPE_META.expense
  const pending = createM.isPending || updateM.isPending
  const canSave = form.amount && form.category

  return (
    <AnimatePresence>
      <motion.div
        className="sheet-overlay"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        transition={{ duration: 0.15 }}
        onClick={e => e.target === e.currentTarget && onClose()}
      >
        <motion.div
          className="sheet-panel"
          initial={{ y: '100%' }}
          animate={{ y: 0 }}
          exit={{ y: '100%' }}
          transition={{ type: 'spring', damping: 26, stiffness: 320 }}
        >
          {/* Handle bar */}
          <div style={{
            width: '36px', height: '4px',
            background: 'var(--border-strong)',
            borderRadius: '2px',
            margin: '14px auto 20px',
          }} />

          {/* Header */}
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '20px' }}>
            <span style={{ fontSize: '16px', fontWeight: 700, color: 'var(--text-1)' }}>
              {isEdit ? 'Edit Transaction' : 'Add Transaction'}
            </span>
            <button
              id="close-transaction-form"
              onClick={onClose}
              style={{
                background: 'var(--surface-2)', border: '1px solid var(--border)',
                borderRadius: '8px', padding: '6px', cursor: 'pointer',
                color: 'var(--text-2)', display: 'flex',
              }}
            >
              <X size={16} />
            </button>
          </div>

          <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>

            {/* Amount display */}
            <div style={{
              background: 'var(--surface-2)',
              border: `1px solid ${meta.color}33`,
              borderRadius: '16px',
              padding: '16px 20px',
            }}>
              <div className="field-label" style={{ marginBottom: '6px' }}>AMOUNT (₹)</div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: '6px' }}>
                <span style={{
                  fontFamily: 'JetBrains Mono', fontSize: '28px',
                  fontWeight: 700, color: meta.color,
                }}>₹</span>
                <input
                  ref={amountRef}
                  id="tx-amount"
                  type="number"
                  step="0.01"
                  min="0"
                  placeholder="0"
                  value={form.amount}
                  onChange={e => setField('amount', e.target.value)}
                  required
                  style={{
                    background: 'none', border: 'none', outline: 'none',
                    fontFamily: 'JetBrains Mono', fontSize: '36px',
                    fontWeight: 700, color: meta.color,
                    width: '100%', padding: 0,
                  }}
                />
              </div>
            </div>

            {/* Type selector */}
            <div>
              <div className="field-label">TYPE</div>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '8px' }}>
                {Object.entries(TYPE_META).map(([type, m]) => (
                  <button
                    key={type}
                    id={`type-${type}`}
                    type="button"
                    onClick={() => setForm(p => ({ ...p, type, category: '' }))}
                    style={{
                      padding: '10px 4px', borderRadius: '12px',
                      fontSize: '11px', fontWeight: 600, cursor: 'pointer',
                      border: `1px solid ${form.type === type ? m.color : 'var(--border)'}`,
                      background: form.type === type ? m.bg : 'var(--surface-2)',
                      color: form.type === type ? m.color : 'var(--text-3)',
                      transition: 'all 0.12s',
                    }}
                  >
                    {m.label}
                  </button>
                ))}
              </div>
            </div>

            {/* Category chips */}
            <div>
              <div className="field-label">CATEGORY</div>
              {cats.length === 0 ? (
                <p style={{ fontSize: '12px', color: 'var(--text-3)', margin: 0 }}>No categories. Go to Settings to add.</p>
              ) : (
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '7px', maxHeight: '130px', overflowY: 'auto' }}>
                  {cats.map(cat => (
                    <button
                      key={cat.name}
                      id={`cat-${cat.name.replace(/\s+/g, '-').toLowerCase()}`}
                      type="button"
                      onClick={() => setField('category', cat.name)}
                      style={{
                        padding: '6px 12px', borderRadius: '8px',
                        fontSize: '12px', cursor: 'pointer',
                        border: `1px solid ${form.category === cat.name ? meta.color : 'var(--border)'}`,
                        background: form.category === cat.name ? meta.bg : 'var(--surface-2)',
                        color: form.category === cat.name ? meta.color : 'var(--text-2)',
                        transition: 'all 0.1s', whiteSpace: 'nowrap',
                      }}
                    >
                      {cat.name}
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* Account + Date row */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
              <div>
                <div className="field-label">ACCOUNT</div>
                <select
                  id="tx-account"
                  value={form.account}
                  onChange={e => setField('account', e.target.value)}
                  className="field-input"
                  style={{ appearance: 'none' }}
                >
                  {ACCOUNTS.map(a => <option key={a} value={a} style={{ background: '#111' }}>{a}</option>)}
                </select>
              </div>
              <div>
                <div className="field-label">DATE</div>
                <input
                  id="tx-date"
                  type="datetime-local"
                  value={form.timestamp}
                  onChange={e => setField('timestamp', e.target.value)}
                  className="field-input"
                />
              </div>
            </div>

            {/* Note */}
            <div>
              <div className="field-label">NOTE</div>
              <input
                id="tx-note"
                type="text"
                placeholder="Optional note..."
                value={form.note}
                onChange={e => setField('note', e.target.value)}
                className="field-input"
              />
            </div>

            {/* Submit */}
            <button
              id="submit-transaction"
              type="submit"
              disabled={pending || !canSave}
              style={{
                padding: '15px',
                borderRadius: '14px',
                background: canSave ? meta.color : 'var(--surface-3)',
                color: canSave ? '#000' : 'var(--text-3)',
                fontWeight: 700, fontSize: '15px',
                border: 'none', cursor: canSave ? 'pointer' : 'not-allowed',
                display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px',
                transition: 'all 0.15s',
                marginTop: '4px',
              }}
            >
              {pending ? (
                <span>Saving...</span>
              ) : (
                <>
                  <Check size={18} />
                  {isEdit ? 'Save Changes' : `Add ${meta.label}`}
                </>
              )}
            </button>
          </form>
        </motion.div>
      </motion.div>
    </AnimatePresence>
  )
}
