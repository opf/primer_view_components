import {getAnchoredPosition} from '@primer/behaviors'
import {controller, target} from '@github/catalyst'
import type {PrimerTextFieldElement} from 'app/lib/primer/forms/primer_text_field'
import type {AnchorAlignment, AnchorSide} from '@primer/behaviors'
import type {LiveRegionElement} from '@primer/live-region-element'
import '@primer/live-region-element'
import '@oddbird/popover-polyfill'
import {observeMutationsUntilConditionMet} from '../utils'
import {TreeViewElement} from '../alpha/tree_view/tree_view'
import {TreeViewSubTreeNodeElement} from '../alpha/tree_view/tree_view_sub_tree_node_element'
import {SegmentedControlElement} from '../alpha/segmented_control'

type SelectVariant = 'none' | 'single' | 'multiple' | null
type SelectedItem = {
  label: string | null | undefined
  value: string | null | undefined
  inputName: string | null | undefined
}

type NodeState = {
  checked: boolean
  disabled: boolean
}

const validSelectors = ['[role="option"]']
const menuItemSelectors = validSelectors.join(',')
const visibleMenuItemSelectors = validSelectors.map(selector => `:not([hidden]) > ${selector}`).join(',')

export type SelectTreePanelItem = HTMLLIElement

enum ErrorStateType {
  BODY,
  BANNER,
}

// This function is expected to return the following values:
// 1. No match - return null
// 2. Match but no highlights - empty array (i.e. when showing all selected nodes but empty query string)
// 3. Match with highlights - non-empty array of Range objects
export type FilterFn = (node: HTMLElement, query: string, filterMode?: string) => Range[] | null

const updateWhenVisible = (() => {
  const anchors = new Set<SelectTreePanelElement>()
  let resizeObserver: ResizeObserver | null = null
  function updateVisibleAnchors() {
    for (const anchor of anchors) {
      anchor.updateAnchorPosition()
    }
  }
  return (el: SelectTreePanelElement) => {
    // eslint-disable-next-line github/prefer-observers
    window.addEventListener('resize', updateVisibleAnchors)
    // eslint-disable-next-line github/prefer-observers
    window.addEventListener('scroll', updateVisibleAnchors)

    resizeObserver ||= new ResizeObserver(() => {
      for (const anchor of anchors) {
        anchor.updateAnchorPosition()
      }
    })
    resizeObserver.observe(el.ownerDocument.documentElement)
    el.addEventListener('dialog:close', () => {
      el.invokerElement?.setAttribute('aria-expanded', 'false')
      anchors.delete(el)
    })
    el.addEventListener('dialog:open', () => {
      anchors.add(el)
    })
  }
})()

@controller
export class SelectTreePanelElement extends HTMLElement {
  @target dialog: HTMLDialogElement
  @target filterInputTextField: HTMLInputElement
  @target filterModeControlList: HTMLElement
  @target list: HTMLElement
  @target noResults: HTMLElement
  @target bannerErrorElement: HTMLElement
  @target bodySpinner: HTMLElement
  @target liveRegion: LiveRegionElement
  @target includeSubItemsCheckBox: HTMLInputElement

  #filterFn?: FilterFn

  #dialogIntersectionObserver: IntersectionObserver
  #abortController: AbortController
  #stateMap: Map<TreeViewSubTreeNodeElement, Map<HTMLElement, NodeState>> = new Map()

  #originalLabel = ''
  #inputName = ''
  #selectedItems: Map<string, SelectedItem> = new Map()
  #loadingDelayTimeoutId: number | null = null
  #loadingAnnouncementTimeoutId: number | null = null
  #hasLoadedData = false

  get filterModeControl(): SegmentedControlElement | null {
    return this.filterModeControlList.closest('segmented-control')
  }

  get treeView(): TreeViewElement | null {
    return this.list.querySelector('tree-view')
  }

  get open(): boolean {
    return this.dialog.open
  }

  get selectVariant(): SelectVariant {
    return this.getAttribute('data-select-variant') as SelectVariant
  }

  get ariaSelectionType(): string {
    return this.selectVariant === 'multiple' ? 'aria-checked' : 'aria-selected'
  }

  set selectVariant(variant: SelectVariant) {
    if (variant) {
      this.setAttribute('data-select-variant', variant)
    } else {
      this.removeAttribute('variant')
    }
  }

  get dynamicLabelPrefix(): string {
    const prefix = this.getAttribute('data-dynamic-label-prefix')
    if (!prefix) return ''
    return `${prefix}:`
  }

  get dynamicAriaLabelPrefix(): string {
    const prefix = this.getAttribute('data-dynamic-aria-label-prefix')
    if (!prefix) return ''
    return `${prefix}:`
  }

  set dynamicLabelPrefix(value: string) {
    this.setAttribute('data-dynamic-label', value)
  }

  get dynamicLabel(): boolean {
    return this.hasAttribute('data-dynamic-label')
  }

  set dynamicLabel(value: boolean) {
    this.toggleAttribute('data-dynamic-label', value)
  }

  get invokerElement(): HTMLButtonElement | null {
    const id = this.querySelector('dialog')?.id
    if (!id) return null
    for (const el of this.querySelectorAll(`[aria-controls]`)) {
      if (el.getAttribute('aria-controls') === id) {
        return el as HTMLButtonElement
      }
    }
    return null
  }

  get closeButton(): HTMLButtonElement | null {
    return this.querySelector('button[data-close-dialog-id]')
  }

  get invokerLabel(): HTMLElement | null {
    if (!this.invokerElement) return null
    return this.invokerElement.querySelector('.Button-label')
  }

  get selectedItems(): SelectedItem[] {
    return Array.from(this.#selectedItems.values())
  }

  get align(): AnchorAlignment {
    return (this.getAttribute('anchor-align') || 'start') as AnchorAlignment
  }

  get side(): AnchorSide {
    return (this.getAttribute('anchor-side') || 'outside-bottom') as AnchorSide
  }

  updateAnchorPosition() {
    // If the selectPanel is removed from the screen on resize close the dialog
    if (this && this.offsetParent === null) {
      this.hide()
    }

    if (this.invokerElement) {
      const {top, left} = getAnchoredPosition(this.dialog, this.invokerElement, {
        align: this.align,
        side: this.side,
        anchorOffset: 4,
      })
      this.dialog.style.top = `${top}px`
      this.dialog.style.left = `${left}px`
      this.dialog.style.bottom = 'auto'
      this.dialog.style.right = 'auto'
    }
  }

  connectedCallback() {
    const {signal} = (this.#abortController = new AbortController())

    this.addEventListener('treeViewNodeChecked', this, {signal})
    this.addEventListener('itemActivated', this, {signal})

    this.addEventListener('keydown', this, {signal})
    this.addEventListener('click', this, {signal})
    this.addEventListener('mousedown', this, {signal})
    this.addEventListener('input', this, {signal})

    this.#setDynamicLabel()
    this.#updateInput()
    this.#softDisableItems()
    updateWhenVisible(this)

    this.#dialogIntersectionObserver = new IntersectionObserver(entries => {
      for (const entry of entries) {
        const elem = entry.target
        if (entry.isIntersecting && elem === this.dialog) {
          // Focus on the filter input when the dialog opens to work around a Safari limitation
          // that prevents the autofocus attribute from working as it does in other browsers
          if (this.filterInputTextField) {
            if (document.activeElement !== this.filterInputTextField) {
              this.filterInputTextField.focus()
            }
          }

          // signal that any focus hijinks are finished (thanks Safari)
          this.dialog.setAttribute('data-ready', 'true')

          this.updateAnchorPosition()
          //this.#updateItemVisibility()
        }
      }
    })

    observeMutationsUntilConditionMet(
      this,
      () => Boolean(this.dialog),
      () => {
        this.#dialogIntersectionObserver.observe(this.dialog)
        this.dialog.addEventListener('close', this, {signal})

        if (this.getAttribute('data-open-on-load') === 'true') {
          this.show()
        }
      },
    )

    // observeMutationsUntilConditionMet(
    //   this,
    //   () => this.items.length > 0,
    //   () => {
    //     this.#updateItemVisibility()
    //     this.#updateInput()
    //   },
    // )
  }

  disconnectedCallback() {
    this.#abortController.abort()
  }

  #softDisableItems() {
    const {signal} = this.#abortController

    for (const item of this.querySelectorAll(validSelectors.join(','))) {
      item.addEventListener('click', this.#potentiallyDisallowActivation.bind(this), {signal})
      item.addEventListener('keydown', this.#potentiallyDisallowActivation.bind(this), {signal})
    }
  }

  // If there is an active item in single-select mode, set its tabindex to 0. Otherwise, set the
  // first visible item's tabindex to 0. All other items should have a tabindex of -1.
  #updateTabIndices() {
    const setZeroTabIndex = false

    if (this.selectVariant === 'single') {
      // for (const item of this.items) {
      //   const itemContent = this.#getItemContent(item)
      //   if (!itemContent) continue
      //   if (!this.isItemHidden(item) && this.isItemChecked(item) && !setZeroTabIndex) {
      //     itemContent.setAttribute('tabindex', '0')
      //     setZeroTabIndex = true
      //   } else {
      //     itemContent.setAttribute('tabindex', '-1')
      //   }
      //   // <li> elements should not themselves be tabbable
      //   item.removeAttribute('tabindex')
      // }
    } else {
      //for (const item of this.items) {
      // const itemContent = this.#getItemContent(item)
      // if (!itemContent) continue
      // itemContent.setAttribute('tabindex', '-1')
      // // <li> elements should not themselves be tabbable
      // item.removeAttribute('tabindex')
      //}
    }

    // if (!setZeroTabIndex && this.#firstItem) {
    //   this.#getItemContent(this.#firstItem)?.setAttribute('tabindex', '0')
    // }
  }

  // returns true if activation was prevented
  #potentiallyDisallowActivation(event: Event): boolean {
    if (!this.#isActivation(event)) return false

    const item = (event.target as HTMLElement).closest(visibleMenuItemSelectors)
    if (!item) return false

    if (item.getAttribute('aria-disabled')) {
      event.preventDefault()

      // eslint-disable-next-line no-restricted-syntax
      event.stopPropagation()

      // eslint-disable-next-line no-restricted-syntax
      event.stopImmediatePropagation()
      return true
    }

    return false
  }

  #isAnchorActivationViaSpace(event: Event): boolean {
    return (
      event.target instanceof HTMLAnchorElement &&
      event instanceof KeyboardEvent &&
      event.type === 'keydown' &&
      !(event.ctrlKey || event.altKey || event.metaKey || event.shiftKey) &&
      event.key === ' '
    )
  }

  #isActivation(event: Event): boolean {
    // Some browsers fire MouseEvents (Firefox) and others fire PointerEvents (Chrome). Activating an item via
    // enter or space counterintuitively fires one of these rather than a KeyboardEvent. Since PointerEvent
    // inherits from MouseEvent, it is enough to check for MouseEvent here.
    return (event instanceof MouseEvent && event.type === 'click') || this.#isAnchorActivationViaSpace(event)
  }

  #setTextFieldLoadingSpinnerTimer() {
    if (!this.#filterInputTextFieldElement) return
    if (this.#loadingDelayTimeoutId) clearTimeout(this.#loadingDelayTimeoutId)
    if (this.#loadingAnnouncementTimeoutId) clearTimeout(this.#loadingAnnouncementTimeoutId)

    this.#loadingAnnouncementTimeoutId = setTimeout(() => {
      this.liveRegion.announce('Loading')
    }, 2000) as unknown as number

    this.#loadingDelayTimeoutId = setTimeout(() => {
      this.#filterInputTextFieldElement?.showLeadingSpinner()
    }, 1000) as unknown as number
  }

  handleEvent(event: Event) {
    if (event.target === this.filterInputTextField) {
      this.#handleSearchFieldEvent(event)
      return
    }

    const targetIsInvoker = this.invokerElement?.contains(event.target as HTMLElement)
    const targetIsCloseButton = this.closeButton?.contains(event.target as HTMLElement)
    const eventIsActivation = this.#isActivation(event)

    if (targetIsInvoker && event.type === 'mousedown') {
      return
    }

    if (event.type === 'mousedown' && event.target instanceof HTMLInputElement) {
      return
    }

    // Prevent safari bug that dismisses menu on mousedown instead of allowing
    // the click event to propagate to the button
    if (event.type === 'mousedown') {
      event.preventDefault()
      return
    }

    if (targetIsInvoker && eventIsActivation) {
      this.#handleInvokerActivated(event)
      return
    }

    if (targetIsCloseButton && eventIsActivation) {
      // hide() will automatically be called by dialog event triggered from `data-close-dialog-id`
      return
    }

    if (
      event.type === 'keydown' &&
      event instanceof KeyboardEvent &&
      (event.target as Element).closest(visibleMenuItemSelectors)
    ) {
      const hasModifier = event.ctrlKey || event.altKey || event.metaKey
      const isAlphabetKey = event.key.length === 1 && /[a-z\d]/i.test(event.key)

      // eslint-disable-next-line no-restricted-syntax
      if (!hasModifier && isAlphabetKey) event.stopPropagation()
    }

    if (event.target === this.dialog && event.type === 'close') {
      // Remove data-ready so it can be set the next time the panel is opened
      this.dialog.removeAttribute('data-ready')
      this.invokerElement?.setAttribute('aria-expanded', 'false')
      // When we close the dialog, clear the filter input

      if (this.filterInputTextField) {
        const fireSearchEvent = this.filterInputTextField.value.length > 0
        this.filterInputTextField.value = ''
        if (fireSearchEvent) {
          this.filterInputTextField.dispatchEvent(new Event('input'))
        }
      }

      this.dispatchEvent(
        new CustomEvent('panelClosed', {
          detail: {panel: this},
          bubbles: true,
        }),
      )

      return
    }

    const item = (event.target as Element).closest(visibleMenuItemSelectors)?.parentElement as
      | SelectTreePanelItem
      | null
      | undefined

    const targetIsItem = item !== null && item !== undefined

    if (targetIsItem && eventIsActivation) {
      if (this.#potentiallyDisallowActivation(event)) return

      const dialogInvoker = item.closest('[data-show-dialog-id]')

      if (dialogInvoker) {
        const dialog = this.ownerDocument.getElementById(dialogInvoker.getAttribute('data-show-dialog-id') || '')

        if (dialog && this.contains(dialogInvoker) && this.contains(dialog)) {
          this.#handleDialogItemActivated(event, dialog)
          return
        }
      }

      // Pressing the space key on a link will cause the page to scroll unless preventDefault() is called.
      // We then click it manually to navigate.
      if (this.#isAnchorActivationViaSpace(event)) {
        event.preventDefault()
        //this.#getItemContent(item)?.click()
      }

      this.#handleItemActivated(item)

      return
    }

    if (event.type === 'click') {
      const rect = this.dialog.getBoundingClientRect()

      const clickWasInsideDialog =
        rect.top <= (event as MouseEvent).clientY &&
        (event as MouseEvent).clientY <= rect.top + rect.height &&
        rect.left <= (event as MouseEvent).clientX &&
        (event as MouseEvent).clientX <= rect.left + rect.width

      if (!clickWasInsideDialog) {
        this.hide()
      }
    }
  }

  set filterFn(newFn: FilterFn) {
    this.#filterFn = newFn
  }

  get filterFn(): FilterFn {
    if (this.#filterFn) {
      return this.#filterFn
    } else {
      return this.defaultFilterFn
    }
  }

  defaultFilterFn(node: HTMLElement, query: string, filterMode?: string): Range[] | null {
    const ranges = []

    if (query.length > 0) {
      const lowercaseQuery = query.toLowerCase()
      const treeWalker = document.createTreeWalker(node, NodeFilter.SHOW_TEXT)
      let currentNode = treeWalker.nextNode()

      while (currentNode) {
        const lowercaseNodeText = currentNode.textContent?.toLocaleLowerCase() || ''
        let startIndex = 0

        while (startIndex < lowercaseNodeText.length) {
          const index = lowercaseNodeText.indexOf(lowercaseQuery, startIndex)
          if (index === -1) break

          const range = new Range()
          range.setStart(currentNode, index)
          range.setEnd(currentNode, index + lowercaseQuery.length)
          ranges.push(range)

          startIndex = index + lowercaseQuery.length
        }

        currentNode = treeWalker.nextNode()
      }
    }

    if (ranges.length === 0 && query.length > 0) {
      return null
    }

    switch (filterMode) {
      case 'selected': {
        // Only match nodes that have been checked
        if (this.treeView?.getNodeCheckedValue(node) !== 'false') {
          return ranges
        }

        break
      }

      case 'all': {
        return ranges
      }
    }

    return null
  }

  #handleFilterModeEvent(event: Event) {
    if (event.type !== 'itemActivated') return

    this.#applyFilterOptions()
  }

  #handleSearchFieldEvent(event: Event) {
    if (event.type !== 'input') return

    this.#applyFilterOptions()
  }

  #handleIncludeSubItemsCheckBoxEvent(event: Event) {
    if (!this.treeView) return
    if (event.type !== 'input') return

    this.#applyFilterOptions()

    if (this.includeSubItemsCheckBox.checked) {
      this.#includeSubItems()
    } else {
      this.#restoreAllNodeStates()
    }
  }

  // Automatically checks all children of checked nodes, including leaf nodes and sub-trees. It does so
  // by finding the set of shallowest checked sub-tree nodes, i.e. the set of checked sub-tree nodes with
  // the lowest level value. It then saves their node state, disables them, and checks all their children.
  // Rather than storing child node information for every checked sub-tree regardless of depth, finding
  // the set of shallowest sub-tree nodes allows the component to store the minimum amount of node
  // information and simplifies the process of restoring it later.
  #includeSubItems() {
    if (!this.treeView) return

    for (const subTree of this.treeView.rootSubTreeNodes()) {
      for (const checkedSubTree of this.eachShallowestCheckedSubTree(subTree)) {
        this.#includeSubItemsUnder(checkedSubTree)
      }
    }
  }

  // Records the state of all the nodes in the given sub-tree. Node state includes whether or not the
  // node is checked, and whether or not it is disabled. Or at least, that's what it included when this
  // comment was first written. Check the members of the NodeState type above for up-to-date info.
  #includeSubItemsUnder(subTree: TreeViewSubTreeNodeElement) {
    if (!this.treeView) return

    const descendantStates: Map<HTMLElement, NodeState> = new Map()

    for (const node of subTree.eachDescendantNode()) {
      descendantStates.set(node as HTMLElement, {
        checked: this.treeView.getNodeCheckedValue(node) === 'true',
        disabled: this.treeView.getNodeDisabledValue(node),
      })

      this.treeView.setNodeCheckedValue(node, 'true')
      this.treeView.setNodeDisabledValue(node, true)
    }

    this.#stateMap.set(subTree, descendantStates)
  }

  get filterMode(): string | null {
    const current = this.filterModeControl?.current

    if (current) {
      return current.getAttribute('data-name')
    } else {
      return null
    }
  }

  get queryString(): string {
    return this.filterInputTextField.value
  }

  /* This function does quite a bit. It's responsible for showing and hiding nodes that match the filter
   * criteria, disabling nodes under certain conditions, and rendering highlights for node text that
   * matches the query string. The filter criteria are as follows:
   *
   * 1. A free-form query string from a text input field.
   * 2. A SegmentedControl with two options:
   *    1. The "Selected" option causes the component to only show checked nodes, provided they also
   *       satisfy the other filter criteria described here.
   *    2. The "All" option causes the component to show all nodes, provided they also satisfy the other
   *       filter criteria described here.
   *
   * Whether or not a node matches is determined by a filter function with a `FilterFn` signature. The
   * component defines a default filter function, but a user-defined one can also be provided. The filter
   * function is expected to return an array of `Range` objects which #applyFilterOptions uses to highlight
   * node text that matches the query string. The default filter function identifies matching node text by
   * looking for an exact substring match, operating on a lowercased version of both the query string and
   * the node text. For an exact description of the expected return values of the filter function, please
   * see the FilterFn type above.
   *
   * It should be noted that the returned `Range` objects must have starting and ending values that refer
   * to offsets inside the same text node. Not adhering to this rule may lead to undefined behavior.
   *
   * Applying the filter criteria can have the following effects on individual nodes:
   *
   * 1. Hidden: Nodes are hidden if:
   *    1. The filter function returns null.
   * 2. Disabled: Nodes are disabled if:
   *    1. The node is a child of a checked parent and the "Include sub-items" check box is checked.
   * 4. Expanded: Sub-tree nodes are expanded if:
   *    1. For at least one of the node's children, including descendants, the filter function returns a
   *       truthy value.
   */
  #applyFilterOptions() {
    if (!this.treeView) return

    this.#removeHighlights()

    const query = this.queryString
    const mode = this.filterMode || undefined
    const generation = window.crypto.randomUUID()
    const filterRangesCache: Map<Element, Range[] | null> = new Map()

    const expandAncestors = (...ancestors: TreeViewSubTreeNodeElement[]) => {
      for (const ancestor of ancestors) {
        ancestor.expand()
        ancestor.removeAttribute('hidden')
        ancestor.setAttribute('data-generation', generation)

        if (cachedFilterFn(ancestor.node, query, mode)) {
          ancestor.node.removeAttribute('aria-disabled')
        } else {
          ancestor.node.setAttribute('aria-disabled', 'true')
        }
      }
    }

    // This function is called in the loop below for both leaf  nodes and sub-tree nodes to determine
    // if they match, and subsequently whether or not to hide them. However, it serves a secondary purpose
    // as well in that it remembers the range information returned by the filter function so it can be
    // used to highlight matching ranges later.
    const cachedFilterFn = (node: HTMLElement, queryStr: string, filterMode?: string): boolean => {
      if (!filterRangesCache.has(node)) {
        filterRangesCache.set(node, this.filterFn(node, queryStr, filterMode))
      }

      return filterRangesCache.get(node)! !== null
    }

    /* We iterate depth-first here in order to be able to examine the most deeply nested leaf nodes
     * before their parents. This enables us to easily hide the parent if none of its children match.
     * To handle expanding and collapsing ancestors, the algorithm iterates over the provided ancestor
     * chain, expanding "upwards" to the root.
     *
     * Using this technique does mean it's possible to iterate over the same ancestor multiple times.
     * For example, consider two nodes that share the same ancestor. Node A contains matching children,
     * but node B does not. The algorithm below will visit node A first and expand it and all its
     * ancestors. Next, the algorithm will visit node B and collapse all its ancestors. To avoid this,
     * the algorithm attaches a random "generation ID" to each node visited. If the generation ID
     * matches when visiting a particular node, we know that node has already been visited and should
     * not be hidden or collapsed.
     */
    for (const [leafNodes, ancestors] of this.eachDescendantDepthFirst(this.list, 1, [])) {
      const parent: TreeViewSubTreeNodeElement | undefined = ancestors[ancestors.length - 1]
      let atLeastOneLeafMatches = false

      for (const leafNode of leafNodes) {
        if (cachedFilterFn(leafNode, query, mode)) {
          leafNode.closest('li')?.removeAttribute('hidden')
          atLeastOneLeafMatches = true
        } else {
          leafNode.closest('li')?.setAttribute('hidden', 'hidden')
        }
      }

      if (atLeastOneLeafMatches) {
        expandAncestors(...ancestors)
      } else {
        if (parent) {
          if (cachedFilterFn(parent.node, query, mode)) {
            // sub-tree matched, so expand ancestors
            expandAncestors(...ancestors)
          } else {
            // this node has already been marked by the current generation and is therefore
            // a shared ancestor - don't collapse or hide it
            if (parent.getAttribute('data-generation') !== generation) {
              parent.collapse()
              parent.setAttribute('hidden', 'hidden')
            }
          }
        }
      }
    }

    // convert range map into a 1-dimensional array with no nulls so it can be given to
    // #applyHighlights (and therefore CSS.highlights.set) more easily
    const allRanges = Array.from(filterRangesCache.values())
      .flat()
      .filter(r => r !== null)

    if (allRanges.length === 0 && query.length > 0) {
      this.list.setAttribute('hidden', 'hidden')
      this.noResults.removeAttribute('hidden')
    } else {
      this.list.removeAttribute('hidden')
      this.noResults.setAttribute('hidden', 'hidden')

      this.#applyHighlights(allRanges)
    }
  }

  #applyHighlights(ranges: Range[]) {
    // Attempt to use the new-ish custom highlight API:
    // https://developer.mozilla.org/en-US/docs/Web/API/CSS_Custom_Highlight_API
    if (CSS.highlights) {
      CSS.highlights.set('primer-filterable-tree-view-search-results', new Highlight(...ranges))
    } else {
      this.#applyManualHighlights(ranges)
    }
  }

  #applyManualHighlights(ranges: Range[]) {
    const textNode = ranges[0].startContainer
    const parent = textNode.parentNode!
    const originalText = textNode.textContent!
    const fragments = []
    let lastIndex = 0

    for (const {startOffset, endOffset} of ranges) {
      // text before the highlight
      if (startOffset > lastIndex) {
        fragments.push(document.createTextNode(originalText.slice(lastIndex, startOffset)))
      }

      // highlighted text
      const mark = document.createElement('mark')
      mark.textContent = originalText.slice(startOffset, endOffset)
      fragments.push(mark)

      lastIndex = endOffset
    }

    // remaining text after the last highlight
    if (lastIndex < originalText.length) {
      fragments.push(document.createTextNode(originalText.slice(lastIndex)))
    }

    // replace original text node with our text + <mark> elements
    for (const frag of fragments.reverse()) {
      parent.insertBefore(frag, textNode.nextSibling)
    }

    parent.removeChild(textNode)
  }

  #removeHighlights() {
    // quick-and-dirty way of ignoring any existing <mark> elements and restoring
    // the original text
    for (const mark of this.querySelectorAll('mark')) {
      if (!mark.parentElement) continue
      mark.parentElement.replaceChildren(mark.parentElement.textContent!)
    }
  }

  #inErrorState(): boolean {
    if (!this.bannerErrorElement) return false

    return !this.bannerErrorElement.hasAttribute('hidden')
  }

  #setErrorState(type: ErrorStateType) {
    const errorElement = this.bannerErrorElement
    this.bannerErrorElement?.removeAttribute('hidden')

    // check if the errorElement is visible in the dom
    if (errorElement && !errorElement.hasAttribute('hidden')) {
      this.liveRegion.announceFromElement(errorElement, {politeness: 'assertive'})
      return
    }
  }

  #clearErrorState() {
    this.bannerErrorElement.setAttribute('hidden', '')
  }

  #maybeAnnounce() {
    // if (this.open && this.list) {
    //   const items = this.visibleItems
    //   if (items.length > 0) {
    //     const instructions = 'tab for results'
    //     this.liveRegion.announce(`${items.length} result${items.length === 1 ? '' : 's'} ${instructions}`)
    //   } else {
    //     const noResultsEl = this.noResults
    //     if (noResultsEl) {
    //       this.liveRegion.announceFromElement(noResultsEl)
    //     }
    //   }
    // }
  }

  get #filterInputTextFieldElement(): PrimerTextFieldElement | null {
    return this.filterInputTextField?.closest('primer-text-field') as PrimerTextFieldElement | null
  }

  #handleInvokerActivated(event: Event) {
    event.preventDefault()

    // eslint-disable-next-line no-restricted-syntax
    event.stopPropagation()

    if (this.open) {
      this.hide()
    } else {
      this.show()
    }
  }

  #handleDialogItemActivated(event: Event, dialog: HTMLElement) {
    this.querySelector<HTMLElement>('.TreeViewRootUlStyles')!.style.display = 'none'
    const dialog_controller = new AbortController()
    const {signal} = dialog_controller
    const handleDialogClose = () => {
      dialog_controller.abort()
      this.querySelector<HTMLElement>('.TreeViewRootUlStyles')!.style.display = ''
      if (this.open) {
        this.hide()
      }
      const activeElement = this.ownerDocument.activeElement
      const lostFocus = this.ownerDocument.activeElement === this.ownerDocument.body
      const focusInClosedMenu = this.contains(activeElement)
      if (lostFocus || focusInClosedMenu) {
        setTimeout(() => this.invokerElement?.focus(), 0)
      }
    }
    // a modal <dialog> element will close all popovers
    dialog.addEventListener('close', handleDialogClose, {signal})
    dialog.addEventListener('cancel', handleDialogClose, {signal})
  }

  #handleItemActivated(item: SelectTreePanelItem) {
    // Hide popover after current event loop to prevent changes in focus from
    // altering the target of the event. Not doing this specifically affects
    // <a> tags. It causes the event to be sent to the currently focused element
    // instead of the anchor, which effectively prevents navigation, i.e. it
    // appears as if hitting enter does nothing. Curiously, clicking instead
    // works fine.
    if (this.selectVariant !== 'multiple') {
      setTimeout(() => {
        if (this.open) {
          this.hide()
        }
      })
    }

    // The rest of the code below deals with single/multiple selection behavior, and should not
    // interfere with events fired by menu items whose behavior is specified outside the library.
    if (this.selectVariant !== 'multiple' && this.selectVariant !== 'single') return

    //const currentlyChecked = this.isItemChecked(item)
    //const checked = !currentlyChecked

    // const activationSuccess = this.dispatchEvent(
    //   new CustomEvent('beforeItemActivated', {
    //     bubbles: true,
    //     cancelable: true,
    //     detail: {
    //       item,
    //       checked,
    //       value: this.#getItemContent(item)?.getAttribute('data-value'),
    //     },
    //   }),
    // )

    // if (!activationSuccess) return

    // const itemContent = this.#getItemContent(item)

    // if (this.selectVariant === 'single') {
    //   // Don't check anything if we have an href
    //   if (itemContent?.getAttribute('href')) return

    //   // disallow unchecking checked item in single-select mode
    //   if (!currentlyChecked) {
    //     // for (const el of this.items) {
    //     //   this.#getItemContent(el)?.setAttribute(this.ariaSelectionType, 'false')
    //     // }

    //     this.#selectedItems.clear()

    //     if (checked) {
    //       this.#addSelectedItem(item)
    //       itemContent?.setAttribute(this.ariaSelectionType, 'true')
    //     }

    //     this.#setDynamicLabel()
    //   }
    // } else {
    //   // multi-select mode allows unchecking a checked item
    //   itemContent?.setAttribute(this.ariaSelectionType, `${checked}`)

    //   if (checked) {
    //     this.#addSelectedItem(item)
    //   } else {
    //     this.#removeSelectedItem(item)
    //   }

    this.#updateInput()
    this.#updateTabIndices()

    // this.dispatchEvent(
    //   new CustomEvent('itemActivated', {
    //     bubbles: true,
    //     detail: {
    //       item,
    //       checked,
    //       value: this.#getItemContent(item)?.getAttribute('data-value'),
    //     },
    //   }),
    // )
  }

  show() {
    this.updateAnchorPosition()
    this.dialog.showModal()
    this.invokerElement?.setAttribute('aria-expanded', 'true')
    const event = new CustomEvent('dialog:open', {
      detail: {dialog: this.dialog},
    })
    this.dispatchEvent(event)
  }

  hide() {
    this.dialog.close()
  }

  #setDynamicLabel() {
    if (!this.dynamicLabel) return
    const invokerLabel = this.invokerLabel
    if (!invokerLabel) return
    this.#originalLabel ||= invokerLabel.textContent || ''
    const itemLabel =
      this.querySelector(`[${this.ariaSelectionType}=true] .ActionListItem-label`)?.textContent || this.#originalLabel
    if (itemLabel) {
      const prefixSpan = document.createElement('span')
      prefixSpan.classList.add('color-fg-muted')
      const contentSpan = document.createElement('span')
      prefixSpan.textContent = `${this.dynamicLabelPrefix} `
      contentSpan.textContent = itemLabel
      invokerLabel.replaceChildren(prefixSpan, contentSpan)

      if (this.dynamicAriaLabelPrefix) {
        this.invokerElement?.setAttribute('aria-label', `${this.dynamicAriaLabelPrefix} ${itemLabel.trim()}`)
      }
    } else {
      invokerLabel.textContent = this.#originalLabel
    }
  }

  #updateInput() {
    if (this.selectVariant === 'single') {
      const input =
        (this.querySelector(`[data-select-panel-inputs=true] input`) as HTMLInputElement) ??
        (this.querySelector(`[data-list-inputs=true] input`) as HTMLInputElement)
      if (!input) return

      const selectedItem = this.selectedItems[0]

      if (selectedItem) {
        input.value = (selectedItem.value || selectedItem.label || '').trim()
        if (selectedItem.inputName) input.name = selectedItem.inputName
        input.removeAttribute('disabled')
      } else if (this.#hasLoadedData) {
        input.setAttribute('disabled', 'disabled')
      }
    } else if (this.selectVariant !== 'none') {
      // multiple select variant
      const inputList =
        this.querySelector('[data-select-panel-inputs=true]') ?? this.querySelector('[data-list-inputs=true]')
      if (!inputList) return

      const inputs = inputList.querySelectorAll('input')

      if (inputs.length > 0) {
        this.#inputName ||= (inputs[0] as HTMLInputElement).name
      }

      // for (const selectedItem of this.selectedItems) {
      //   const newInput = document.createElement('input')
      //   newInput.setAttribute(`${isRemoteInput ? 'data-select-panel-input' : 'data-list-input'}`, 'true')
      //   newInput.type = 'hidden'
      //   newInput.autocomplete = 'off'
      //   newInput.name = selectedItem.inputName || this.#inputName
      //   newInput.value = (selectedItem.value || selectedItem.label || '').trim()

      //   inputList.append(newInput)
      // }

      // for (const input of inputs) {
      //   input.remove()
      // }
    }
  }

  #restoreNodeState(subTree: TreeViewSubTreeNodeElement) {
    if (!this.treeView) return
    if (!this.#stateMap.has(subTree)) return

    const descendantStates = this.#stateMap.get(subTree)!

    for (const [element, state] of descendantStates.entries()) {
      let node = element

      if (element instanceof TreeViewSubTreeNodeElement) {
        node = element.node
      }

      this.treeView.setNodeCheckedValue(node, state.checked ? 'true' : 'false')
      this.treeView.setNodeDisabledValue(node, state.disabled)
    }

    // once node state has been restored, there's no reason to keep it around - it will be saved
    // again if this sub-tree gets checked
    this.#stateMap.delete(subTree)
  }

  // Revert all nodes back to their saved state, i.e. from before we automatically checked and disabled
  // everything.
  #restoreAllNodeStates() {
    for (const subTree of this.#stateMap.keys()) {
      this.#restoreNodeState(subTree)
    }
  }

  // Iterates over the nodes in the given sub-tree in depth-first order, yielding a list of leaf nodes
  // and an array of ancestor nodes. It uses the aria-level information attached to each node to determine
  // the next level of the tree to visit.
  *eachDescendantDepthFirst(
    node: HTMLElement,
    level: number,
    ancestry: TreeViewSubTreeNodeElement[],
  ): Generator<[NodeListOf<HTMLElement>, TreeViewSubTreeNodeElement[]]> {
    for (const subTreeItem of node.querySelectorAll<HTMLElement>(
      `[role=treeitem][data-node-type='sub-tree'][aria-level='${level}']`,
    )) {
      const subTree = subTreeItem.closest('tree-view-sub-tree-node') as TreeViewSubTreeNodeElement
      yield* this.eachDescendantDepthFirst(subTree, level + 1, [...ancestry, subTree])
    }

    const leafNodes = node.querySelectorAll<HTMLElement>(
      `[role=treeitem][data-node-type='leaf'][aria-level='${level}']`,
    )

    yield [leafNodes, ancestry]
  }

  // Yields only the shallowest (i.e. lowest depth) sub-tree nodes that are checked, i.e. does not
  // visit a sub-tree's children if that sub-tree is checked.
  *eachShallowestCheckedSubTree(root: TreeViewSubTreeNodeElement): Generator<TreeViewSubTreeNodeElement> {
    if (this.treeView?.getNodeCheckedValue(root.node) === 'true') {
      yield root
      return // do not descend further
    }

    for (const childSubTree of root.eachDirectDescendantSubTreeNode()) {
      yield* this.eachShallowestCheckedSubTree(childSubTree)
    }
  }
}

if (!window.customElements.get('select-panel')) {
  window.SelectTreePanelElement = SelectTreePanelElement
  window.customElements.define('select-panel', SelectTreePanelElement)
}

declare global {
  interface Window {
    SelectTreePanelElement: typeof SelectTreePanelElement
  }
}
