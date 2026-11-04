import { cn, theftColor } from '../../lib/utils'

export function StatusBadge({ status }: { status: string }) {
  return (
    <span className={cn('inline-flex rounded-full border px-3 py-1 text-xs font-semibold', theftColor(status))}>
      {status}
    </span>
  )
}

export function TypeBadge({ type }: { type: string }) {
  const colors =
    type === 'feeder'
      ? 'text-blue-400 bg-blue-400/10 border-blue-400/30'
      : 'text-violet-400 bg-violet-400/10 border-violet-400/30'
  return (
    <span className={cn('inline-flex rounded-full border px-2 py-0.5 text-xs font-medium uppercase', colors)}>
      {type}
    </span>
  )
}
