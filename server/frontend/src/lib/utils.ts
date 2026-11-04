import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function theftColor(status: string) {
  switch (status) {
    case 'SAFE':
      return 'text-emerald-400 bg-emerald-400/10 border-emerald-400/30'
    case 'SUSPECTED':
      return 'text-amber-400 bg-amber-400/10 border-amber-400/30'
    case 'THEFT DETECTED':
      return 'text-red-400 bg-red-400/10 border-red-400/30'
    default:
      return 'text-slate-400 bg-slate-400/10 border-slate-400/30'
  }
}
