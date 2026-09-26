/**
 * Platform categories that change how shortcut keys are displayed.
 * Port of primer-react KeybindingHint/platform.ts (SSR/override parts dropped).
 *
 * - `apple`: macOS and iOS/iPadOS (Command and Option keys)
 * - `windows`: Windows (Windows key for Meta)
 * - `other`: everything else (Meta has no consistent label)
 */
export type Platform = 'apple' | 'windows' | 'other'

const PLATFORMS: readonly string[] = ['apple', 'windows', 'other']

export function isPlatform(value: string): value is Platform {
  return PLATFORMS.includes(value)
}

export function detectPlatform(): Platform {
  if (typeof navigator === 'undefined') return 'other'
  const platform = navigator.platform || ''
  const userAgent = navigator.userAgent || ''
  // iPadOS in desktop mode reports MacIntel, which is the desired outcome.
  if (/^mac/i.test(platform) || /iphone|ipad|ipod/i.test(platform) || /iphone|ipad|ipod/i.test(userAgent)) {
    return 'apple'
  }
  if (/^win/i.test(platform)) return 'windows'
  return 'other'
}
