import { useQuery } from '@tanstack/react-query'
import { useEffect, useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { compareApi, nodesApi } from '../../api'
import type { Node } from '../../api/types'
import { StatusBadge, TypeBadge } from '../ui/Badge'
import { Card, CardTitle } from '../ui/Card'
import { Label, Select } from '../ui/Input'

export function ComparePanel() {
  const [searchParams] = useSearchParams()
  const [nodeA, setNodeA] = useState<number | ''>('')
  const [nodeB, setNodeB] = useState<number | ''>('')

  const { data: nodes = [] } = useQuery({
    queryKey: ['nodes'],
    queryFn: () => nodesApi.list(),
  })

  useEffect(() => {
    const a = searchParams.get('a')
    const b = searchParams.get('b')
    if (a) setNodeA(Number(a))
    if (b) setNodeB(Number(b))
  }, [searchParams])

  const { data: result, isFetching } = useQuery({
    queryKey: ['compare', nodeA, nodeB],
    queryFn: () => compareApi.nodes(nodeA as number, nodeB as number),
    enabled: typeof nodeA === 'number' && typeof nodeB === 'number' && nodeA !== nodeB,
  })

  return (
    <>
      <div className="mb-6">
        <h1 className="text-2xl font-bold">Compare Nodes</h1>
        <p className="text-sm text-slate-400">Select any two nodes to analyze power and energy difference</p>
      </div>

      <Card className="mb-6">
        <div className="grid gap-4 md:grid-cols-2">
          <div>
            <Label>Node A</Label>
            <Select value={nodeA} onChange={(e) => setNodeA(e.target.value ? Number(e.target.value) : '')}>
              <option value="">Select node...</option>
              {nodes.map((n) => (
                <option key={n.id} value={n.id}>
                  {n.name} ({n.type})
                </option>
              ))}
            </Select>
          </div>
          <div>
            <Label>Node B</Label>
            <Select value={nodeB} onChange={(e) => setNodeB(e.target.value ? Number(e.target.value) : '')}>
              <option value="">Select node...</option>
              {nodes.map((n) => (
                <option key={n.id} value={n.id}>
                  {n.name} ({n.type})
                </option>
              ))}
            </Select>
          </div>
        </div>
      </Card>

      {nodeA && nodeB && nodeA === nodeB && (
        <p className="text-amber-400">Please select two different nodes.</p>
      )}

      {isFetching && <p className="text-slate-400">Comparing nodes...</p>}

      {result && (
        <div className="space-y-4">
          <div className="flex items-center justify-center">
            <StatusBadge status={result.theft} />
          </div>
          <div className="grid gap-4 md:grid-cols-2">
            <NodeDetailCard label="Node A" node={result.node_a} />
            <NodeDetailCard label="Node B" node={result.node_b} />
          </div>
          <Card>
            <CardTitle>Difference (A − B)</CardTitle>
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div>
                <p className="text-slate-400">Power</p>
                <p className="text-xl font-bold">{result.difference.power} W</p>
              </div>
              <div>
                <p className="text-slate-400">Energy</p>
                <p className="text-xl font-bold">{result.difference.energy} kWh</p>
              </div>
            </div>
          </Card>
        </div>
      )}
    </>
  )
}

function NodeDetailCard({ label, node }: { label: string; node: Node }) {
  return (
    <Card>
      <p className="mb-2 text-xs uppercase text-slate-400">{label}</p>
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
    </Card>
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
