import { useQuery } from '@tanstack/react-query'
import L from 'leaflet'
import { useMemo, useState } from 'react'
import { MapContainer, Marker, Popup, TileLayer } from 'react-leaflet'
import { useNavigate } from 'react-router-dom'
import { nodesApi } from '../../api'
import type { Node } from '../../api/types'
import { TypeBadge } from '../ui/Badge'
import { Button } from '../ui/Button'
import { Card } from '../ui/Card'

import markerIcon2x from 'leaflet/dist/images/marker-icon-2x.png'
import markerIcon from 'leaflet/dist/images/marker-icon.png'
import markerShadow from 'leaflet/dist/images/marker-shadow.png'

delete (L.Icon.Default.prototype as unknown as { _getIconUrl?: unknown })._getIconUrl
L.Icon.Default.mergeOptions({
  iconRetinaUrl: markerIcon2x,
  iconUrl: markerIcon,
  shadowUrl: markerShadow,
})

export function NetworkMap() {
  const navigate = useNavigate()
  const [selected, setSelected] = useState<Node[]>([])

  const { data: nodes = [] } = useQuery({
    queryKey: ['nodes'],
    queryFn: () => nodesApi.list(),
    refetchInterval: 5000,
  })

  const center = useMemo(() => {
    if (!nodes.length) return [28.6139, 77.209] as [number, number]
    const lat = nodes.reduce((s, n) => s + n.latitude, 0) / nodes.length
    const lng = nodes.reduce((s, n) => s + n.longitude, 0) / nodes.length
    return [lat, lng] as [number, number]
  }, [nodes])

  function toggleSelect(node: Node, shiftKey: boolean) {
    if (shiftKey) {
      setSelected((prev) => {
        const exists = prev.find((n) => n.id === node.id)
        if (exists) return prev.filter((n) => n.id !== node.id)
        if (prev.length >= 2) return [prev[1], node]
        return [...prev, node]
      })
    } else {
      setSelected([node])
    }
  }

  function compareSelected() {
    if (selected.length === 2) {
      navigate(`/compare?a=${selected[0].id}&b=${selected[1].id}`)
    }
  }

  return (
    <>
      <div className="mb-6 flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold">Network Map</h1>
          <p className="text-sm text-slate-400">
            Click a marker for details. Shift+click to select up to two nodes for comparison.
          </p>
        </div>
        {selected.length === 2 && (
          <Button onClick={compareSelected}>Compare Selected Nodes</Button>
        )}
      </div>

      {selected.length > 0 && (
        <Card className="mb-4">
          <p className="text-sm text-slate-300">
            Selected: {selected.map((n) => n.name).join(' & ')} ({selected.length}/2)
          </p>
        </Card>
      )}

      <div className="h-[600px] overflow-hidden rounded-xl border border-slate-800">
        <MapContainer center={center} zoom={14} className="h-full w-full">
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />
          {nodes.map((node) => (
            <Marker
              key={node.id}
              position={[node.latitude, node.longitude]}
              eventHandlers={{
                click: (e) => toggleSelect(node, e.originalEvent.shiftKey),
              }}
            >
              <Popup>
                <div className="text-sm">
                  <p className="font-semibold">{node.name}</p>
                  <TypeBadge type={node.type} />
                  <p className="mt-2">{node.zone?.name}</p>
                  <p>Power: {node.reading?.power ?? 0} W</p>
                </div>
              </Popup>
            </Marker>
          ))}
        </MapContainer>
      </div>
    </>
  )
}
