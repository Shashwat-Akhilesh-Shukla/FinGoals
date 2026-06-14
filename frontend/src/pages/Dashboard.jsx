import { useQuery } from '@tanstack/react-query'
import { ChevronLeft, ChevronRight, Activity, TrendingUp, TrendingDown } from 'lucide-react'
import { api } from '../lib/api'
import {
  formatINR, formatPct, getMonthLabel, prevMonth, nextMonth,
  isCurrentMonth, verdictColor, verdictBg, verdictBorder, BUCKET_COLORS,
} from '../lib/formatters'
import { useApp } from '../store/AppContext'
import DonutChart from '../components/charts/DonutChart'
import LineChart  from '../components/charts/LineChart'
import Skeleton   from '../components/Skeleton'

// ─── Ratio Card ────────────────────────────────────────────
function RatioCard({ id, label, value, verdict, loading }) {
  if (loading) return <Skeleton height={94} radius={14} />
  const vc = verdictColor(verdict?.color || 'gray')
  const vb = verdictBg(verdict?.color || 'gray')
  const vborder = verdictBorder(verdict?.color || 'gray')

  return (
    <div
      id={id}
      style={{
        background: vb,
        border: `1px solid ${vborder}`,
        borderRadius: '14px',
        padding: '13px 12px',
      }}
    >
      <div style={{ fontSize: '9px', color: 'rgba(255,255,255,0.35)', letterSpacing: '0.09em', fontFamily: 'JetBrains Mono', marginBottom: '8px' }}>
        {label}
      </div>
      <div style={{ fontFamily: 'JetBrains Mono', fontSize: '22px', fontWeight: 700, color: vc, lineHeight: 1 }}>
        {formatPct(value)}
      </div>
      {verdict && (
        <div style={{ fontSize: '9px', letterSpacing: '0.05em', color: vc, marginTop: '7px', fontWeight: 700, opacity: 0.85 }}>
          {verdict.label}
        </div>
      )}
    </div>
  )
}

// ─── Allocation Row ────────────────────────────────────────
function AllocRow({ label, amount, color }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '7px' }}>
        <span style={{ width: '8px', height: '8px', borderRadius: '2px', background: color, flexShrink: 0 }} />
        <span style={{ fontSize: '12px', color: 'var(--text-2)' }}>{label}</span>
      </div>
      <span style={{ fontFamily: 'JetBrains Mono', fontSize: '13px', fontWeight: 600, color: 'var(--text-1)' }}>
        {formatINR(amount)}
      </span>
    </div>
  )
}

// ─── Dashboard Page ────────────────────────────────────────
export default function Dashboard() {
  const { selectedMonth, setSelectedMonth } = useApp()

  const { data: summary, isLoading: sumL } = useQuery({
    queryKey: ['summary', selectedMonth],
    queryFn:  () => api.getSummary(selectedMonth),
  })
  const { data: verdicts, isLoading: verL } = useQuery({
    queryKey: ['verdicts', selectedMonth],
    queryFn:  () => api.getVerdicts(selectedMonth),
  })
  const { data: breakdown } = useQuery({
    queryKey: ['breakdown', selectedMonth],
    queryFn:  () => api.getBreakdown(selectedMonth),
  })
  const { data: trends } = useQuery({
    queryKey: ['trends', 6],
    queryFn:  () => api.getTrends(6),
  })

  const loading = sumL || verL

  const OL = verdicts?.overall_label
  const overallColor = { CRITICAL: 'red', POOR: 'red', AVERAGE: 'amber', GOOD: 'green', EXCELLENT: 'green' }[OL] || 'gray'
  const vc = verdictColor(overallColor)
  const vb = verdictBg(overallColor)
  const vborder = verdictBorder(overallColor)

  const pieData = (breakdown || []).slice(0, 7).map(b => ({
    label: b.category,
    value: b.amount,
    pct:   b.pct,
    color: BUCKET_COLORS[b.bucket] || '#6b7280',
  }))

  const retained = Math.max(0,
    (summary?.income || 0)
    - (summary?.expenses || 0)
    - (summary?.investments || 0)
    - (summary?.savings || 0)
  )

  const hasData = !!(summary?.income || summary?.expenses)

  return (
    <div className="page-enter">
      {/* ── Month Nav ─────────────────────────────────── */}
      <div style={{ padding: '20px 16px 10px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button
          id="prev-month-btn"
          onClick={() => setSelectedMonth(prevMonth(selectedMonth))}
          style={{ padding: '8px', borderRadius: '8px', background: 'var(--surface)', border: '1px solid var(--border)', color: 'var(--text-2)', cursor: 'pointer', display: 'flex' }}
        >
          <ChevronLeft size={16} />
        </button>

        <div style={{ textAlign: 'center' }}>
          <div style={{ fontFamily: 'JetBrains Mono', fontWeight: 700, fontSize: '15px', color: 'var(--text-1)' }}>
            {getMonthLabel(selectedMonth)}
          </div>
          <div style={{ fontSize: '10px', color: 'var(--text-3)', letterSpacing: '0.09em' }}>FINANCIAL REPORT</div>
        </div>

        <button
          id="next-month-btn"
          onClick={() => setSelectedMonth(nextMonth(selectedMonth))}
          disabled={isCurrentMonth(selectedMonth)}
          style={{
            padding: '8px', borderRadius: '8px',
            background: 'var(--surface)', border: '1px solid var(--border)',
            color: isCurrentMonth(selectedMonth) ? 'var(--text-3)' : 'var(--text-2)',
            cursor: isCurrentMonth(selectedMonth) ? 'not-allowed' : 'pointer',
            display: 'flex',
          }}
        >
          <ChevronRight size={16} />
        </button>
      </div>

      <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: '12px' }}>

        {/* ── Net Balance + Overall Verdict ───────────── */}
        {loading ? <Skeleton height={136} radius={20} /> : (
          <div
            id="net-balance-card"
            style={{
              background: vb, border: `1px solid ${vborder}`,
              borderRadius: '20px', padding: '20px',
            }}
          >
            <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: '14px' }}>
              <span style={{ fontSize: '10px', letterSpacing: '0.1em', color: 'rgba(255,255,255,0.35)', fontFamily: 'JetBrains Mono' }}>
                NET BALANCE
              </span>
              <span style={{
                fontSize: '10px', letterSpacing: '0.1em', fontFamily: 'JetBrains Mono', fontWeight: 800,
                color: vc,
                background: `${vc}1a`,
                border: `1px solid ${vc}33`,
                padding: '3px 10px', borderRadius: '6px',
              }}>
                {OL || '—'}
              </span>
            </div>

            <div style={{ fontFamily: 'JetBrains Mono', fontSize: '40px', fontWeight: 700, color: 'var(--text-1)', lineHeight: 1.1 }}>
              {formatINR(summary?.net ?? 0)}
            </div>

            <div style={{ marginTop: '14px', display: 'flex', gap: '20px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
                <TrendingUp size={13} color="var(--green)" />
                <span style={{ fontFamily: 'JetBrains Mono', fontSize: '12px', color: 'var(--text-2)' }}>
                  {formatINR(summary?.income || 0)}
                </span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
                <TrendingDown size={13} color="var(--red)" />
                <span style={{ fontFamily: 'JetBrains Mono', fontSize: '12px', color: 'var(--text-2)' }}>
                  {formatINR(summary?.expenses || 0)}
                </span>
              </div>
            </div>
          </div>
        )}

        {/* ── Ratio Cards ─────────────────────────────── */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '10px' }}>
          <RatioCard id="ratio-savings"     label="SAVINGS"    value={summary?.savings_rate}    verdict={verdicts?.savings}    loading={loading} />
          <RatioCard id="ratio-investment"  label="INVEST"     value={summary?.investment_rate}  verdict={verdicts?.investment}  loading={loading} />
          <RatioCard id="ratio-essentials"  label="ESSENTIALS" value={summary?.essential_ratio}  verdict={verdicts?.expense}    loading={loading} />
        </div>

        {/* ── Allocation Breakdown ─────────────────────── */}
        {hasData && (
          <div style={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: '16px', padding: '16px' }}>
            <div className="section-label">INCOME ALLOCATION</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
              <AllocRow label="Expenses"    amount={summary?.expenses    || 0} color="#ef4444" />
              <AllocRow label="Investments" amount={summary?.investments || 0} color="#3b82f6" />
              <AllocRow label="Savings"     amount={summary?.savings     || 0} color="#8b5cf6" />
              <AllocRow label="Retained"    amount={retained}                  color="#10b981" />
            </div>

            {/* Mini bar */}
            {(summary?.income || 0) > 0 && (
              <div style={{ marginTop: '14px', height: '6px', borderRadius: '3px', overflow: 'hidden', display: 'flex', gap: '2px' }}>
                {[
                  { v: summary?.expenses,    c: '#ef4444' },
                  { v: summary?.investments, c: '#3b82f6' },
                  { v: summary?.savings,     c: '#8b5cf6' },
                  { v: retained,             c: '#10b981' },
                ].map((seg, i) => {
                  const pct = ((seg.v || 0) / summary.income) * 100
                  return pct > 0 ? (
                    <div key={i} style={{ flex: pct, background: seg.c, minWidth: '2px' }} />
                  ) : null
                })}
              </div>
            )}
          </div>
        )}

        {/* ── Expense Donut ────────────────────────────── */}
        {pieData.length > 0 && (
          <div style={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: '16px', padding: '16px' }}>
            <div className="section-label">EXPENSE BREAKDOWN</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
              <DonutChart data={pieData} size={120} />
              <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '8px', minWidth: 0 }}>
                {pieData.slice(0, 6).map(item => (
                  <div key={item.label} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '8px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px', minWidth: 0 }}>
                      <span style={{ width: '7px', height: '7px', borderRadius: '2px', background: item.color, flexShrink: 0 }} />
                      <span style={{ fontSize: '11px', color: 'var(--text-2)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                        {item.label}
                      </span>
                    </div>
                    <span style={{ fontFamily: 'JetBrains Mono', fontSize: '11px', color: 'var(--text-1)', flexShrink: 0, fontWeight: 500 }}>
                      {item.pct}%
                    </span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* ── Trend Chart ──────────────────────────────── */}
        {trends && trends.length >= 2 && (
          <div style={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: '16px', padding: '16px' }}>
            <div className="section-label">6-MONTH TREND</div>
            <LineChart data={trends} />
          </div>
        )}

        {/* ── Empty State ──────────────────────────────── */}
        {!loading && !hasData && (
          <div style={{
            border: '1px dashed var(--border)', borderRadius: '16px',
            padding: '48px 20px', textAlign: 'center', color: 'var(--text-3)',
          }}>
            <Activity size={32} style={{ margin: '0 auto 12px', opacity: 0.3 }} />
            <div style={{ fontSize: '14px', fontWeight: 500, color: 'var(--text-2)' }}>No data for {getMonthLabel(selectedMonth)}</div>
            <div style={{ fontSize: '12px', marginTop: '6px' }}>Tap + to add your first transaction</div>
          </div>
        )}

        <div style={{ height: '4px' }} />
      </div>
    </div>
  )
}
