import type {Platform} from './platform'

const PLATFORMS: readonly string[] = ['apple', 'windows', 'other']

export function isPlatform(value: string): value is Platform {
  return PLATFORMS.includes(value)
}
