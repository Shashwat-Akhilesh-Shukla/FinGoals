const BASE = '/api'

async function req(path, options = {}) {
  const res = await fetch(`${BASE}${path}`, {
    headers: { 'Content-Type': 'application/json', ...options.headers },
    ...options,
  })
  if (!res.ok) {
    const text = await res.text()
    throw new Error(text || `HTTP ${res.status}`)
  }
  if (res.status === 204) return null
  return res.json()
}

export const api = {
  // ── Transactions ──────────────────────────────
  getTransactions: (params = {}) => {
    const clean = Object.fromEntries(Object.entries(params).filter(([, v]) => v !== '' && v != null))
    const q = new URLSearchParams(clean).toString()
    return req(`/transactions${q ? '?' + q : ''}`)
  },
  createTransaction: (data) =>
    req('/transactions', { method: 'POST', body: JSON.stringify(data) }),
  updateTransaction: (id, data) =>
    req(`/transactions/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
  deleteTransaction: (id) =>
    req(`/transactions/${id}`, { method: 'DELETE' }),
  importCSV: async (file) => {
    const fd = new FormData()
    fd.append('file', file)
    const res = await fetch(`${BASE}/transactions/import`, { method: 'POST', body: fd })
    return res.json()
  },

  // ── Categories ────────────────────────────────
  getCategories: () => req('/transactions/categories'),
  createCategory: (data) =>
    req('/transactions/categories', { method: 'POST', body: JSON.stringify(data) }),
  deleteCategory: (id) =>
    req(`/transactions/categories/${id}`, { method: 'DELETE' }),

  // ── Analytics ─────────────────────────────────
  getSummary: (month) =>
    req(`/analytics/summary${month ? '?month=' + month : ''}`),
  getVerdicts: (month) =>
    req(`/analytics/verdicts${month ? '?month=' + month : ''}`),
  getTrends: (months = 6) =>
    req(`/analytics/trends?months=${months}`),
  getBreakdown: (month) =>
    req(`/analytics/breakdown${month ? '?month=' + month : ''}`),

  // ── Goals ─────────────────────────────────────
  getGoals: () => req('/goals'),
  createGoal: (data) =>
    req('/goals', { method: 'POST', body: JSON.stringify(data) }),
  updateGoal: (id, data) =>
    req(`/goals/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
  deleteGoal: (id) =>
    req(`/goals/${id}`, { method: 'DELETE' }),

  // ── Export ────────────────────────────────────
  exportCSV:       () => window.open(`${BASE}/export/csv`),
  exportJSON:      () => window.open(`${BASE}/export/json`),
  downloadBackup:  () => window.open(`${BASE}/export/backup`),
}
