import {controller, target} from '@github/catalyst'

const SUBMIT_BUTTON_SELECTOR = 'input[type=submit],button[type=submit],button[data-submit-dialog-id]'

@controller
class DangerDialogFormHelperElement extends HTMLElement {
  @target checkbox: HTMLInputElement | undefined
  @target liveRegion: HTMLElement | undefined

  get form() {
    return this.querySelector('form')
  }

  get submitButton() {
    return this.querySelector<HTMLInputElement | HTMLButtonElement>(SUBMIT_BUTTON_SELECTOR)!
  }

  connectedCallback() {
    // makes the custom element behave as if it doesn't exist in the DOM structure, passing all
    // styles directly to its children.
    this.style.display = 'contents'
    if (this.form) {
      this.form.style.display = 'contents'
    }
    this.#reset()
  }

  toggle(): void {
    if (!this.checkbox || !this.submitButton) return

    const enabled = this.checkbox.checked
    this.submitButton.disabled = !enabled

    if (this.liveRegion) {
      const message = enabled
          ? this.getAttribute('data-confirmation-live-message-checked')
          : this.getAttribute('data-confirmation-live-message-unchecked')

      this.liveRegion.textContent = ''
      this.liveRegion.textContent = message || ''
    }
  }

  #reset(): void {
    this.toggle()
  }
}

declare global {
  interface Window {
    DangerDialogFormHelperElement: typeof DangerDialogFormHelperElement
  }
}

if (!window.customElements.get('danger-dialog-form-helper')) {
  window.DangerDialogFormHelperElement = DangerDialogFormHelperElement
  window.customElements.define('danger-dialog-form-helper', DangerDialogFormHelperElement)
}
