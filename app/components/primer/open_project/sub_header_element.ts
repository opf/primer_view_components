import {controller, target, targets} from '@github/catalyst'

@controller
class SubHeaderElement extends HTMLElement {
  @target filterInput: HTMLElement
  @targets hiddenItemsOnExpandedFilter: HTMLElement[]
  @targets shownItemsOnExpandedFilter: HTMLElement[]

  connectedCallback() {
    this.clearFilterButton = this.querySelector('.FormControl-input-trailingAction') as HTMLElement;
    this.toggleFilterInputClearButton()
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
