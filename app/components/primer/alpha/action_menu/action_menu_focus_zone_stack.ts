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

  pop(target?: AnchoredPositionElement) {
    if (target) {
      while (this.#stack.length > 0 && this.current?.element !== target) {
        const entry = this.#stack.pop()
        entry?.abortController.abort()
      }
    }

    const entry = this.#stack.pop()
    entry?.abortController.abort()
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
