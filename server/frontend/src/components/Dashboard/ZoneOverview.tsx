import { useQuery } from '@tanstack/react-query'
import { insightsApi } from '../../api'
import { Card, CardTitle } from '../ui/Card'
import { StatusBadge } from '../ui/Badge'

export function ZoneOverview() {
  const { data } = useQuery({
    queryKey: ['insights'],
    queryFn: insightsApi.get,
    refetchInterval: 5000,
  })

  if (!data?.zone_summaries.length) return null

  return (
    <div className="grid gap-4 md:grid-cols-2">
      {data.zone_summaries.map((zone) => (
        <Card key={zone.zone_id}>
          <div className="mb-3 flex items-center justify-between">
            <CardTitle>{zone.zone_name}</CardTitle>
            <StatusBadge status={zone.theft_status} />
          </div>
          <div className="grid grid-cols-2 gap-3 text-sm">
            <Stat label="Feeders" value={String(zone.feeder_count)} />
            <Stat label="Consumers" value={String(zone.consumer_count)} />
            <Stat label="Feeder Power" value={`${zone.feeder_power} W`} />
            <Stat label="Consumer Power" value={`${zone.consumer_power} W`} />
          </div>
          <p className="mt-3 text-xs text-slate-400">Power gap: {zone.power_diff} W</p>
        </Card>
      ))}
    </div>
  )
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <p className="text-xs text-slate-400">{label}</p>
      <p className="font-semibold">{value}</p>
    </div>
  )
}
