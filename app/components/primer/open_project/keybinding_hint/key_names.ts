import type {Platform} from './platform'

/** Converts the first character to upper case and the rest to lower case. */
const capitalize = ([first, ...rest]: string) => (first?.toUpperCase() ?? '') + rest.join('').toLowerCase()

// The tables below cover keys realistically used in shortcuts, not every key.

/** Short iconic key names matching keyboard legends. */
export const condensedKeyName = (key: string, platform: Platform) =>
  ({
    alt: platform === 'apple' ? '⌥' : 'Alt',
    control: '⌃',
    shift: '⇧',
    meta: platform === 'apple' ? '⌘' : platform === 'windows' ? 'Win' : 'Meta',
    // Unreachable: splitChord resolves `mod` to meta/control first; kept for primer-react parity.
    mod: platform === 'apple' ? '⌘' : '⌃',
    pageup: 'PgUp',
    pagedown: 'PgDn',
    arrowup: '↑',
    arrowdown: '↓',
    arrowleft: '←',
    arrowright: '→',
    plus: '+',
    backspace: '⌫',
    delete: 'Del',
    space: '␣',
    tab: '⇥',
    enter: '⏎',
    escape: 'Esc',
    function: 'Fn',
    capslock: 'CapsLock',
    insert: 'Ins',
    printscreen: 'PrtScn',
  })[key] ?? capitalize(key)

/** Spelled-out key names for the `full` format. */
export const fullKeyName = (key: string, platform: Platform) =>
  ({
    alt: platform === 'apple' ? 'Option' : 'Alt',
    meta: platform === 'apple' ? 'Command' : platform === 'windows' ? 'Windows' : 'Meta',
    // Unreachable: splitChord resolves `mod` to meta/control first; kept for primer-react parity.
    mod: platform === 'apple' ? 'Command' : 'Control',
    '+': 'Plus',
    pageup: 'Page Up',
    pagedown: 'Page Down',
    arrowup: 'Up Arrow',
    arrowdown: 'Down Arrow',
    arrowleft: 'Left Arrow',
    arrowright: 'Right Arrow',
    capslock: 'Caps Lock',
    printscreen: 'Print Screen',
  })[key] ?? capitalize(key)

/** Key names for screen readers; avoids punctuation being read as pauses. English only. */
export const accessibleKeyName = (key: string, platform: Platform) =>
  ({
    alt: platform === 'apple' ? 'option' : 'alt',
    meta: platform === 'apple' ? 'command' : platform === 'windows' ? 'Windows' : 'meta',
    // Unreachable: splitChord resolves `mod` to meta/control first; kept for primer-react parity.
    mod: platform === 'apple' ? 'command' : 'control',
    pageup: 'page up',
    pagedown: 'page down',
    arrowup: 'up arrow',
    arrowdown: 'down arrow',
    arrowleft: 'left arrow',
    arrowright: 'right arrow',
    capslock: 'caps lock',
    printscreen: 'print screen',
    '`': 'backtick',
    '~': 'tilde',
    '!': 'exclamation point',
    '@': 'at',
    '#': 'hash',
    $: 'dollar sign',
    '%': 'percent',
    '^': 'caret',
    '&': 'ampersand',
    '*': 'asterisk',
    '(': 'left parenthesis',
    ')': 'right parenthesis',
    _: 'underscore',
    '-': 'dash',
    '+': 'plus',
    '=': 'equals',
    '[': 'left bracket',
    '{': 'left curly brace',
    ']': 'right bracket',
    '}': 'right curly brace',
    '\\': 'backslash',
    '|': 'pipe',
    ';': 'semicolon',
    ':': 'colon',
    "'": 'single quote',
    '"': 'double quote',
    ',': 'comma',
    '<': 'left angle bracket',
    '.': 'period',
    '>': 'right angle bracket',
    '/': 'forward slash',
    '?': 'question mark',
    ' ': 'space',
  })[key] ?? key.toLowerCase()

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
