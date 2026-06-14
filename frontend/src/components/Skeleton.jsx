export default function Skeleton({ height = 60, radius = 12 }) {
  return (
    <div
      className="skeleton"
      style={{ height, borderRadius: radius, flexShrink: 0 }}
    />
  )
}
