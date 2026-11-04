// Mirrors primer-react `KeybindingHint/platform.ts`. The React-only parts are
// replaced: `getSnapshot` is exported as `detectPlatform`, and the element's
// `data-platform` attribute takes the place of `PlatformOverrideProvider`.
import {isMacOS as ssrUnsafeIsMacOS} from '@primer/behaviors/utils'

/**
 * The platform categories that affect how keyboard shortcut keys are displayed.
 *
 * - `apple`: Apple platforms (macOS and iOS/iPadOS), which use the Command and Option keys.
 * - `windows`: Windows, which uses the Windows (Meta) key.
 * - `other`: Any other platform (e.g. Linux, Android), where the Meta key does not map to a
 *   consistent label.
 */
export type Platform = 'apple' | 'windows' | 'other'

/** SSR-unsafe detection of iOS/iPadOS (in addition to macOS, which is detected separately). */
const ssrUnsafeIsIOS = () => {
  if (typeof navigator === 'undefined') return false
  return /iphone|ipad|ipod/i.test(navigator.platform) || /iphone|ipad|ipod/i.test(navigator.userAgent)
}

/** SSR-unsafe detection of Windows. */
const ssrUnsafeIsWindows = () => {
  if (typeof navigator === 'undefined') return false
  return /^win/i.test(navigator.platform)
}

const getSnapshot = (): Platform => {
  if (ssrUnsafeIsMacOS() || ssrUnsafeIsIOS()) return 'apple'
  if (ssrUnsafeIsWindows()) return 'windows'
  return 'other'
}

export const detectPlatform = getSnapshot
