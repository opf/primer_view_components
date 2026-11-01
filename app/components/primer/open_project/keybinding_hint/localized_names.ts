import type {Platform} from './platform'
import {accessibleKeyName, condensedKeyName, fullKeyName} from './key_names'

export type NameFormat = 'condensed' | 'full' | 'accessible'

type PlatformNames = Partial<Record<Platform, string>>

/** `separator` is the JSON `then` (the word spoken between chords). */
export type KeyNames = {
  separator?: string
  keys: Record<string, Partial<Record<NameFormat, PlatformNames>>>
}

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === 'object' && value !== null && !Array.isArray(value)

const own = (record: Record<string, unknown>, key: string): unknown =>
  Object.hasOwn(record, key) ? record[key] : undefined

const nonBlank = (value: unknown): string | undefined =>
  typeof value === 'string' && value.trim() !== '' ? value : undefined

/** Parses the `data-names` attribute; anything malformed yields no names. */
export function parseKeyNames(json: string): KeyNames {
  try {
    const parsed: unknown = JSON.parse(json)
    if (isRecord(parsed) && isRecord(parsed.keys)) {
      return {separator: nonBlank(parsed['then']), keys: parsed.keys as KeyNames['keys']}
    }
  } catch {
    // Fall through to no names: upstream English applies.
  }
  return {keys: {}}
}

/** Exact platform, then `other`; `undefined` when no usable name was given. */
export function localizedKeyName(
  names: KeyNames,
  key: string,
  format: NameFormat,
  platform: Platform,
): string | undefined {
  const entry = own(names.keys, key)
  if (!isRecord(entry)) return undefined
  const platforms = own(entry, format)
  if (!isRecord(platforms)) return undefined
  return nonBlank(own(platforms, platform)) ?? nonBlank(own(platforms, 'other'))
}

const upstreamNames: Record<NameFormat, (key: string, platform: Platform) => string> = {
  condensed: condensedKeyName,
  full: fullKeyName,
  accessible: accessibleKeyName,
}

const capitalize = (key: string) => key.charAt(0).toUpperCase() + key.slice(1).toLowerCase()

/**
 * Upstream's English name. The mirrored tables index plain object literals, so
 * a key such as `constructor` would return an `Object.prototype` member;
 * those keys get upstream's default spelling instead.
 */
export function englishKeyName(key: string, format: NameFormat, platform: Platform): string {
  if (key in Object.prototype) return format === 'accessible' ? key.toLowerCase() : capitalize(key)
  return upstreamNames[format](key, platform)
}

export function keyName(names: KeyNames, key: string, format: NameFormat, platform: Platform): string {
  return localizedKeyName(names, key, format, platform) ?? englishKeyName(key, format, platform)
}
