import '@github/auto-check-element'
import type {AutoCheckErrorEvent, AutoCheckSuccessEvent} from '@github/auto-check-element'
import {controller, target} from '@github/catalyst'
import {CharacterCounter} from './character_counter'
import {
  clearValidation,
  renderValidationMessage,
  showValidation,
  styleValidation,
  type InlineValidationParts,
} from './inline_validation'

declare global {
  interface HTMLElementEventMap {
    'auto-check-success': AutoCheckSuccessEvent
    'auto-check-error': AutoCheckErrorEvent
  }
}

@controller('primer-text-field')
export class PrimerTextFieldElement extends HTMLElement {
  @target inputElement: HTMLInputElement
  @target validationElement: HTMLElement
  @target validationMessageElement: HTMLElement
  @target validationSuccessIcon: HTMLElement
  @target validationErrorIcon: HTMLElement
  @target leadingVisual: HTMLElement
  @target leadingSpinner: HTMLElement
  @target characterLimitElement: HTMLElement
  @target characterLimitSrElement: HTMLElement

  #abortController: AbortController | null
  #characterCounter: CharacterCounter | null = null

  connectedCallback(): void {
    this.#abortController?.abort()
    const {signal} = (this.#abortController = new AbortController())

    this.addEventListener(
      'auto-check-success',
      async (event: AutoCheckSuccessEvent) => {
        const message = await event.detail.response.text()
        if (message && message.length > 0) {
          this.setSuccess(message)
        } else {
          this.clearError()
        }
      },
      {signal},
    )

    this.addEventListener(
      'auto-check-error',
      async (event: AutoCheckErrorEvent) => {
        const errorMessage = await event.detail.response.text()
        this.setError(errorMessage)
      },
      {signal},
    )

    // Set up character limit tracking if present
    if (this.characterLimitElement) {
      this.#characterCounter = new CharacterCounter(
        this.inputElement,
        this.characterLimitElement,
        this.characterLimitSrElement,
      )
      this.#characterCounter.initialize(signal)
    }
  }

  disconnectedCallback() {
    this.#abortController?.abort()
    this.#characterCounter?.cleanup()
  }

  clearContents() {
    this.inputElement.value = ''
    this.inputElement.focus()
    this.inputElement.dispatchEvent(new Event('input', {bubbles: true, cancelable: false}))
  }

  clearError(): void {
    clearValidation(this.#validationParts)
  }

  setValidationMessage(message: string): void {
    renderValidationMessage(this.validationMessageElement, message)
  }

  toggleValidationStyling(isError: boolean): void {
    styleValidation(this.#validationParts, isError ? 'error' : 'success')
  }

  setSuccess(message: string): void {
    showValidation(this.#validationParts, message, 'success')
  }

  setError(message: string): void {
    showValidation(this.#validationParts, message, 'error')
  }

  get #validationParts(): InlineValidationParts {
    return {
      input: this.inputElement,
      validation: this.validationElement,
      message: this.validationMessageElement,
      successIcon: this.validationSuccessIcon,
      errorIcon: this.validationErrorIcon,
    }
  }

  showLeadingSpinner(): void {
    this.leadingSpinner?.removeAttribute('hidden')
    this.leadingVisual?.setAttribute('hidden', '')
  }

  hideLeadingSpinner(): void {
    this.leadingSpinner?.setAttribute('hidden', '')
    this.leadingVisual?.removeAttribute('hidden')
  }
}
