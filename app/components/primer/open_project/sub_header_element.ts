import {controller, target, targets} from '@github/catalyst'

@controller
class SubHeaderElement extends HTMLElement {
  @target filterInput: HTMLInputElement
  @targets hiddenItemsOnExpandedFilter: HTMLElement[]
  @targets shownItemsOnExpandedFilter: HTMLElement[]

  clearFilterButton: HTMLButtonElement | null

  connectedCallback() {
    this.setupFilterInputClearButton()
  }

  toggleFilterInputClearButton() {
    if (!this.clearFilterButton) {
      return
    }
    if (this.filterInput.value.length > 0) {
      this.clearFilterButton.classList.remove('d-none')
    } else {
      this.clearFilterButton.classList.add('d-none')
    }
  }

  expandFilterInput() {
    for (const item of this.hiddenItemsOnExpandedFilter) {
      item.classList.add('d-none')
    }

    for (const item of this.shownItemsOnExpandedFilter) {
      item.classList.remove('d-none')
    }

    this.classList.add('SubHeader--expandedSearch')

    this.filterInput.focus()
  }

  collapseFilterInput() {
    for (const item of this.hiddenItemsOnExpandedFilter) {
      item.classList.remove('d-none')
    }

    for (const item of this.shownItemsOnExpandedFilter) {
      item.classList.add('d-none')
    }

    this.classList.remove('SubHeader--expandedSearch')
  }

  setupFilterInputClearButton() {
    this.waitForCondition(
      () => Boolean(this.filterInput),
      () => {
        this.filterInput.classList.remove('SubHeader-filterInput_hiddenClearButton')
        this.clearFilterButton = this.querySelector('button.FormControl-input-trailingAction') as HTMLButtonElement

        if (this.clearFilterButton) {
          this.toggleFilterInputClearButton()
        }
      },
    )
  }

  // Waits for condition to return true. If it returns false initially, this function creates a
  // MutationObserver that calls body() whenever the contents of the component change.
  waitForCondition(condition: () => boolean, body: () => void) {
    if (condition()) {
      body()
    } else {
      const mutationObserver = new MutationObserver(() => {
        if (condition()) {
          body()
          mutationObserver.disconnect()
        }
      })

      mutationObserver.observe(this, {childList: true, subtree: true})
    }
  }
}

declare global {
  interface Window {
    SubHeaderElement: typeof SubHeaderElement
  }
}

if (!window.customElements.get('sub-header')) {
  window.SubHeaderElement = SubHeaderElement
  window.customElements.define('sub-header', SubHeaderElement)
}
