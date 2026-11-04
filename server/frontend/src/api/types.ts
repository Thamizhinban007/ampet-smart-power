export interface Zone {
  id: number
  name: string
  code: string
  description: string
  latitude: number
  longitude: number
  created_at: string | null
  node_count?: number
}

export interface Reading {
  id: number
  node_id: number
  voltage: number
  current: number
  power: number
  energy: number
  recorded_at: string | null
}

export interface Node {
  id: number
  zone_id: number
  name: string
  type: 'feeder' | 'consumer'
  parent_node_id: number | null
  latitude: number
  longitude: number
  status: string
  created_at: string | null
  reading?: Reading | null
  zone?: Zone
  linked_diff?: {
    power: number
    energy: number
    theft: string
  }
}

export interface CompareResult {
  node_a: Node
  node_b: Node
  difference: { power: number; energy: number }
  theft: string
}

export interface ZoneSummary {
  zone_id: number
  zone_name: string
  feeder_count: number
  consumer_count: number
  feeder_power: number
  consumer_power: number
  power_diff: number
  theft_status: string
}

export interface Insights {
  overall_health: number
  zone_summaries: ZoneSummary[]
  alerts: Array<{ zone_id: number; zone_name: string; severity: string; message: string }>
  recommendations: Array<{ zone_id: number; node_id: number; node_name: string; message: string }>
  summary: string
}
