import { api } from './client'
import type { CompareResult, Insights, Node, Zone } from './types'

export const zonesApi = {
  list: () => api.get<Zone[]>('/api/zones'),
  get: (id: number) => api.get<Zone>(`/api/zones/${id}`),
  create: (data: Partial<Zone>) => api.post<Zone>('/api/zones', data),
  update: (id: number, data: Partial<Zone>) => api.put<Zone>(`/api/zones/${id}`, data),
  remove: (id: number) => api.delete<{ status: string }>(`/api/zones/${id}`),
}

export const nodesApi = {
  list: (params?: { zone_id?: number; type?: string }) => {
    const q = new URLSearchParams()
    if (params?.zone_id) q.set('zone_id', String(params.zone_id))
    if (params?.type) q.set('type', params.type)
    const qs = q.toString()
    return api.get<Node[]>(`/api/nodes${qs ? `?${qs}` : ''}`)
  },
  get: (id: number) => api.get<Node>(`/api/nodes/${id}`),
  create: (data: Partial<Node> & { reading?: Partial<Node['reading']> }) =>
    api.post<Node>('/api/nodes', data),
  update: (id: number, data: Partial<Node>) => api.put<Node>(`/api/nodes/${id}`, data),
  remove: (id: number) => api.delete<{ status: string }>(`/api/nodes/${id}`),
}

export const telemetryApi = {
  live: () => api.get<Node[]>('/api/telemetry/live'),
}

export const compareApi = {
  nodes: (a: number, b: number) => api.get<CompareResult>(`/api/nodes/compare?a=${a}&b=${b}`),
}

export const insightsApi = {
  get: () => api.get<Insights>('/api/insights'),
}
