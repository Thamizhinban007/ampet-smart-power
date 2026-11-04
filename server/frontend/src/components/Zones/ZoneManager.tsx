import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Pencil, Plus, Trash2 } from 'lucide-react'
import { useState } from 'react'
import { zonesApi } from '../../api'
import type { Zone } from '../../api/types'
import { Button } from '../ui/Button'
import { Card } from '../ui/Card'
import { Input, Label, Textarea } from '../ui/Input'
import { Modal } from '../ui/Modal'

const emptyZone: Partial<Zone> = {
  name: '',
  code: '',
  description: '',
  latitude: 28.6139,
  longitude: 77.209,
}

export function ZoneManager() {
  const qc = useQueryClient()
  const [open, setOpen] = useState(false)
  const [editing, setEditing] = useState<Zone | null>(null)
  const [form, setForm] = useState<Partial<Zone>>(emptyZone)

  const { data: zones = [], isLoading } = useQuery({
    queryKey: ['zones'],
    queryFn: zonesApi.list,
  })

  const saveMutation = useMutation({
    mutationFn: async () => {
      if (editing) return zonesApi.update(editing.id, form)
      return zonesApi.create(form)
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['zones'] })
      qc.invalidateQueries({ queryKey: ['insights'] })
      closeModal()
    },
  })

  const deleteMutation = useMutation({
    mutationFn: (id: number) => zonesApi.remove(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['zones'] })
      qc.invalidateQueries({ queryKey: ['nodes'] })
      qc.invalidateQueries({ queryKey: ['insights'] })
    },
  })

  function openCreate() {
    setEditing(null)
    setForm(emptyZone)
    setOpen(true)
  }

  function openEdit(zone: Zone) {
    setEditing(zone)
    setForm(zone)
    setOpen(true)
  }

  function closeModal() {
    setOpen(false)
    setEditing(null)
    setForm(emptyZone)
  }

  return (
    <>
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Zones</h1>
          <p className="text-sm text-slate-400">Manage service areas and locations</p>
        </div>
        <Button onClick={openCreate}>
          <Plus size={16} /> Add Zone
        </Button>
      </div>

      <Card>
        {isLoading ? (
          <p className="text-slate-400">Loading zones...</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="border-b border-slate-800 text-xs uppercase text-slate-400">
                <tr>
                  <th className="pb-3 pr-4">Name</th>
                  <th className="pb-3 pr-4">Code</th>
                  <th className="pb-3 pr-4">Nodes</th>
                  <th className="pb-3 pr-4">Location</th>
                  <th className="pb-3">Actions</th>
                </tr>
              </thead>
              <tbody>
                {zones.map((zone) => (
                  <tr key={zone.id} className="border-b border-slate-800/60">
                    <td className="py-3 pr-4 font-medium">{zone.name}</td>
                    <td className="py-3 pr-4 text-slate-400">{zone.code}</td>
                    <td className="py-3 pr-4">{zone.node_count ?? 0}</td>
                    <td className="py-3 pr-4 text-slate-400">
                      {zone.latitude.toFixed(4)}, {zone.longitude.toFixed(4)}
                    </td>
                    <td className="py-3">
                      <div className="flex gap-2">
                        <Button variant="ghost" onClick={() => openEdit(zone)}>
                          <Pencil size={14} />
                        </Button>
                        <Button variant="ghost" onClick={() => deleteMutation.mutate(zone.id)}>
                          <Trash2 size={14} className="text-red-400" />
                        </Button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      <Modal open={open} title={editing ? 'Edit Zone' : 'Create Zone'} onClose={closeModal}>
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
          <div>
            <Label>Code</Label>
            <Input value={form.code || ''} onChange={(e) => setForm({ ...form, code: e.target.value })} required />
          </div>
          <div>
            <Label>Description</Label>
            <Textarea
              value={form.description || ''}
              onChange={(e) => setForm({ ...form, description: e.target.value })}
              rows={3}
            />
          </div>
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
