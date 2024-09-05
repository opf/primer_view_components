import {controller, target, targets} from '@github/catalyst'

@controller
class SubHeaderElement extends HTMLElement {
  @target filterInput: HTMLInputElement
  @targets hiddenItemsOnExpandedFilter: HTMLElement[]
  @targets shownItemsOnExpandedFilter: HTMLElement[]

  clearFilterButton: HTMLButtonElement | null
  clearButtonWrapper: HTMLElement | null

  connectedCallback() {
    this.clearFilterButton = this.querySelector('button.FormControl-input-trailingAction') as HTMLButtonElement
    this.clearButtonWrapper = this.clearFilterButton.closest('.FormControl-input-wrap') as HTMLElement

    if (this.clearFilterButton) {
      this.toggleFilterInputClearButton()
    }
  }

  toggleFilterInputClearButton() {
    if (!(this.clearButtonWrapper && this.clearFilterButton)) {
      return
    }
    if (this.filterInput.value.length > 0) {
      // Remove the wrapper's trailingAction class in order to have the filterInput's
      // whole width used for the placeholder text.
      this.clearButtonWrapper.classList.add('FormControl-input-wrap--trailingAction')
      this.clearFilterButton.classList.remove('d-none')
    } else {
      this.clearButtonWrapper.classList.remove('FormControl-input-wrap--trailingAction')
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
