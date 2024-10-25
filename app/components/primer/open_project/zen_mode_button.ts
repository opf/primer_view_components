import {controller, target} from '@github/catalyst'

@controller
class ZenModeButtonElement extends HTMLElement {
  @target button: HTMLElement
  inZenMode = false

  // eslint-disable-next-line custom-elements/no-constructor
  constructor() {
    super()
    // eslint-disable-next-line @typescript-eslint/no-this-alias
    const self = this
    document.addEventListener('fullscreenchange', function () {
      if (!document.fullscreenElement && self.inZenMode) {
        self.performAction()
      }
    })
  }

  dispatchZenModeStatus() {
    // Create a new custom event
    const event = new CustomEvent('zenModeToggled', {
      detail: {
        active: this.inZenMode,
      },
    })
    // Dispatch the custom event
    window.dispatchEvent(event)
  }

  private deactivateZenMode() {
    this.inZenMode = false
    this.button.setAttribute('aria-pressed', 'false')
    if (document.exitFullscreen && document.fullscreenElement) {
      void document.exitFullscreen()
    }
  }

  private activateZenMode() {
    this.inZenMode = true
    this.button.setAttribute('aria-pressed', 'true')
    if (document.documentElement.requestFullscreen) {
      void document.documentElement.requestFullscreen()
    }
  }

  public performAction() {
    if (this.inZenMode) {
      this.deactivateZenMode()
    } else {
      this.activateZenMode()
    }
    this.dispatchZenModeStatus()
  }
}

declare global {
  interface Window {
    ZenModeButtonElement: typeof ZenModeButtonElement
  }
}

if (!window.customElements.get('zen-mode-button')) {
  window.ZenModeButtonElement = ZenModeButtonElement
  window.customElements.define('zen-mode-button', ZenModeButtonElement)
}
