import { NavLink } from 'react-router-dom'
import { LayoutDashboard, ArrowLeftRight, Target, Settings } from 'lucide-react'

const NAV = [
  { to: '/dashboard',    Icon: LayoutDashboard, label: 'Dashboard'    },
  { to: '/transactions', Icon: ArrowLeftRight,   label: 'Transactions' },
  { to: '/goals',        Icon: Target,           label: 'Goals'        },
  { to: '/settings',     Icon: Settings,         label: 'Settings'     },
]

export default function BottomNav() {
  return (
    <nav
      id="bottom-nav"
      style={{
        position: 'fixed',
        bottom: 0,
        left: '50%',
        transform: 'translateX(-50%)',
        width: '100%',
        maxWidth: '480px',
        background: 'rgba(8, 8, 8, 0.96)',
        backdropFilter: 'blur(20px)',
        WebkitBackdropFilter: 'blur(20px)',
        borderTop: '1px solid var(--border)',
        display: 'grid',
        gridTemplateColumns: 'repeat(4, 1fr)',
        zIndex: 100,
        paddingBottom: 'env(safe-area-inset-bottom, 0px)',
      }}
    >
      {NAV.map(({ to, Icon, label }) => (
        <NavLink
          key={to}
          to={to}
          id={`nav-${label.toLowerCase()}`}
          style={({ isActive }) => ({
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '12px 0 10px',
            gap: '3px',
            color: isActive ? 'var(--green)' : 'var(--text-3)',
            textDecoration: 'none',
            transition: 'color 0.15s',
            fontSize: '10px',
            fontWeight: 500,
          })}
        >
          {({ isActive }) => (
            <>
              <Icon
                size={20}
                strokeWidth={isActive ? 2.5 : 1.8}
                style={{ transition: 'transform 0.15s' }}
              />
              <span style={{ fontSize: '10px', fontWeight: isActive ? 600 : 400 }}>
                {label}
              </span>
            </>
          )}
        </NavLink>
      ))}
    </nav>
  )
}
