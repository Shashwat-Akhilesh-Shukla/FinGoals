function polar(cx, cy, r, deg) {
  const rad = (deg - 90) * (Math.PI / 180)
  return { x: cx + r * Math.cos(rad), y: cy + r * Math.sin(rad) }
}

function slicePath(cx, cy, outerR, innerR, startDeg, endDeg) {
  const o1 = polar(cx, cy, outerR, startDeg)
  const o2 = polar(cx, cy, outerR, endDeg)
  const i1 = polar(cx, cy, innerR, startDeg)
  const i2 = polar(cx, cy, innerR, endDeg)
  const large = endDeg - startDeg > 180 ? 1 : 0
  return [
    `M ${o1.x.toFixed(2)} ${o1.y.toFixed(2)}`,
    `A ${outerR} ${outerR} 0 ${large} 1 ${o2.x.toFixed(2)} ${o2.y.toFixed(2)}`,
    `L ${i2.x.toFixed(2)} ${i2.y.toFixed(2)}`,
    `A ${innerR} ${innerR} 0 ${large} 0 ${i1.x.toFixed(2)} ${i1.y.toFixed(2)}`,
    'Z',
  ].join(' ')
}

/**
 * @param {{ label: string, value: number, pct: number, color: string }[]} data
 * @param {number} size
 */
export default function DonutChart({ data, size = 130 }) {
  if (!data || data.length === 0) return null

  const cx = size / 2
  const cy = size / 2
  const outerR = size * 0.44
  const innerR = size * 0.29
  const total  = data.reduce((s, d) => s + d.value, 0)
  if (total === 0) return null

  const GAP = 1.5 // degrees between slices
  let current = 0

  const slices = data.map((d) => {
    const span  = (d.value / total) * 360
    const start = current
    const end   = current + span - (span > 5 ? GAP : 0)
    current    += span
    return { ...d, path: slicePath(cx, cy, outerR, innerR, start, end) }
  })

  return (
    <svg
      width={size}
      height={size}
      viewBox={`0 0 ${size} ${size}`}
      style={{ overflow: 'visible', flexShrink: 0 }}
    >
      {slices.map((s, i) => (
        <path key={i} d={s.path} fill={s.color} opacity={0.88} />
      ))}
    </svg>
  )
}
