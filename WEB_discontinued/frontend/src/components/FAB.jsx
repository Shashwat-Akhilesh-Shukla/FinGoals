import { Plus } from 'lucide-react'
import { useApp } from '../store/AppContext'

export default function FAB() {
  const { setShowAddForm } = useApp()

  return (
    <button
      id="fab-add-transaction"
      onClick={() => setShowAddForm(true)}
      aria-label="Add transaction"
      style={{
        position: 'fixed',
        bottom: '78px',
        right: 'max(16px, calc(50% - 224px))',
        width: '52px',
        height: '52px',
        borderRadius: '16px',
        background: 'var(--green)',
        border: 'none',
        cursor: 'pointer',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        boxShadow: '0 4px 24px rgba(16, 185, 129, 0.40)',
        zIndex: 99,
        transition: 'transform 0.15s, box-shadow 0.15s',
      }}
      onMouseEnter={e => {
        e.currentTarget.style.transform = 'scale(1.06)'
        e.currentTarget.style.boxShadow = '0 6px 28px rgba(16, 185, 129, 0.55)'
      }}
      onMouseLeave={e => {
        e.currentTarget.style.transform = 'scale(1)'
        e.currentTarget.style.boxShadow = '0 4px 24px rgba(16, 185, 129, 0.40)'
      }}
      onMouseDown={e => { e.currentTarget.style.transform = 'scale(0.96)' }}
      onMouseUp={e => { e.currentTarget.style.transform = 'scale(1.06)' }}
    >
      <Plus size={24} color="#000" strokeWidth={2.5} />
    </button>
  )
}
