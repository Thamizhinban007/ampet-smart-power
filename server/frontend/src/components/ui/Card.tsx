import { cn } from '../../lib/utils'

export function Card({ children, className }: { children: React.ReactNode; className?: string }) {
  return (
    <div className={cn('rounded-xl border border-slate-800 bg-[#1a2332] p-5 shadow-lg', className)}>
      {children}
    </div>
  )
}

export function CardTitle({ children }: { children: React.ReactNode }) {
  return <h3 className="mb-3 text-lg font-semibold text-slate-100">{children}</h3>
}
