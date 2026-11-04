import { useQuery } from '@tanstack/react-query'
import { telemetryApi } from '../../api'
import { Card, CardTitle } from '../ui/Card'
import { StatusBadge, TypeBadge } from '../ui/Badge'

export function LiveNodeCards() {
  const { data: nodes = [], isLoading, isError, error, isSuccess } = useQuery({
    queryKey: ['telemetry', 'live'],
    queryFn: telemetryApi.live,
    refetchInterval: 1000,
  })

  return (
    <div className="space-y-3">
      <div className="flex items-center gap-2 text-sm">
        <span
          className={`inline-block h-2.5 w-2.5 rounded-full ${
            isSuccess ? 'bg-emerald-400' : isError ? 'bg-red-400' : isLoading ? 'bg-amber-400 animate-pulse' : 'bg-slate-500'
          }`}
        />
        <span className="text-slate-400">
          {isLoading && 'Connecting to backend...'}
          {isSuccess && `Connected — ${nodes.length} live node(s)`}
          {isError && `Backend error: ${(error as Error)?.message || 'Connection failed'}`}
        </span>
      </div>

      {isError && (
        <Card className="border-red-500/30">
          <p className="text-sm text-red-400">
            Cannot load live nodes. Make sure the Flask backend is running on port 5000
            (<code className="text-red-300">python run.py</code>).
          </p>
        </Card>
      )}

      {!isError && nodes.length === 0 && !isLoading && (
        <Card>
          <p className="text-sm text-slate-400">No nodes found. Add nodes in the Nodes page.</p>
        </Card>
      )}

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {nodes.map((node) => (
        <Card key={node.id}>
          <div className="mb-3 flex items-center justify-between">
            <CardTitle>{node.name}</CardTitle>
            <TypeBadge type={node.type} />
          </div>
          <p className="mb-3 text-xs text-slate-400">{node.zone?.name}</p>
          <div className="grid grid-cols-2 gap-2 text-sm">
            <Metric label="Voltage" value={`${node.reading?.voltage ?? 0} V`} />
            <Metric label="Current" value={`${node.reading?.current ?? 0} A`} />
            <Metric label="Power" value={`${node.reading?.power ?? 0} W`} />
            <Metric label="Energy" value={`${node.reading?.energy ?? 0} kWh`} />
          </div>
          {node.linked_diff && (
            <div className="mt-4 flex items-center justify-between border-t border-slate-800 pt-3">
              <span className="text-xs text-slate-400">Feeder vs consumers</span>
              <StatusBadge status={node.linked_diff.theft} />
            </div>
          )}
        </Card>
        ))}
      </div>
    </div>
  )
}

function Metric({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-lg bg-slate-900/60 px-3 py-2">
      <p className="text-xs text-slate-400">{label}</p>
      <p className="font-medium">{value}</p>
    </div>
  )
}
