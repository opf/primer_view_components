import {attr, target, targets} from '@github/catalyst'

// eslint-disable-next-line custom-elements/expose-class-on-global
export abstract class CollapsibleHelperElement extends HTMLElement {
  @target arrowDown: Element
  @target arrowUp: Element
  @target triggerElement: HTMLElement
  @targets collapsibleElements: HTMLElement[]

  @attr collapsed = false

  toggle() {
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
    showElement(this.arrowDown)
    hideElement(this.arrowUp)
    this.triggerElement.setAttribute('aria-expanded', 'false')

    this.collapsibleElements.forEach(hideElement)

    this.classList.add(`${this.baseClass}--collapsed`)
  }

  expandAll() {
    hideElement(this.arrowDown)
    showElement(this.arrowUp)
    this.triggerElement.setAttribute('aria-expanded', 'true')

    this.collapsibleElements.forEach(showElement)

    this.classList.remove(`${this.baseClass}--collapsed`)
  }

  abstract get baseClass(): string
}

function hideElement(el: Element) {
  el.classList.add('d-none')
  el.setAttribute('aria-hidden', 'true')
}

function showElement(el: Element) {
  el.classList.remove('d-none')
  el.setAttribute('aria-hidden', 'false')
}
