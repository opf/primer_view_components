import type {Platform} from './platform'
import {nonBlank} from './localized_names'
import type {NameFormat} from './localized_names'

type PlatformNames = Partial<Record<Platform, string>>
type EntryNames = Partial<Record<NameFormat, PlatformNames>>

/** The `data-names` JSON shape; identical to Ruby's `KeybindingHint::Names.for`. */
export type KeyNamesData = {then: string | undefined; keys: Record<string, EntryNames>}

const FORMATS: readonly NameFormat[] = ['condensed', 'full', 'accessible']
const PLATFORMS: readonly Platform[] = ['apple', 'windows', 'other']

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === 'object' && value !== null && !Array.isArray(value)

const own = (value: unknown, key: string): unknown =>
  isRecord(value) && Object.hasOwn(value, key) ? value[key] : undefined

const isSymbol = (name: string | undefined) => name !== undefined && !/\p{L}/u.test(name)

/**
 * Keys as Ruby tokenises them: the server cannot know the platform, so `mod`
 * contributes both `control` and `meta`. Whitespace matches Ruby's `\s`.
 */
export const tokens = (keys: string): string[] => [
  ...new Set(
    keys
      .split(/[ \t\r\n\f\v]+/)
      .flatMap(chord => chord.split('+'))
      .filter(token => token !== '')
      .map(token => token.toLowerCase())
      .flatMap(token => (token === 'mod' ? ['control', 'meta'] : [token])),
  ),
]

/** I18n keys cannot contain `.`, so punctuation entries carry their key in `key`. */
const tokenIndex = (entries: unknown): Map<string, string> => {
  const index = new Map<string, string>()
  if (!isRecord(entries)) return index
  for (const [name, entry] of Object.entries(entries)) {
    if (!isRecord(entry)) continue
    const key = own(entry, 'key')
    index.set(typeof key === 'string' ? key : name, name)
  }
  return index
}

const platformNames = (value: unknown): PlatformNames => {
  const names: PlatformNames = {}
  for (const platform of PLATFORMS) {
    const name = nonBlank(own(value, platform))
    if (name !== undefined) names[platform] = name
  }
  return names
}

const entryNames = (englishEntry: unknown, localeEntry: unknown): EntryNames => {
  const names: EntryNames = {}
  for (const format of FORMATS) {
    const english = platformNames(own(englishEntry, format))
    const translated = platformNames(own(localeEntry, format))
    for (const platform of PLATFORMS) {
      if (isSymbol(english[platform])) delete translated[platform]
    }
    const merged = {...english, ...translated}
    if (Object.keys(merged).length > 0) names[format] = merged
  }
  return names
}

/**
 * Builds `data-names` for `keys` from the `keybinding_hint` locale scopes, as
 * i18n-js returns them. Translator data is untrusted: only non-blank strings in
 * the expected place are used, and symbols such as ⌘ cannot be replaced.
 */
export function buildKeyNames(keys: string, localeScope: unknown, englishScope: unknown): KeyNamesData {
  const englishKeys = own(englishScope, 'keys')
  const index = tokenIndex(englishKeys)
  const result: KeyNamesData = {
    then: nonBlank(own(localeScope, 'then')) ?? nonBlank(own(englishScope, 'then')),
    keys: {},
  }
  for (const token of tokens(keys)) {
    const entry = index.get(token)
    if (entry === undefined) continue
    // defineProperty, not assignment: a `__proto__` token must stay an own key.
    Object.defineProperty(result.keys, token, {
      value: entryNames(own(englishKeys, entry), own(own(localeScope, 'keys'), entry)),
      enumerable: true,
      writable: true,
      configurable: true,
    })
  }
  return result
}
