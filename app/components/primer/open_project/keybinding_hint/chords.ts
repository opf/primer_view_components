import type {Platform} from './platform'

/** Modifier order. Non-modifiers sort last; there is at most one per chord. */
const keySortPriorities: Partial<Record<string, number>> = {
  control: 1,
  meta: 2,
  alt: 3,
  option: 4,
  shift: 5,
  function: 6,
}

const keySortPriority = (key: string) => keySortPriorities[key] ?? Infinity

/**
 * Deviation from primer-react: `mod` is resolved to the platform's modifier
 * before sorting so it takes that modifier's slot. Upstream leaves `mod`
 * unprioritised, which renders "Mod+Shift+p" as ⇧⌘P.
 */
const resolveMod = (key: string, platform: Platform) =>
  key === 'mod' ? (platform === 'apple' ? 'meta' : 'control') : key

/** Split a chord into lowercase, sorted key names. Empty tokens are dropped. */
export const splitChord = (chord: string, platform: Platform): string[] =>
  chord
    .split('+')
    .filter(key => key !== '')
    .map(key => resolveMod(key.toLowerCase(), platform))
    .sort((a, b) => keySortPriority(a) - keySortPriority(b))

/** Split a sequence into chords. Repeated whitespace and empty chords are dropped. */
export const splitSequence = (sequence: string, platform: Platform): string[][] =>
  sequence
    .trim()
    .split(/\s+/)
    .filter(chord => chord !== '')
    .map(chord => splitChord(chord, platform))
    .filter(keys => keys.length > 0)
