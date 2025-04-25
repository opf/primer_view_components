import AnchoredPositionElement from '../../anchored_position'
import {FocusKeys, focusTrap, focusZone} from '@primer/behaviors'

type StackEntry = {
  element: AnchoredPositionElement
  abortController?: AbortController
}

export class ActionMenuRovingTabIndexStack {
  #stack: StackEntry[]

  constructor() {
    this.#stack = []
  }

  get current(): StackEntry | undefined {
    return this.#stack[this.#stack.length - 1]
  }

  push(next: AnchoredPositionElement) {
    this.#stack.push({element: next, abortController: this.#setupFocusZone(next)})
  }

  pop(target?: AnchoredPositionElement) {
    if (target) {
      while (this.#stack.length > 0 && this.current?.element !== target) {
        const entry = this.#stack.pop()
        entry?.abortController?.abort()
      }
    }

    const entry = this.#stack.pop()
    entry?.abortController?.abort()
  }

  #setupFocusZone(containerEl: HTMLElement): AbortController | undefined {
    const {signal: focusZoneSignal} = focusZone(containerEl, {
      bindKeys: FocusKeys.ArrowVertical | FocusKeys.ArrowHorizontal | FocusKeys.HomeAndEnd | FocusKeys.Backspace,

      getNextFocusable: (_direction, from, event) => {
        if (!(from instanceof HTMLElement)) return

        // Skip elements within a modal dialog
        // This need to be in a try/catch to avoid errors in
        // non-supported browsers
        try {
          if (from.closest('dialog:modal')) {
            return
          }
        } catch {
          // Don't return
        }

        return this.#getNextFocusableElement(from, event) ?? from
      },

      focusInStrategy: () => {
        let currentItem = containerEl.querySelector('[aria-current]')
        currentItem = currentItem?.checkVisibility() ? currentItem : null

        const firstItem = containerEl.querySelector('[role="menuitem"]')

        // Focus the aria-current item if it exists
        if (currentItem instanceof HTMLElement) {
          return currentItem
        }

        // Otherwise, focus the activeElement if it's a menuitem
        if (
          document.activeElement instanceof HTMLElement &&
          containerEl.contains(document.activeElement) &&
          document.activeElement.getAttribute('role') === 'menuitem'
        ) {
          return document.activeElement
        }

        // Otherwise, focus the first menuitem
        return firstItem instanceof HTMLElement ? firstItem : undefined
      },

      focusOutBehavior: 'wrap',
    })

    return focusTrap(containerEl, undefined, focusZoneSignal)
  }

  #getNextFocusableElement(activeElement: HTMLElement, event: KeyboardEvent): HTMLElement | undefined {
    switch (event.key) {
      case 'ArrowUp':
        // Focus previous visible element
        return this.#getVisibleElement(activeElement, 'previous')

      case 'ArrowDown':
        // Focus next visible element
        return this.#getVisibleElement(activeElement, 'next')

      case 'Backspace':
        return this.#getParentElement(activeElement)
    }
  }

  #getVisibleElement(element: HTMLElement, direction: 'next' | 'previous'): HTMLElement | undefined {
    const root = element.closest('[role=menu]')

    if (!root) return

    const walker = document.createTreeWalker(root, NodeFilter.SHOW_ELEMENT, node => {
      if (!(node instanceof HTMLElement)) return NodeFilter.FILTER_SKIP
      return node.getAttribute('role') === 'menuitem' ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_SKIP
    })

    let current = walker.firstChild()

    while (current !== element) {
      current = walker.nextNode()
    }

    const next = direction === 'next' ? walker.nextNode() : walker.previousNode()
    return next instanceof HTMLElement ? next : undefined
  }

  #getParentElement(element: HTMLElement): HTMLElement | undefined {
    const parent = element.closest('[role=menu]')
    return parent instanceof HTMLElement ? parent : undefined
  }
}
