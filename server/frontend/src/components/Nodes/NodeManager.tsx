import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Pencil, Plus, Trash2 } from 'lucide-react'
import { useMemo, useState } from 'react'
import { nodesApi, zonesApi } from '../../api'
import type { Node } from '../../api/types'
import { TypeBadge } from '../ui/Badge'
import { Button } from '../ui/Button'
import { Card } from '../ui/Card'
import { Input, Label, Select } from '../ui/Input'
import { Modal } from '../ui/Modal'

const emptyNode: Partial<Node> = {
  name: '',
  type: 'consumer',
  zone_id: 0,
  parent_node_id: null,
  latitude: 28.6139,
  longitude: 77.209,
  status: 'ACTIVE',
}

export function NodeManager() {
  const qc = useQueryClient()
  const [zoneFilter, setZoneFilter] = useState<number | ''>('')
  const [typeFilter, setTypeFilter] = useState<string>('')
  const [open, setOpen] = useState(false)
  const [editing, setEditing] = useState<Node | null>(null)
  const [form, setForm] = useState<Partial<Node>>(emptyNode)

  const { data: zones = [] } = useQuery({ queryKey: ['zones'], queryFn: zonesApi.list })

  const queryParams = useMemo(
    () => ({
      zone_id: zoneFilter || undefined,
      type: typeFilter || undefined,
    }),
    [zoneFilter, typeFilter],
  )

  const { data: nodes = [], isLoading } = useQuery({
    queryKey: ['nodes', queryParams],
    queryFn: () => nodesApi.list(queryParams),
    refetchInterval: 3000,
  })

  const { data: allNodes = [] } = useQuery({
    queryKey: ['nodes'],
    queryFn: () => nodesApi.list(),
  })

  const feeders = allNodes.filter((n) => n.type === 'feeder')

  const saveMutation = useMutation({
    mutationFn: async () => {
      if (editing) return nodesApi.update(editing.id, form)
      return nodesApi.create(form)
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['nodes'] })
      qc.invalidateQueries({ queryKey: ['telemetry'] })
      qc.invalidateQueries({ queryKey: ['insights'] })
      closeModal()
    },
  })

  const deleteMutation = useMutation({
    mutationFn: (id: number) => nodesApi.remove(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['nodes'] })
      qc.invalidateQueries({ queryKey: ['telemetry'] })
      qc.invalidateQueries({ queryKey: ['insights'] })
    },
  })

  function openCreate() {
    setEditing(null)
    setForm({ ...emptyNode, zone_id: zones[0]?.id ?? 0 })
    setOpen(true)
  }

  function openEdit(node: Node) {
    setEditing(node)
    setForm(node)
    setOpen(true)
  }

  function closeModal() {
    setOpen(false)
    setEditing(null)
    setForm(emptyNode)
  }

  return (
    <>
      <div className="mb-6 flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold">Nodes</h1>
          <p className="text-sm text-slate-400">Feeders and consumers linked by zone</p>
        </div>
        <Button onClick={openCreate}>
          <Plus size={16} /> Add Node
        </Button>
      </div>

      <div className="mb-4 flex flex-wrap gap-3">
        <Select
          value={zoneFilter}
          onChange={(e) => setZoneFilter(e.target.value ? Number(e.target.value) : '')}
          className="w-48"
        >
          <option value="">All Zones</option>
          {zones.map((z) => (
            <option key={z.id} value={z.id}>
              {z.name}
            </option>
          ))}
        </Select>
        <Select value={typeFilter} onChange={(e) => setTypeFilter(e.target.value)} className="w-40">
          <option value="">All Types</option>
          <option value="feeder">Feeder</option>
          <option value="consumer">Consumer</option>
        </Select>
      </div>

      <Card>
        {isLoading ? (
          <p className="text-slate-400">Loading nodes...</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="border-b border-slate-800 text-xs uppercase text-slate-400">
                <tr>
                  <th className="pb-3 pr-4">Name</th>
                  <th className="pb-3 pr-4">Type</th>
                  <th className="pb-3 pr-4">Zone</th>
                  <th className="pb-3 pr-4">Feeder Link</th>
                  <th className="pb-3 pr-4">Power</th>
                  <th className="pb-3 pr-4">Location</th>
                  <th className="pb-3">Actions</th>
                </tr>
              </thead>
              <tbody>
                {nodes.map((node) => {
                  const parent = allNodes.find((n) => n.id === node.parent_node_id)
                  return (
                    <tr key={node.id} className="border-b border-slate-800/60">
                      <td className="py-3 pr-4 font-medium">{node.name}</td>
                      <td className="py-3 pr-4">
                        <TypeBadge type={node.type} />
                      </td>
                      <td className="py-3 pr-4 text-slate-400">{node.zone?.name}</td>
                      <td className="py-3 pr-4 text-slate-400">{parent?.name || '—'}</td>
                      <td className="py-3 pr-4">{node.reading?.power ?? 0} W</td>
                      <td className="py-3 pr-4 text-slate-400">
                        {node.latitude.toFixed(4)}, {node.longitude.toFixed(4)}
                      </td>
                      <td className="py-3">
                        <div className="flex gap-2">
                          <Button variant="ghost" onClick={() => openEdit(node)}>
                            <Pencil size={14} />
                          </Button>
                          <Button variant="ghost" onClick={() => deleteMutation.mutate(node.id)}>
                            <Trash2 size={14} className="text-red-400" />
                          </Button>
                        </div>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      <Modal open={open} title={editing ? 'Edit Node' : 'Create Node'} onClose={closeModal}>
        <form
          className="space-y-4"
          onSubmit={(e) => {
            e.preventDefault()
            saveMutation.mutate()
          }}
        >
          <div>
            <Label>Name</Label>
            <Input value={form.name || ''} onChange={(e) => setForm({ ...form, name: e.target.value })} required />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <Label>Type</Label>
              <Select
                value={form.type || 'consumer'}
                onChange={(e) =>
                  setForm({
                    ...form,
                    type: e.target.value as 'feeder' | 'consumer',
                    parent_node_id: e.target.value === 'feeder' ? null : form.parent_node_id,
                  })
                }
              >
                <option value="feeder">Feeder</option>
                <option value="consumer">Consumer</option>
              </Select>
            </div>
            <div>
              <Label>Zone</Label>
              <Select
                value={form.zone_id || ''}
                onChange={(e) => setForm({ ...form, zone_id: Number(e.target.value) })}
                required
              >
                {zones.map((z) => (
                  <option key={z.id} value={z.id}>
                    {z.name}
                  </option>
                ))}
              </Select>
            </div>
          </div>
          {form.type === 'consumer' && (
            <div>
              <Label>Linked Feeder</Label>
              <Select
                value={form.parent_node_id ?? ''}
                onChange={(e) =>
                  setForm({
                    ...form,
                    parent_node_id: e.target.value ? Number(e.target.value) : null,
                  })
                }
              >
                <option value="">None</option>
                {feeders.map((f) => (
                  <option key={f.id} value={f.id}>
                    {f.name}
                  </option>
                ))}
              </Select>
            </div>
          )}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <Label>Latitude</Label>
              <Input
                type="number"
                step="any"
                value={form.latitude ?? 0}
                onChange={(e) => setForm({ ...form, latitude: parseFloat(e.target.value) })}
              />
            </div>
            <div>
              <Label>Longitude</Label>
              <Input
                type="number"
                step="any"
                value={form.longitude ?? 0}
                onChange={(e) => setForm({ ...form, longitude: parseFloat(e.target.value) })}
              />
            </div>
          </div>
          {saveMutation.isError && (
            <p className="text-sm text-red-400">{(saveMutation.error as Error).message}</p>
          )}
          <div className="flex justify-end gap-2">
            <Button type="button" variant="secondary" onClick={closeModal}>
              Cancel
            </Button>
            <Button type="submit" disabled={saveMutation.isPending}>
              {saveMutation.isPending ? 'Saving...' : 'Save'}
            </Button>
          </div>
        </form>
      </Modal>
    </>
  )
}
