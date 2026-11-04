import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { BrowserRouter, Route, Routes } from 'react-router-dom'
import { AppLayout } from './components/Layout/AppLayout'
import { ComparePage } from './pages/ComparePage'
import { DashboardPage } from './pages/DashboardPage'
import { MapPage } from './pages/MapPage'
import { NodesPage } from './pages/NodesPage'
import { ZonesPage } from './pages/ZonesPage'

const queryClient = new QueryClient()

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Routes>
          <Route element={<AppLayout />}>
            <Route index element={<DashboardPage />} />
            <Route path="zones" element={<ZonesPage />} />
            <Route path="nodes" element={<NodesPage />} />
            <Route path="compare" element={<ComparePage />} />
            <Route path="map" element={<MapPage />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  )
}
