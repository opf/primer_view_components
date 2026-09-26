import {attr, controller} from '@github/catalyst'
import {html, render, nothing} from 'lit-html'
import type {TemplateResult} from 'lit-html'
import {detectPlatform, isPlatform} from './keybinding_hint/platform'
import type {Platform} from './keybinding_hint/platform'
import {accessibleKeyName, condensedKeyName, fullKeyName, splitSequence} from './keybinding_hint/key_names'

type Format = 'condensed' | 'full'

/**
 * Renders keyboard shortcut hints client-side, because only the browser knows
 * the platform (⌘ vs ⌃). The server renders a plain-text fallback inside the
 * chord box; this element replaces it once, then owns a <kbd> mount that
 * lit-html renders into.
 *
 * Attributes (Catalyst `@attr`, so `data-*`): keys, format, scheme, size,
 * platform ('' = detect; 'apple' | 'windows' | 'other' overrides, used by
 * previews and tests).
 */
@controller('keybinding-hint')
export class KeybindingHintElement extends HTMLElement {
  @attr keys = ''
  @attr format = 'condensed'
  @attr scheme = 'default'
  @attr size = 'medium'
  @attr platform = ''

  #mount: HTMLElement | null = null
  #signature = ''
  // Whether the mount still holds exactly what lit last rendered. Any
  // mutation we did not make (Turbo morph, stream update, manual innerHTML,
  // even inside a single chord) revokes it, because lit would otherwise
  // update detached markers and leave the foreign content on screen.
  #owned = false
  // Every mutation we make is drained with takeRecords() straight after, so
  // any record that is delivered here or still queued in #update is external.
  #observer = new MutationObserver(() => {
    this.#owned = false
    this.#update()
  })

  connectedCallback() {
    this.#observer.observe(this, {childList: true, subtree: true, characterData: true})
    this.#update()
  }

  disconnectedCallback() {
    // Mutations while detached go unobserved, so re-render on reconnect.
    this.#observer.disconnect()
    this.#owned = false
  }

  attributeChangedCallback() {
    // Catalyst fires this for every observed attribute before connectedCallback
    // and once more for each default it writes; #update is idempotent and cheap.
    this.#update()
  }

  #update() {
    if (!this.isConnected) return

    const platform = this.#resolvedPlatform()
    const chords = splitSequence(this.keys, platform)
    const signature = [this.keys, this.format, this.scheme, this.size, platform].join('\u0000')
    // Catches an external mutation made in the same task as an attribute
    // change, before the observer callback has run.
    if (this.#observer.takeRecords().length > 0) this.#owned = false
    const owned = this.#owned && this.#mount !== null

    if (owned && signature === this.#signature) return

    if (chords.length === 0) {
      // Blank keys: render nothing, drop the fallback and any previous mount.
      if (this.hasChildNodes()) this.replaceChildren()
      this.#observer.takeRecords()
      this.#mount = null
      this.#owned = false
      this.#signature = signature
      return
    }

    if (!owned) {
      // First render, or something (Turbo morph, manual innerHTML) replaced our
      // content with fresh server markup. A new mount gives lit a fresh
      // container; reusing the old one would hit lit's detached markers.
      this.#mount = document.createElement('kbd')
      this.#mount.className = 'KeybindingHint-kbd'
      this.replaceChildren(this.#mount)
    }

    const target = this.#mount as HTMLElement
    render(this.#template(chords, platform), target)
    // Drop the records of our own render so they cannot re-enter #update.
    this.#observer.takeRecords()
    this.#owned = true
    this.#signature = signature
  }

  #resolvedPlatform(): Platform {
    return isPlatform(this.platform) ? this.platform : detectPlatform()
  }

  #resolvedFormat(): Format {
    return this.format === 'full' ? 'full' : 'condensed'
  }

  #chordClass(): string {
    const classes = ['KeybindingHint-chord']
    if (this.scheme === 'emphasis') classes.push('KeybindingHint-chord--emphasis')
    if (this.size === 'small') classes.push('KeybindingHint-chord--small')
    return classes.join(' ')
  }

  #template(chords: string[][], platform: Platform): TemplateResult[] {
    const format = this.#resolvedFormat()
    const chordClass = this.#chordClass()
    // Whitespace text nodes are deliberate: they give screen readers word
    // boundaries between hidden labels. Inside the inline-flex chord they do
    // not render; between chords the two around "then" collapse into the one
    // visible separator (as in React).
    return chords.map(
      (keys, chordIndex) =>
        html`${chordIndex > 0 ? html` <span class="sr-only">then</span> ` : nothing}<span
            class="${chordClass}"
            data-kbd-chord
            >${keys.map((key, keyIndex) => this.#keyTemplate(key, keyIndex, format, platform))}</span
          >`,
    )
  }

  #keyTemplate(key: string, index: number, format: Format, platform: Platform): TemplateResult {
    const visible = format === 'condensed' ? condensedKeyName(key, platform) : fullKeyName(key, platform)
    const separator = index === 0 ? nothing : format === 'full' ? html` <span aria-hidden="true"> + </span> ` : ' '
    return html`${separator}<span class="sr-only">${accessibleKeyName(key, platform)}</span
      ><span aria-hidden="true">${visible}</span>`
  }
}

declare global {
  interface Window {
    KeybindingHintElement: typeof KeybindingHintElement
  }
}

if (!window.customElements.get('keybinding-hint')) {
  window.KeybindingHintElement = KeybindingHintElement
}
