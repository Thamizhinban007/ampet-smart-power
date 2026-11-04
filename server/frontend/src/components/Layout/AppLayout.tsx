import { NavLink, Outlet } from 'react-router-dom'
import { Activity, GitCompare, LayoutDashboard, Map, Network, Zap } from 'lucide-react'
import { cn } from '../../lib/utils'

const links = [
  { to: '/', label: 'Dashboard', icon: LayoutDashboard },
  { to: '/zones', label: 'Zones', icon: Activity },
  { to: '/nodes', label: 'Nodes', icon: Network },
  { to: '/compare', label: 'Compare', icon: GitCompare },
  { to: '/map', label: 'Map', icon: Map },
]

export function AppLayout() {
  return (
    <div className="flex min-h-screen">
      <aside className="flex w-64 flex-col border-r border-slate-800 bg-[#0f172a]">
        <div className="flex items-center gap-2 border-b border-slate-800 px-5 py-5">
          <Zap className="text-blue-400" size={22} />
          <div>
            <p className="text-sm font-bold tracking-wide">AMPET</p>
            <p className="text-xs text-slate-400">Zone & Node Platform</p>
          </div>
        </div>
        <nav className="flex flex-1 flex-col gap-1 p-3">
          {links.map(({ to, label, icon: Icon }) => (
            <NavLink
              key={to}
              to={to}
              end={to === '/'}
              className={({ isActive }) =>
                cn(
                  'flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm transition',
                  isActive
                    ? 'bg-blue-600/20 text-blue-300'
                    : 'text-slate-400 hover:bg-slate-800 hover:text-slate-200',
                )
              }
            >
              <Icon size={18} />
              {label}
            </NavLink>
          ))}
        </nav>
      </aside>
      <main className="flex-1 overflow-auto p-6">
        <Outlet />
      </main>
    </div>
  )
}
