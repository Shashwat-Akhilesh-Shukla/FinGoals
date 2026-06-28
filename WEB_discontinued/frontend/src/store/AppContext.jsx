import { createContext, useContext, useState } from 'react'
import { getCurrentMonth } from '../lib/formatters'

const AppContext = createContext(null)

export function AppProvider({ children }) {
  const [selectedMonth, setSelectedMonth] = useState(getCurrentMonth)
  const [showAddForm, setShowAddForm] = useState(false)

  return (
    <AppContext.Provider value={{ selectedMonth, setSelectedMonth, showAddForm, setShowAddForm }}>
      {children}
    </AppContext.Provider>
  )
}

export const useApp = () => {
  const ctx = useContext(AppContext)
  if (!ctx) throw new Error('useApp must be used inside AppProvider')
  return ctx
}
