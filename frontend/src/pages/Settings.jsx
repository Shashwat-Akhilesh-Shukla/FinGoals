import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Download, Database, FileJson, FileText, ChevronRight, Plus, Trash2, Info } from 'lucide-react'
import { api } from '../lib/api'
import Skeleton from '../components/Skeleton'

// ─── Category Manager ──────────────────────────────────────
function CategoryManager() {
  const qc = useQueryClient()
  const [form, setForm] = useState({ name: '', bucket: 'lifestyle', transaction_type: 'expense' })
  const [show, setShow] = useState(false)

  const { data: cats, isLoading } = useQuery({
    queryKey: ['categories'],
    queryFn: api.getCategories,
    staleTime: Infinity,
  })

  const createM = useMutation({
    mutationFn: api.createCategory,
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['categories'] }); setForm({ name: '', bucket: 'lifestyle', transaction_type: 'expense' }) },
  })
  const deleteM = useMutation({
    mutationFn: api.deleteCategory,
    onSuccess: () => qc.invalidateQueries({ queryKey: ['categories'] }),
  })

  const BUCKETS = [
    { value: 'essentials',  txType: 'expense',    label: 'Essentials'  },
    { value: 'lifestyle',   txType: 'expense',    label: 'Lifestyle'   },
    { value: 'investments', txType: 'investment', label: 'Investments' },
    { value: 'savings',     txType: 'savings',    label: 'Savings'     },
    { value: 'income',      txType: 'income',     label: 'Income'      },
  ]

  const customCats = (cats || []).filter(c => c.is_custom)

  return (
    <div>
      <div className="section-label">CATEGORIES</div>
      <div style={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: '16px', overflow: 'hidden' }}>
        {/* Toggle form */}
        <button
          id="add-category-btn"
          onClick={() => setShow(s => !s)}
          style={{
            width: '100%', display: 'flex', alignItems: 'center', gap: '10px',
            padding: '14px 16px', background: 'none', border: 'none',
            borderBottom: '1px solid var(--border)', cursor: 'pointer', textAlign: 'left',
          }}
        >
          <div style={{ width: '34px', height: '34px', borderRadius: '10px', background: 'var(--green-muted)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Plus size={16} color="var(--green)" />
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: '14px', fontWeight: 500, color: 'var(--text-1)' }}>Add Custom Category</div>
            <div style={{ fontSize: '11px', color: 'var(--text-3)', marginTop: '1px' }}>Extend the predefined list</div>
          </div>
          <ChevronRight size={14} color="var(--text-3)" style={{ transform: show ? 'rotate(90deg)' : 'none', transition: 'transform 0.15s' }} />
        </button>

        {show && (
          <div style={{ padding: '14px 16px', borderBottom: '1px solid var(--border)', display: 'flex', flexDirection: 'column', gap: '10px' }}>
            <input
              className="field-input"
              placeholder="Category name"
              value={form.name}
              onChange={e => setForm(p => ({ ...p, name: e.target.value }))}
            />
            <select
              className="field-input"
              style={{ appearance: 'none' }}
              value={form.bucket}
              onChange={e => {
                const b = BUCKETS.find(b => b.value === e.target.value)
                setForm(p => ({ ...p, bucket: e.target.value, transaction_type: b?.txType || 'expense' }))
              }}
            >
              {BUCKETS.map(b => <option key={b.value} value={b.value} style={{ background: '#111' }}>{b.label}</option>)}
            </select>
            <button
              onClick={() => { if (form.name) createM.mutate(form) }}
              disabled={!form.name || createM.isPending}
              style={{
                padding: '10px', borderRadius: '10px',
                background: form.name ? 'var(--green)' : 'var(--surface-3)',
                color: form.name ? '#000' : 'var(--text-3)',
                fontWeight: 600, fontSize: '13px', border: 'none', cursor: 'pointer',
              }}
            >
              {createM.isPending ? 'Adding...' : 'Add Category'}
            </button>
          </div>
        )}

        {/* Custom categories list */}
        {isLoading ? (
          <div style={{ padding: '14px 16px' }}><Skeleton height={40} /></div>
        ) : customCats.length === 0 ? (
          <div style={{ padding: '14px 16px', fontSize: '12px', color: 'var(--text-3)', textAlign: 'center' }}>
            No custom categories yet
          </div>
        ) : (
          customCats.map((cat, i) => (
            <div
              key={cat.id}
              style={{
                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                padding: '11px 16px',
                borderTop: '1px solid var(--border)',
              }}
            >
              <div>
                <div style={{ fontSize: '13px', fontWeight: 500, color: 'var(--text-1)' }}>{cat.name}</div>
                <div style={{ fontSize: '11px', color: 'var(--text-3)', textTransform: 'capitalize' }}>{cat.bucket}</div>
              </div>
              <button
                onClick={() => { if (window.confirm(`Delete category "${cat.name}"?`)) deleteM.mutate(cat.id) }}
                style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--red)', opacity: 0.5, display: 'flex' }}
              >
                <Trash2 size={14} />
              </button>
            </div>
          ))
        )}
      </div>
    </div>
  )
}

// ─── Settings Page ─────────────────────────────────────────
export default function Settings() {
  const EXPORT_SECTION = [
    {
      id: 'export-csv',
      Icon: FileText,
      label: 'Export as CSV',
      sub: 'All transactions in spreadsheet format',
      action: api.exportCSV,
      color: '#10b981',
    },
    {
      id: 'export-json',
      Icon: FileJson,
      label: 'Export as JSON',
      sub: 'Full backup including goals & categories',
      action: api.exportJSON,
      color: '#3b82f6',
    },
    {
      id: 'export-backup',
      Icon: Database,
      label: 'Download SQLite Backup',
      sub: 'Raw database file for complete backup',
      action: api.downloadBackup,
      color: '#8b5cf6',
    },
  ]

  const VERDICT_GUIDE = [
    { label: 'STRONG',   color: '#10b981', desc: 'Savings rate > 40%' },
    { label: 'GOOD',     color: '#10b981', desc: 'Savings rate 20–40%' },
    { label: 'WEAK',     color: '#f59e0b', desc: 'Savings rate 5–20%' },
    { label: 'FAILED',   color: '#ef4444', desc: 'Savings rate < 5%' },
    { label: 'OVERDEPENDENT', color: '#ef4444', desc: 'Essentials > 60% of income' },
    { label: 'NOT BUILDING WEALTH', color: '#ef4444', desc: 'Investment rate < 10%' },
  ]

  return (
    <div className="page-enter">
      <div style={{ padding: '20px 16px 24px' }}>
        <h1 style={{ fontSize: '20px', fontWeight: 700, margin: 0 }}>Settings</h1>
        <div style={{ fontSize: '12px', color: 'var(--text-3)', marginTop: '3px' }}>Data control · No cloud · Local only</div>
      </div>

      <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: '20px' }}>

        {/* Export */}
        <div>
          <div className="section-label">DATA EXPORT</div>
          <div style={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: '16px', overflow: 'hidden' }}>
            {EXPORT_SECTION.map(({ id, Icon, label, sub, action, color }, i) => (
              <button
                key={id}
                id={id}
                onClick={action}
                style={{
                  width: '100%', display: 'flex', alignItems: 'center', gap: '12px',
                  padding: '14px 16px', background: 'none',
                  border: 'none',
                  borderTop: i > 0 ? '1px solid var(--border)' : 'none',
                  cursor: 'pointer', textAlign: 'left',
                }}
              >
                <div style={{ width: '36px', height: '36px', borderRadius: '10px', background: `${color}15`, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  <Icon size={17} color={color} strokeWidth={1.8} />
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: '14px', fontWeight: 500, color: 'var(--text-1)' }}>{label}</div>
                  <div style={{ fontSize: '11px', color: 'var(--text-3)', marginTop: '2px' }}>{sub}</div>
                </div>
                <ChevronRight size={14} color="var(--text-3)" />
              </button>
            ))}
          </div>
        </div>

        {/* Categories */}
        <CategoryManager />

        {/* Verdict guide */}
        <div>
          <div className="section-label">VERDICT SYSTEM</div>
          <div style={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: '16px', padding: '16px', display: 'flex', flexDirection: 'column', gap: '10px' }}>
            {VERDICT_GUIDE.map(v => (
              <div key={v.label} style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <span style={{
                  fontFamily: 'JetBrains Mono', fontSize: '10px', fontWeight: 700,
                  color: v.color, minWidth: '130px', letterSpacing: '0.04em',
                }}>
                  {v.label}
                </span>
                <span style={{ fontSize: '12px', color: 'var(--text-2)' }}>{v.desc}</span>
              </div>
            ))}
          </div>
        </div>

        {/* App info */}
        <div style={{
          background: 'var(--surface)', border: '1px solid var(--border)',
          borderRadius: '16px', padding: '16px',
          display: 'flex', alignItems: 'center', gap: '12px',
        }}>
          <Info size={16} color="var(--text-3)" />
          <div>
            <div style={{ fontSize: '13px', fontWeight: 500, color: 'var(--text-2)' }}>FinGoals v1.0</div>
            <div style={{ fontSize: '11px', color: 'var(--text-3)', marginTop: '2px' }}>
              Local-first · Zero cloud · No AI · No external APIs
            </div>
          </div>
        </div>

        <div style={{ height: '4px' }} />
      </div>
    </div>
  )
}
