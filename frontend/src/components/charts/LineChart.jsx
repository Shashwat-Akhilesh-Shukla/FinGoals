const W = 340
const H = 150
const PAD = { top: 12, right: 8, bottom: 28, left: 48 }
const IW = W - PAD.left - PAD.right
const IH = H - PAD.top - PAD.bottom

function fmtK(v) {
  if (v >= 10_000_000) return (v / 10_000_000).toFixed(1) + 'Cr'
  if (v >= 100_000)    return (v / 100_000).toFixed(1) + 'L'
  if (v >= 1_000)      return (v / 1_000).toFixed(0) + 'K'
  return v.toFixed(0)
}

function fmtMonth(m) {
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
  const idx = parseInt(m.split('-')[1]) - 1
  return months[idx] || m
}

const LINES = [
  { key: 'income',      color: '#10b981', label: 'Income'   },
  { key: 'expenses',    color: '#ef4444', label: 'Expenses' },
  { key: 'investments', color: '#3b82f6', label: 'Invested' },
]

/**
 * @param {{ month: string, income: number, expenses: number, investments: number }[]} data
 */
export default function LineChart({ data }) {
  if (!data || data.length < 2) return null

  const allVals = data.flatMap(d => LINES.map(l => d[l.key] || 0))
  const maxVal  = Math.max(...allVals, 1)

  const xOf = (i) => PAD.left + (i / (data.length - 1)) * IW
  const yOf = (v) => PAD.top + IH - (v / maxVal) * IH

  const yTicks = [0, 0.25, 0.5, 0.75, 1]

  return (
    <div style={{ width: '100%' }}>
      <svg
        width="100%"
        viewBox={`0 0 ${W} ${H}`}
        style={{ display: 'block', overflow: 'visible' }}
      >
        {/* Grid */}
        {yTicks.map((t, i) => (
          <g key={i}>
            <line
              x1={PAD.left} y1={yOf(maxVal * t)}
              x2={W - PAD.right} y2={yOf(maxVal * t)}
              stroke="rgba(255,255,255,0.04)"
              strokeWidth={1}
            />
            <text
              x={PAD.left - 5}
              y={yOf(maxVal * t) + 3.5}
              textAnchor="end"
              fill="rgba(255,255,255,0.28)"
              fontSize={8}
              fontFamily="JetBrains Mono, monospace"
            >
              {fmtK(maxVal * t)}
            </text>
          </g>
        ))}

        {/* Lines */}
        {LINES.map(({ key, color }) => {
          const points = data.map((d, i) => `${i === 0 ? 'M' : 'L'} ${xOf(i).toFixed(1)} ${yOf(d[key] || 0).toFixed(1)}`).join(' ')
          return (
            <path
              key={key}
              d={points}
              fill="none"
              stroke={color}
              strokeWidth={1.8}
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          )
        })}

        {/* Dots */}
        {LINES.map(({ key, color }) =>
          data.map((d, i) =>
            (d[key] || 0) > 0 ? (
              <circle
                key={`${key}-${i}`}
                cx={xOf(i)}
                cy={yOf(d[key] || 0)}
                r={2.5}
                fill={color}
              />
            ) : null
          )
        )}

        {/* X labels */}
        {data.map((d, i) => (
          <text
            key={i}
            x={xOf(i)}
            y={H - 6}
            textAnchor="middle"
            fill="rgba(255,255,255,0.28)"
            fontSize={8.5}
            fontFamily="JetBrains Mono, monospace"
          >
            {fmtMonth(d.month)}
          </text>
        ))}
      </svg>

      {/* Legend */}
      <div style={{ display: 'flex', gap: '16px', marginTop: '8px', flexWrap: 'wrap' }}>
        {LINES.map(({ color, label }) => (
          <div key={label} style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
            <span style={{ display: 'block', width: '18px', height: '2px', background: color, borderRadius: '1px' }} />
            <span style={{ fontSize: '10px', color: 'var(--text-2)' }}>{label}</span>
          </div>
        ))}
      </div>
    </div>
  )
}
