import type {AnchorAlignment, AnchorSide} from '@primer/behaviors'
import '@oddbird/popover-polyfill'
import {getAnchoredPosition} from '@primer/behaviors'

const isPopoverOpen = (() => {
  let selector: string
  function setSelector(el: Element) {
    try {
      selector = ':popover-open'
      return el.matches(selector)
    } catch {
      try {
        selector = ':open'
        return el.matches(':open')
      } catch {
        selector = '.\\:popover-open'
        return el.matches('.\\:popover-open')
      }
    }
  }
  return (el: Element) => (selector ? el.matches(selector) : setSelector(el))
})()

const TOOLTIP_SR_ONLY_CLASS = 'sr-only'

type Direction = 'n' | 's' | 'e' | 'w' | 'ne' | 'se' | 'nw' | 'sw'

const DIRECTION_CLASSES = [
  'tooltip-n',
  'tooltip-s',
  'tooltip-e',
  'tooltip-w',
  'tooltip-ne',
  'tooltip-se',
  'tooltip-nw',
  'tooltip-sw',
]

function closeOpenTooltips(except?: Element) {
  for (const tooltip of openTooltips) {
    if (tooltip === except) continue
    if (isPopoverOpen(tooltip)) {
      tooltip.hidePopover()
    } else {
      openTooltips.delete(tooltip)
    }
  }
}

function focusOutListener() {
  closeOpenTooltips()
}

function focusInListener(event: Event) {
  setTimeout(() => {
    for (const tooltip of openTooltips) {
      if (isPopoverOpen(tooltip) && tooltip.showReason === 'focus' && tooltip.control !== event.target) {
        tooltip.hidePopover()
      }
    }
  }, 0)
}

const tooltips = new Set<ToolTipElement>()
const openTooltips = new Set<ToolTipElement>()
class ToolTipElement extends HTMLElement {
  styles() {
    return `
      :host {
        --tooltip-top: var(--tool-tip-position-top, 0);
        --tooltip-left: var(--tool-tip-position-left, 0);
        padding: var(--overlay-paddingBlock-condensed) var(--overlay-padding-condensed) !important;
        font: var(--text-body-shorthand-small);
        color: var(--tooltip-fgColor, var(--fgColor-onEmphasis)) !important;
        text-align: center;
        text-decoration: none;
        text-shadow: none;
        text-transform: none;
        letter-spacing: normal;
        word-wrap: break-word;
        white-space: pre;
        background: var(--tooltip-bgColor, var(--bgColor-emphasis)) !important;
        border-radius: var(--borderRadius-medium);
        border: 0 !important;
        opacity: 0;
        max-width: var(--overlay-width-small);
        word-wrap: break-word;
        white-space: normal;
        width: max-content !important;
        inset: var(--tooltip-top) auto auto var(--tooltip-left) !important;
        overflow: visible !important;
        text-wrap: balance;
      }

      :host(:is(.tooltip-n, .tooltip-nw, .tooltip-ne)) {
        --tooltip-top: calc(var(--tool-tip-position-top, 0) - var(--overlay-offset, 0.25rem));
        --tooltip-left: var(--tool-tip-position-left);
      }

      :host(:is(.tooltip-s, .tooltip-sw, .tooltip-se)) {
        --tooltip-top: calc(var(--tool-tip-position-top, 0) + var(--overlay-offset, 0.25rem));
        --tooltip-left: var(--tool-tip-position-left);
      }

      :host(.tooltip-w) {
        --tooltip-top: var(--tool-tip-position-top);
        --tooltip-left: calc(var(--tool-tip-position-left, 0) - var(--overlay-offset, 0.25rem));
      }

      :host(.tooltip-e) {
        --tooltip-top: var(--tool-tip-position-top);
        --tooltip-left: calc(var(--tool-tip-position-left, 0) + var(--overlay-offset, 0.25rem));
      }

      :host:after{
        position: absolute;
        display: block;
        right: 0;
        left: 0;
        height: var(--overlay-offset, 0.25rem);
        content: "";
      }

      :host(.tooltip-s):after,
      :host(.tooltip-se):after,
      :host(.tooltip-sw):after {
        bottom: 100%
      }

      :host(.tooltip-n):after,
      :host(.tooltip-ne):after,
      :host(.tooltip-nw):after {
        top: 100%;
      }

      @keyframes tooltip-appear {
        from {
          opacity: 0;
        }
        to {
          opacity: 1;
        }
      }

      :host(:popover-open),
      :host(:popover-open):before {
        animation-name: tooltip-appear;
        animation-duration: .1s;
        animation-fill-mode: forwards;
        animation-timing-function: ease-in;
      }

      :host(.\\:popover-open) {
        animation-name: tooltip-appear;
        animation-duration: .1s;
        animation-fill-mode: forwards;
        animation-timing-function: ease-in;
      }

      @media (forced-colors: active) {
        :host {
          outline: solid 1px transparent;
        }

        :host:before {
          display: none;
        }
      }
    `
  }

  #abortController: AbortController | undefined
  #align: AnchorAlignment = 'center'
  #side: AnchorSide = 'outside-bottom'
  #allowUpdatePosition = false
  #showReason: 'focus' | 'mouse' = 'mouse'
  get showReason() {
    return this.#showReason
  }

  get htmlFor(): string {
    return this.getAttribute('for') || ''
  }

  set htmlFor(value: string) {
    this.setAttribute('for', value)
  }

  get type(): 'description' | 'label' {
    const type = this.getAttribute('data-type')
    return type === 'label' ? 'label' : 'description'
  }

  set type(value: 'description' | 'label') {
    this.setAttribute('data-type', value)
  }

  get direction(): Direction {
    return (this.getAttribute('data-direction') || 's') as Direction
  }

  set direction(value: Direction) {
    this.setAttribute('data-direction', value)
  }

  get control(): HTMLElement | null {
    return this.ownerDocument.getElementById(this.htmlFor)
  }

  /* @deprecated */
  set hiddenFromView(value: true | false) {
    if (value && isPopoverOpen(this)) {
      this.hidePopover()
    } else if (!value && !isPopoverOpen(this)) {
      this.showPopover()
    }
  }

  /* @deprecated */
  get hiddenFromView() {
    return !isPopoverOpen(this)
  }

  connectedCallback() {
    tooltips.add(this)
    this.#updateControlReference()
    this.#updateDirection()
    if (!this.shadowRoot) {
      const shadow = this.attachShadow({mode: 'open'})
      const style = shadow.appendChild(document.createElement('style'))
      style.textContent = this.styles()
      shadow.appendChild(document.createElement('slot'))
    }
    this.#update(false)
    this.#allowUpdatePosition = true

    this.#updateControl()
  }

  disconnectedCallback() {
    tooltips.delete(this)
    openTooltips.delete(this)
    this.#abortController?.abort()
  }

  async handleEvent(event: Event) {
    if (!this.control) return
    const showing = isPopoverOpen(this)

    // Ensures that tooltip stays open when hovering between tooltip and element
    // WCAG Success Criterion 1.4.13 Hoverable
    const shouldShow =
      event.type === 'mouseenter' ||
      // Only show tooltip on focus if running in headless browser (for tests) or if focus ring
      // is visible (i.e. if user is using keyboard navigation)
      (event.type === 'focus' && (navigator.webdriver || this.control.matches(':focus-visible')))
    const isMouseLeaveFromButton =
      event.type === 'mouseleave' &&
      (event as MouseEvent).relatedTarget !== this.control &&
      (event as MouseEvent).relatedTarget !== this
    const isEscapeKeydown = event.type === 'keydown' && (event as KeyboardEvent).key === 'Escape'
    const isMouseDownOnButton = event.type === 'mousedown' && event.currentTarget === this.control
    const isOpeningOtherPopover = event.type === 'beforetoggle' && event.currentTarget !== this
    const shouldHide = isMouseLeaveFromButton || isEscapeKeydown || isMouseDownOnButton || isOpeningOtherPopover

    if (showing && isEscapeKeydown) {
      /* eslint-disable-next-line no-restricted-syntax */
      event.stopImmediatePropagation()
      event.preventDefault()
    }

    await Promise.resolve()
    if (!showing && shouldShow && !isPopoverOpen(this)) {
      this.#showReason = event.type === 'mouseenter' ? 'mouse' : 'focus'
      this.showPopover()
    } else if (showing && shouldHide && isPopoverOpen(this)) {
      this.hidePopover()
    }

    if (event.type === 'toggle') {
      this.#update((event as ToggleEvent).newState === 'open')
    }
  }

  static observedAttributes = ['data-type', 'data-direction', 'id', 'for']

  #update(isOpen: boolean) {
    if (isOpen) {
      openTooltips.add(this)
      this.classList.remove(TOOLTIP_SR_ONLY_CLASS)
      closeOpenTooltips(this)
      this.#updatePosition()
    } else {
      openTooltips.delete(this)
      this.classList.remove(...DIRECTION_CLASSES)
      this.classList.add(TOOLTIP_SR_ONLY_CLASS)
    }
  }

  attributeChangedCallback(name: string) {
    if (!this.isConnected) return

    if (name === 'for') {
      this.#updateControl()
    } else if (name === 'id' || name === 'data-type') {
      this.#updateControlReference()
    } else if (name === 'data-direction') {
      this.#updateDirection()
    }
  }

  #updateControl() {
    if (!this.control) return

    this.setAttribute('role', 'tooltip')

    this.#abortController?.abort()
    this.#abortController = new AbortController()
    const {signal} = this.#abortController

    this.addEventListener('mouseleave', this, {signal})
    this.addEventListener('toggle', this, {signal})
    this.control.addEventListener('mouseenter', this, {signal})
    this.control.addEventListener('mouseleave', this, {signal})
    this.control.addEventListener('focus', this, {signal})
    this.control.addEventListener('mousedown', this, {signal})
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore popoverTargetElement is not in the type definition
    this.control.popoverTargetElement?.addEventListener('beforetoggle', this, {
      signal,
    })
    this.ownerDocument.addEventListener('focusout', focusOutListener)
    this.ownerDocument.addEventListener('focusin', focusInListener)
    this.ownerDocument.addEventListener('keydown', this, {signal, capture: true})
  }

  #updateControlReference() {
    if (!this.id || !this.control) return
    if (this.type === 'label') {
      let labelledBy = this.control.getAttribute('aria-labelledby')
      if (labelledBy) {
        if (!labelledBy.split(' ').includes(this.id)) {
          labelledBy = `${labelledBy} ${this.id}`
        } else {
          labelledBy = `${labelledBy}`
        }
      } else {
        labelledBy = this.id
      }
      this.control.setAttribute('aria-labelledby', labelledBy)

      // Prevent duplicate accessible name announcements.
      this.setAttribute('aria-hidden', 'true')
    } else {
      let describedBy = this.control.getAttribute('aria-describedby')
      if (describedBy) {
        if (!describedBy.split(' ').includes(this.id)) {
          describedBy = `${describedBy} ${this.id}`
        } else {
          describedBy = `${describedBy}`
        }
      } else {
        describedBy = this.id
      }
      this.control.setAttribute('aria-describedby', describedBy)
    }
  }

  #updateDirection() {
    this.classList.remove(...DIRECTION_CLASSES)
    const direction = this.direction
    if (direction === 'n') {
      this.#align = 'center'
      this.#side = 'outside-top'
    } else if (direction === 'ne') {
      this.#align = 'end'
      this.#side = 'outside-top'
    } else if (direction === 'e') {
      this.#align = 'center'
      this.#side = 'outside-right'
    } else if (direction === 'se') {
      this.#align = 'end'
      this.#side = 'outside-bottom'
    } else if (direction === 's') {
      this.#align = 'center'
      this.#side = 'outside-bottom'
    } else if (direction === 'sw') {
      this.#align = 'start'
      this.#side = 'outside-bottom'
    } else if (direction === 'w') {
      this.#align = 'center'
      this.#side = 'outside-left'
    } else if (direction === 'nw') {
      this.#align = 'start'
      this.#side = 'outside-top'
    }
  }

  #updatePosition() {
    if (!this.control) return
    if (!this.#allowUpdatePosition || !isPopoverOpen(this)) return

    const position = getAnchoredPosition(this, this.control, {
      side: this.#side,
      align: this.#align,
      anchorOffset: 0,
    })
    const anchorSide = position.anchorSide
    const align = position.anchorAlign

    this.style.setProperty('--tool-tip-position-top', `${position.top}px`)
    this.style.setProperty('--tool-tip-position-left', `${position.left}px`)

    let direction: Direction = 's'

    if (anchorSide === 'outside-left') {
      direction = 'w'
    } else if (anchorSide === 'outside-right') {
      direction = 'e'
    } else if (anchorSide === 'outside-top') {
      if (align === 'center') {
        direction = 'n'
      } else if (align === 'start') {
        direction = 'ne'
      } else {
        direction = 'nw'
      }
    } else {
      if (align === 'center') {
        direction = 's'
      } else if (align === 'start') {
        direction = 'se'
      } else {
        direction = 'sw'
      }
    }

    this.classList.add(`tooltip-${direction}`)
  }
}

if (!window.customElements.get('tool-tip')) {
  window.ToolTipElement = ToolTipElement
  window.customElements.define('tool-tip', ToolTipElement)
}

declare global {
  interface Window {
    ToolTipElement: typeof ToolTipElement
  }
}
