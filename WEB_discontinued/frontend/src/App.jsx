import { Routes, Route, Navigate } from 'react-router-dom'
import Dashboard from './pages/Dashboard'
import Transactions from './pages/Transactions'
import Goals from './pages/Goals'
import Settings from './pages/Settings'
import BottomNav from './components/BottomNav'
import FAB from './components/FAB'
import TransactionForm from './components/TransactionForm'
import { useApp } from './store/AppContext'

export default function App() {
  const { showAddForm, setShowAddForm } = useApp()

  return (
    <div style={{ background: 'var(--bg)', minHeight: '100dvh' }}>
      <div className="main-content">
        <Routes>
          <Route path="/"              element={<Navigate to="/dashboard" replace />} />
          <Route path="/dashboard"     element={<Dashboard />} />
          <Route path="/transactions"  element={<Transactions />} />
          <Route path="/goals"         element={<Goals />} />
          <Route path="/settings"      element={<Settings />} />
        </Routes>
      </div>

      <FAB />
      <BottomNav />

      {showAddForm && (
        <TransactionForm onClose={() => setShowAddForm(false)} />
      )}
    </div>
  )
}
