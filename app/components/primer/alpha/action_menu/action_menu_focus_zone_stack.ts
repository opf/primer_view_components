import AnchoredPositionElement from '../../anchored_position'
import {FocusKeys, focusTrap, focusZone} from '@primer/behaviors'
import {ActionMenuElement} from './action_menu_element'

type StackEntry = {
  element: AnchoredPositionElement
  abortController?: AbortController
}

export class ActionMenuFocusZoneStack {
  #stack: StackEntry[]

  constructor() {
    this.#stack = []
  }

  get current(): StackEntry | undefined {
    return this.#stack[this.#stack.length - 1]
  }

  push(next: AnchoredPositionElement, options: {trapFocus: boolean} = {trapFocus: true}) {
    const {trapFocus} = options
    this.#stack.push({element: next, abortController: this.#setupFocusZone(next, trapFocus)})
  }

  pop(target?: AnchoredPositionElement) {
    if (target) {
      if (!this.#stack.some(entry => entry.element === target)) return

      while (this.#stack.length > 0 && this.current?.element !== target) {
        const entry = this.#stack.pop()
        entry?.abortController?.abort()
      }
    }

    const entry = this.#stack.pop()
    entry?.abortController?.abort()
  }

  // Pops and aborts every entry above (not including) the given element.
  popAbove(element: AnchoredPositionElement) {
    if (!this.#stack.some(entry => entry.element === element)) return

    while (this.#stack.length > 0 && this.current?.element !== element) {
      const entry = this.#stack.pop()
      entry?.abortController?.abort()
    }
  }

  // Drops and aborts every entry whose element is no longer live, for example
  // an overlay that other code removed while it was open. Its toggle event
  // never reaches the menu, so nothing else pops it.
  prune(isLive: (element: AnchoredPositionElement) => boolean) {
    this.#stack = this.#stack.filter(entry => {
      if (isLive(entry.element)) return true
      entry.abortController?.abort()
      return false
    })
  }

  clear() {
    while (this.#stack.length > 0) {
      const entry = this.#stack.pop()
      entry?.abortController?.abort()
    }
  }

  #setupFocusZone(containerEl: AnchoredPositionElement, trapFocus: boolean): AbortController {
    const focusZoneAbortController = focusZone(containerEl, {
      bindKeys: FocusKeys.ArrowVertical | FocusKeys.ArrowHorizontal | FocusKeys.HomeAndEnd | FocusKeys.Backspace,
      focusOutBehavior: 'wrap',

      focusableElementFilter: (element: HTMLElement): boolean => {
        return this.elementIsMenuItem(element) && element.closest('anchored-position') === containerEl
      },
    })

    if (trapFocus) {
      // focusTrap returns undefined when given a signal, so keep the zone's controller
      focusTrap(containerEl, undefined, focusZoneAbortController.signal)
    }

    return focusZoneAbortController
  }

  elementIsMenuItem(element: HTMLElement): boolean {
    return this.#validItemRoles.includes(element.getAttribute('role') || '')
  }

  get #validItemRoles(): string[] {
    return ActionMenuElement.validItemRoles
  }

  get isEmpty(): boolean {
    return this.#stack.length === 0
  }
}
