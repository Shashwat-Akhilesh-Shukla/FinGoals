import { useState, useCallback } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Search, Upload, Edit2, Trash2, AlertCircle } from 'lucide-react'
import { api } from '../lib/api'
import { formatINR, formatDate, getTypeMeta } from '../lib/formatters'
import { useApp } from '../store/AppContext'
import TransactionForm from '../components/TransactionForm'
import Skeleton from '../components/Skeleton'

const TYPE_FILTERS = [
  { value: '',           label: 'All'        },
  { value: 'income',     label: 'Income'     },
  { value: 'expense',    label: 'Expenses'   },
  { value: 'investment', label: 'Invested'   },
  { value: 'savings',    label: 'Savings'    },
]

// ─── Single Transaction Row ────────────────────────────────
function TxRow({ tx, onEdit, onDelete }) {
  const meta = getTypeMeta(tx.type)
  const sign = tx.type === 'income' ? '+' : '-'

  return (
    <div
      style={{
        background: 'var(--surface)',
        border: '1px solid var(--border)',
        borderRadius: '12px',
        padding: '12px 14px',
        display: 'flex',
        alignItems: 'center',
        gap: '12px',
      }}
    >
      {/* Type badge */}
      <div style={{
        width: '38px', height: '38px', borderRadius: '10px',
        background: meta.bg,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0,
      }}>
        <span style={{ fontFamily: 'JetBrains Mono', fontSize: '10px', color: meta.color, fontWeight: 700 }}>
          {tx.type.slice(0, 3).toUpperCase()}
        </span>
      </div>

      {/* Info */}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: '13px', fontWeight: 500, color: 'var(--text-1)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
          {tx.category}
        </div>
        <div style={{ fontSize: '11px', color: 'var(--text-3)', marginTop: '2px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
          {tx.account} · {formatDate(tx.timestamp)}{tx.note ? ` · ${tx.note}` : ''}
        </div>
      </div>

      {/* Amount + actions */}
      <div style={{ textAlign: 'right', flexShrink: 0 }}>
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: '14px', fontWeight: 600, color: meta.color }}>
          {sign}{formatINR(tx.amount)}
        </div>
        <div style={{ display: 'flex', gap: '10px', marginTop: '5px', justifyContent: 'flex-end' }}>
          <button
            onClick={onEdit}
            style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0, color: 'var(--text-3)', display: 'flex' }}
            aria-label="Edit"
          >
            <Edit2 size={13} />
          </button>
          <button
            onClick={onDelete}
            style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0, color: 'var(--red)', opacity: 0.6, display: 'flex' }}
            aria-label="Delete"
          >
            <Trash2 size={13} />
          </button>
        </div>
      </div>
    </div>
  )
}

// ─── Transactions Page ─────────────────────────────────────
export default function Transactions() {
  const { selectedMonth } = useApp()
  const qc = useQueryClient()

  const [typeFilter, setTypeFilter] = useState('')
  const [search,     setSearch]     = useState('')
  const [page,       setPage]       = useState(1)
  const [editTx,     setEditTx]     = useState(null)

  const { data, isLoading, isError } = useQuery({
    queryKey: ['transactions', typeFilter, selectedMonth, page],
    queryFn:  () => api.getTransactions({ type: typeFilter, month: selectedMonth, page, per_page: 50 }),
  })

  const deleteMut = useMutation({
    mutationFn: (id) => api.deleteTransaction(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['transactions'] })
      qc.invalidateQueries({ queryKey: ['summary'] })
      qc.invalidateQueries({ queryKey: ['verdicts'] })
    },
  })

  const handleDelete = useCallback((tx) => {
    if (!window.confirm(`Delete ₹${tx.amount} · ${tx.category}?`)) return
    deleteMut.mutate(tx.id)
  }, [deleteMut])

  const handleImport = async (e) => {
    const file = e.target.files?.[0]
    if (!file) return
    e.target.value = ''
    try {
      const r = await api.importCSV(file)
      const msg = `✓ Imported ${r.imported} transactions` + (r.errors?.length ? `\n\nErrors:\n${r.errors.join('\n')}` : '')
      alert(msg)
      qc.invalidateQueries({ queryKey: ['transactions'] })
      qc.invalidateQueries({ queryKey: ['summary'] })
    } catch (err) {
      alert('Import failed: ' + err.message)
    }
  }

  const items = (data?.items || []).filter(tx =>
    !search ||
    tx.category.toLowerCase().includes(search.toLowerCase()) ||
    (tx.note || '').toLowerCase().includes(search.toLowerCase())
  )

  return (
    <div className="page-enter">
      {/* Header */}
      <div style={{ padding: '20px 16px 12px', display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
        <div>
          <h1 style={{ fontSize: '20px', fontWeight: 700, margin: 0 }}>Transactions</h1>
          <div style={{ fontSize: '12px', color: 'var(--text-3)', marginTop: '3px' }}>
            {data?.total ?? '—'} total records
          </div>
        </div>

        <label id="import-csv-btn" style={{ cursor: 'pointer' }}>
          <input type="file" accept=".csv" onChange={handleImport} style={{ display: 'none' }} />
          <span style={{
            display: 'flex', alignItems: 'center', gap: '5px',
            padding: '8px 12px', borderRadius: '10px',
            background: 'var(--surface)', border: '1px solid var(--border)',
            fontSize: '12px', color: 'var(--text-2)',
          }}>
            <Upload size={13} /> Import CSV
          </span>
        </label>
      </div>

      {/* Search */}
      <div style={{ padding: '0 16px 10px' }}>
        <div style={{ position: 'relative' }}>
          <Search size={13} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-3)' }} />
          <input
            id="tx-search"
            type="text"
            placeholder="Search category or note..."
            value={search}
            onChange={e => setSearch(e.target.value)}
            className="field-input"
            style={{ paddingLeft: '34px' }}
          />
        </div>
      </div>

      {/* Type filter pills */}
      <div style={{ padding: '0 16px 12px', display: 'flex', gap: '7px', overflowX: 'auto' }}>
        {TYPE_FILTERS.map(f => (
          <button
            key={f.value}
            id={`filter-${f.value || 'all'}`}
            onClick={() => { setTypeFilter(f.value); setPage(1) }}
            style={{
              padding: '6px 14px', borderRadius: '20px',
              fontSize: '12px', fontWeight: 500,
              whiteSpace: 'nowrap', cursor: 'pointer',
              transition: 'all 0.12s',
              background: typeFilter === f.value ? 'var(--green)' : 'var(--surface)',
              border: `1px solid ${typeFilter === f.value ? 'var(--green)' : 'var(--border)'}`,
              color: typeFilter === f.value ? '#000' : 'var(--text-2)',
            }}
          >
            {f.label}
          </button>
        ))}
      </div>

      {/* List */}
      <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: '6px' }}>
        {isLoading ? (
          Array.from({ length: 7 }).map((_, i) => <Skeleton key={i} height={62} radius={12} />)
        ) : isError ? (
          <div style={{ textAlign: 'center', padding: '48px 0', color: 'var(--red)' }}>
            <AlertCircle size={28} style={{ margin: '0 auto 10px', opacity: 0.5 }} />
            <div style={{ fontSize: '13px' }}>Failed to load transactions</div>
          </div>
        ) : items.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '48px 0', color: 'var(--text-3)' }}>
            <div style={{ fontSize: '14px', fontWeight: 500 }}>No transactions found</div>
            <div style={{ fontSize: '12px', marginTop: '5px' }}>Try a different filter or add one with +</div>
          </div>
        ) : (
          items.map(tx => (
            <TxRow
              key={tx.id}
              tx={tx}
              onEdit={() => setEditTx(tx)}
              onDelete={() => handleDelete(tx)}
            />
          ))
        )}

        {data?.has_more && (
          <button
            id="load-more-btn"
            onClick={() => setPage(p => p + 1)}
            style={{
              margin: '6px 0 20px', padding: '13px', borderRadius: '12px',
              background: 'var(--surface)', border: '1px solid var(--border)',
              color: 'var(--text-2)', fontSize: '13px', cursor: 'pointer', width: '100%',
            }}
          >
            Load more ({data.total - data.page * data.per_page} remaining)
          </button>
        )}

        <div style={{ height: '4px' }} />
      </div>

      {/* Edit form */}
      {editTx && (
        <TransactionForm
          transaction={editTx}
          onClose={() => setEditTx(null)}
        />
      )}
    </div>
  )
}
