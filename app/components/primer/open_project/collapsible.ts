import {attr, target, targets} from '@github/catalyst'

export abstract class CollapsibleElement extends HTMLElement {
  @target arrowDown: Element
  @target arrowUp: Element
  @target triggerElement: HTMLElement
  @targets collapsibleElements: HTMLElement[]

  @attr collapsed = false

  toggleViaKeyboard(event: KeyboardEvent) {
    if (event.code === 'Enter' || event.code === 'Space') {
      this.toggle(event)
    }
  }

  toggle(event?: Event) {
    if (
      event &&
      event.target instanceof Element &&
      !event.target.closest('[data-collapsible-toggle]') &&
      event.target.closest('a, button')
    )
      return
    event?.preventDefault()
    this.collapsed = !this.collapsed
  }

  attributeChangedCallback(name: string) {
    if (name === 'data-collapsed') {
      if (this.collapsed) {
        this.hideAll()
      } else {
        this.expandAll()
      }
    }
  }

  hideAll() {
    // For whatever reason, setting `hidden` directly does not work on the SVGs
    this.arrowDown?.removeAttribute('hidden')
    this.arrowUp?.setAttribute('hidden', '')
    this.triggerElement.setAttribute('aria-expanded', 'false')

    for (const el of this.collapsibleElements) {
      el.hidden = true
    }

    this.classList.add(`${this.baseClass}--collapsed`)
  }

  expandAll() {
    this.arrowUp?.removeAttribute('hidden')
    this.arrowDown?.setAttribute('hidden', '')
    this.triggerElement.setAttribute('aria-expanded', 'true')

    for (const el of this.collapsibleElements) {
      el.hidden = false
    }

    this.classList.remove(`${this.baseClass}--collapsed`)
  }

  abstract get baseClass(): string
}
