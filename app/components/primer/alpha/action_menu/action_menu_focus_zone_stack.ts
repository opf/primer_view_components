import AnchoredPositionElement from '../../anchored_position'
import {FocusKeys, focusTrap, focusZone} from '@primer/behaviors'
import {ActionMenuElement} from './action_menu_element'

type StackEntry = {
  element: AnchoredPositionElement
  abortController: AbortController
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

  // Pops and aborts the top entry, or the given element and every entry above it.
  pop(target?: AnchoredPositionElement) {
    if (target) {
      if (!this.#includes(target)) return
      this.popAbove(target)
    }

    this.#popTop()
  }

  // Pops and aborts every entry above (not including) the given element.
  popAbove(element: AnchoredPositionElement) {
    if (!this.#includes(element)) return

    while (this.current && this.current.element !== element) this.#popTop()
  }

  // Drops and aborts every entry whose element is no longer live, for example
  // an overlay that other code removed while it was open. Its toggle event
  // never reaches the menu, so nothing else pops it.
  prune(isLive: (element: AnchoredPositionElement) => boolean) {
    this.#stack = this.#stack.filter(entry => {
      if (isLive(entry.element)) return true
      entry.abortController.abort()
      return false
    })
  }

  clear() {
    while (this.current) this.#popTop()
  }

  #popTop() {
    this.#stack.pop()?.abortController.abort()
  }

  #includes(element: AnchoredPositionElement): boolean {
    return this.#stack.some(entry => entry.element === element)
  }

  #setupFocusZone(containerEl: AnchoredPositionElement, trapFocus: boolean): AbortController {
    const focusZoneAbortController = focusZone(containerEl, {
      bindKeys: FocusKeys.ArrowVertical | FocusKeys.ArrowHorizontal | FocusKeys.HomeAndEnd | FocusKeys.Backspace,
      focusOutBehavior: 'wrap',

      focusableElementFilter: (element: HTMLElement): boolean => {
        return this.elementIsMenuItem(element) && element.closest('anchored-position') === containerEl
      },
    })

    // focusTrap() returns nothing when given a signal, so hand back the focus zone's
    // controller in both cases. Aborting it tears down the focus trap as well.
    if (trapFocus) {
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
