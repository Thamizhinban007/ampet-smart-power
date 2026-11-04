import { useQuery } from '@tanstack/react-query'
import { Brain, ShieldAlert } from 'lucide-react'
import { insightsApi } from '../../api'
import { Card, CardTitle } from '../ui/Card'
import { StatusBadge } from '../ui/Badge'

export function AIInsightsPanel() {
  const { data, isLoading } = useQuery({
    queryKey: ['insights'],
    queryFn: insightsApi.get,
    refetchInterval: 5000,
  })

  if (isLoading || !data) {
    return (
      <Card className="border-blue-500/20 bg-gradient-to-r from-blue-950/40 to-slate-900">
        <CardTitle>AI Insights</CardTitle>
        <p className="text-sm text-slate-400">Analyzing network data...</p>
      </Card>
    )
  }

  return (
    <Card className="border-blue-500/20 bg-gradient-to-r from-blue-950/40 to-slate-900">
      <div className="mb-4 flex items-start justify-between gap-4">
        <div className="flex items-center gap-2">
          <Brain className="text-blue-400" size={20} />
          <CardTitle>AI Insights</CardTitle>
        </div>
        <div className="text-right">
          <p className="text-xs uppercase text-slate-400">System Health</p>
          <p className="text-2xl font-bold text-emerald-400">{data.overall_health}%</p>
        </div>
      </div>
      <p className="mb-4 text-sm leading-relaxed text-slate-300">{data.summary}</p>
      {data.alerts.length > 0 && (
        <div className="mb-4 space-y-2">
          {data.alerts.map((alert) => (
            <div key={alert.zone_id} className="flex items-center gap-2 rounded-lg bg-slate-900/60 px-3 py-2 text-sm">
              <ShieldAlert size={16} className="text-amber-400" />
              <span>{alert.message}</span>
              <StatusBadge status={alert.severity} />
            </div>
          ))}
        </div>
      )}
      {data.recommendations.length > 0 && (
        <div>
          <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400">Recommendations</p>
          <ul className="space-y-1 text-sm text-slate-300">
            {data.recommendations.slice(0, 3).map((rec) => (
              <li key={rec.node_id}>• {rec.message}</li>
            ))}
          </ul>
        </div>
      )}
    </Card>
  )
}
