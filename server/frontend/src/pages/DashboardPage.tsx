import { AIInsightsPanel } from '../components/AIInsights/AIInsightsPanel'
import { LiveNodeCards } from '../components/Dashboard/LiveNodeCards'
import { ZoneOverview } from '../components/Dashboard/ZoneOverview'

export function DashboardPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Dashboard</h1>
        <p className="text-sm text-slate-400">Live monitoring across zones and nodes</p>
      </div>
      <AIInsightsPanel />
      <div>
        <h2 className="mb-3 text-lg font-semibold">Zone Overview</h2>
        <ZoneOverview />
      </div>
      <div>
        <h2 className="mb-3 text-lg font-semibold">Live Nodes</h2>
        <LiveNodeCards />
      </div>
    </div>
  )
}
