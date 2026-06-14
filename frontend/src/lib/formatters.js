// ── Currency ──────────────────────────────────────────────
export function formatINR(amount) {
  if (amount === undefined || amount === null) return '₹—'
  const abs = Math.abs(amount)
  let formatted
  if (abs >= 10_000_000)      formatted = (abs / 10_000_000).toFixed(2) + ' Cr'
  else if (abs >= 100_000)    formatted = (abs / 100_000).toFixed(2) + ' L'
  else if (abs >= 1_000)      formatted = (abs / 1_000).toFixed(1) + 'K'
  else                        formatted = abs.toLocaleString('en-IN', { maximumFractionDigits: 0 })
  return (amount < 0 ? '-' : '') + '₹' + formatted
}

export function formatINRFull(amount) {
  if (amount === undefined || amount === null) return '₹—'
  return '₹' + Math.abs(amount).toLocaleString('en-IN', { minimumFractionDigits: 0, maximumFractionDigits: 2 })
}

// ── Percentage ────────────────────────────────────────────
export function formatPct(value) {
  if (value === undefined || value === null) return '—%'
  return value.toFixed(1) + '%'
}

// ── Dates ─────────────────────────────────────────────────
const MONTHS = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']

export function getMonthLabel(monthStr) {
  if (!monthStr) return ''
  const [y, m] = monthStr.split('-')
  return `${MONTHS[parseInt(m) - 1]} ${y}`
}

export function getCurrentMonth() {
  const now = new Date()
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`
}

export function prevMonth(monthStr) {
  const [y, m] = monthStr.split('-').map(Number)
  const d = new Date(y, m - 2, 1)
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`
}

export function nextMonth(monthStr) {
  const [y, m] = monthStr.split('-').map(Number)
  const d = new Date(y, m, 1)
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`
}

export function isCurrentMonth(monthStr) {
  return monthStr === getCurrentMonth()
}

export function formatDate(dateStr) {
  if (!dateStr) return ''
  const d = new Date(dateStr)
  return d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' })
}

export function formatDateTime(dateStr) {
  if (!dateStr) return ''
  const d = new Date(dateStr)
  return d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })
}

// ── Verdict helpers ───────────────────────────────────────
const VERDICT_COLORS = {
  green:   '#10b981',
  emerald: '#10b981',
  amber:   '#f59e0b',
  red:     '#ef4444',
  gray:    '#555555',
}

const VERDICT_BG = {
  green:   'rgba(16, 185, 129, 0.09)',
  emerald: 'rgba(16, 185, 129, 0.09)',
  amber:   'rgba(245, 158, 11, 0.09)',
  red:     'rgba(239, 68, 68, 0.09)',
  gray:    'rgba(85, 85, 85, 0.09)',
}

const VERDICT_BORDER = {
  green:   'rgba(16, 185, 129, 0.22)',
  emerald: 'rgba(16, 185, 129, 0.22)',
  amber:   'rgba(245, 158, 11, 0.22)',
  red:     'rgba(239, 68, 68, 0.22)',
  gray:    'rgba(85, 85, 85, 0.22)',
}

export const verdictColor  = (c) => VERDICT_COLORS[c]  || VERDICT_COLORS.gray
export const verdictBg     = (c) => VERDICT_BG[c]      || VERDICT_BG.gray
export const verdictBorder = (c) => VERDICT_BORDER[c]  || VERDICT_BORDER.gray

// ── Transaction types ─────────────────────────────────────
export const TYPE_META = {
  income:     { label: 'Income',     color: '#10b981', bg: 'rgba(16,185,129,0.10)',  sign: '+' },
  expense:    { label: 'Expense',    color: '#ef4444', bg: 'rgba(239,68,68,0.10)',   sign: '-' },
  investment: { label: 'Investment', color: '#3b82f6', bg: 'rgba(59,130,246,0.10)',  sign: '-' },
  savings:    { label: 'Savings',    color: '#8b5cf6', bg: 'rgba(139,92,246,0.10)',  sign: '-' },
}

export function getTypeMeta(type) {
  return TYPE_META[type] || { label: type, color: '#555', bg: 'rgba(85,85,85,0.10)', sign: '' }
}

// ── Chart colors ──────────────────────────────────────────
export const BUCKET_COLORS = {
  essentials:  '#3b82f6',
  lifestyle:   '#8b5cf6',
  investments: '#10b981',
  savings:     '#f59e0b',
  income:      '#14b8a6',
  other:       '#6b7280',
}
