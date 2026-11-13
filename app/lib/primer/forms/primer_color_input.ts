import {attr, controller, target} from '@github/catalyst'
import {clearValidation, showValidation, type InlineValidationParts} from './inline_validation'

const HEX_PATTERN = /^#?([0-9a-f]{3}|[0-9a-f]{6})$/i

// Returns the canonical uppercase `#RRGGBB` form of the given text, or null
// if it is not a three- or six-digit hex color.
export function parseHex(text: string): string | null {
  const match = HEX_PATTERN.exec(text.trim())
  if (!match) return null

  let digits = match[1]
  if (digits.length === 3) digits = digits.replace(/./g, '$&$&')

  return `#${digits.toUpperCase()}`
}

@controller('primer-color-input')
export class PrimerColorInputElement extends HTMLElement {
  @target inputElement: HTMLInputElement
  @target pickerElement: HTMLInputElement

  // The text input is empty.
  @attr blank = false
  // There is no color to show in the swatch.
  @attr empty = false
  // The id of the validation element FormControl renders after this element.
  // Empty without FormControl, as inside `multi`.
  @attr validationId = ''

  #abortController: AbortController | null = null
  #observer: MutationObserver | null = null

  connectedCallback(): void {
    this.#abortController?.abort()
    const {signal} = (this.#abortController = new AbortController())

    this.syncDisabled()
    this.sync()

    // The server always renders the picker disabled. Whatever rewrites
    // attributes without reconnecting this element, a Turbo morph for one,
    // puts that back, so the rule is re-applied on every such change.
    this.#observer?.disconnect()
    this.#observer = new MutationObserver(() => this.syncDisabled())
    this.#observer.observe(this, {attributes: true, attributeFilter: ['disabled', 'readonly'], subtree: true})

    // The form is outside this element's subtree, so data-action cannot
    // reach it. Reset restores the text value after the event, hence the tick.
    this.inputElement.form?.addEventListener('reset', () => setTimeout(() => this.sync()), {signal})
  }

  disconnectedCallback(): void {
    this.#abortController?.abort()
    this.#observer?.disconnect()
  }

  // The picker is operable only while its value can reach the submitted text
  // input and that input accepts edits.
  private syncDisabled(): void {
    const disabled = this.inputElement.disabled || this.inputElement.readOnly

    // Assigning the same value again would still rewrite the attribute and
    // wake the observer, which would then never settle.
    if (this.pickerElement.disabled !== disabled) this.pickerElement.disabled = disabled
  }

  // Text → picker. Bound to `input` on the text input, so the swatch follows
  // every keystroke: text that is not a whole color yet shows none. The
  // picker itself has no empty value and keeps the last color to open on.
  syncPicker(): void {
    const text = this.inputElement.value.trim()
    const color = parseHex(text)

    this.blank = text === ''
    this.empty = color === null

    if (color) this.pickerElement.value = color.toLowerCase()
  }

  // Bound to `change` on the text input.
  normalize(): void {
    const color = parseHex(this.inputElement.value)
    if (color) this.inputElement.value = color
  }

  // Bound to `paste` on the text input. The browser cuts a paste to the
  // input's `maxlength` first, so padding around a copied color would push
  // its last digits out. The padding is dropped and the rest inserted as an
  // edit of the user's own, which keeps undo, `maxlength` and read-only
  // intact and still ends in a `change` event.
  trimPaste(event: ClipboardEvent): void {
    const text = event.clipboardData?.getData('text/plain') ?? ''
    const trimmed = text.trim()
    if (trimmed === text) return

    event.preventDefault()
    document.execCommand('insertText', false, trimmed)
  }

  // Picker → text. Bound to `input` on the picker. The picker's own event
  // stops here: the one forwarded from the text input stands in for it, and
  // listeners further up would otherwise hear of each pick twice.
  syncInput(event: Event): void {
    /* eslint-disable-next-line no-restricted-syntax */
    event.stopPropagation()

    this.inputElement.value = this.pickerElement.value.toUpperCase()
    this.inputElement.dispatchEvent(new Event('input', {bubbles: true}))
  }

  // Bound to `change` on the picker, whose own event stops here as well.
  commit(event: Event): void {
    /* eslint-disable-next-line no-restricted-syntax */
    event.stopPropagation()

    this.inputElement.dispatchEvent(new Event('change', {bubbles: true}))
  }

  // Resynchronises from the text input's current value. Call this after
  // setting the value from script, which fires no event.
  sync(): void {
    this.syncPicker()
  }

  // The validation API of `primer-text-field`. The message is parsed as
  // HTML, so pass trusted markup; announcing it is up to the caller. Without
  // a validation element these do nothing.
  setError(message: string): void {
    const parts = this.#validationParts
    if (parts) showValidation(parts, message, 'error')
  }

  setSuccess(message: string): void {
    const parts = this.#validationParts
    if (parts) showValidation(parts, message, 'success')
  }

  clearError(): void {
    const parts = this.#validationParts
    if (parts) clearValidation(parts)
  }

  // The validation element is a sibling, so its parts are not Catalyst
  // targets; they carry this element's target names all the same.
  get #validationParts(): InlineValidationParts | null {
    const validation = this.validationId ? document.getElementById(this.validationId) : null
    if (!validation) return null

    const part = (name: string) => validation.querySelector<HTMLElement>(`[data-target~="primer-color-input.${name}"]`)!

    return {
      input: this.inputElement,
      validation,
      message: part('validationMessageElement'),
      successIcon: part('validationSuccessIcon'),
      errorIcon: part('validationErrorIcon'),
    }
  }
}

declare global {
  interface HTMLElementTagNameMap {
    'primer-color-input': PrimerColorInputElement
  }
}
