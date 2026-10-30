import {controller, target} from '@github/catalyst'
import '@oddbird/popover-polyfill'
import type {IncludeFragmentElement} from '@github/include-fragment-element'
import AnchoredPositionElement from '../../anchored_position'
import {observeMutationsUntilConditionMet} from '../../utils'
import {ActionMenuFocusZoneStack} from './action_menu_focus_zone_stack'
import {ClipboardCopyElement} from '@github/clipboard-copy-element'

type SelectVariant = 'none' | 'single' | 'multiple' | null
type SelectedItem = {
  label: string | null | undefined
  value: string | null | undefined
  element: Element
}

@controller('action-menu')
export class ActionMenuElement extends HTMLElement {
  @target includeFragment: IncludeFragmentElement
  @target overlay: AnchoredPositionElement
  @target list: HTMLElement

  #abortController: AbortController
  #originalLabel = ''
  #inputName = ''
  #invokerBeingClicked = false
  #intersectionObserver: IntersectionObserver
  #focusZoneStack: ActionMenuFocusZoneStack

  // Deferred primary content, refreshed when `src` changes. #deferred is set
  // once, at first connect, when the primary overlay body holds a fragment.
  #deferred = false
  // Configuration: an unloaded copy of the fragment new loads are cloned from.
  // Only fragments inserted by other code replace it.
  #template: IncludeFragmentElement | null = null
  // The current request; `failed` comes from the fragment's `error` event.
  #request: {fragment: IncludeFragmentElement; src: string; failed: boolean} | null = null
  // UI listener lifetime for the current fragment; aborted on disconnect.
  #fragmentAbortController: AbortController | null = null
  // Failure listener lifetime for the current request; aborted only when a
  // new request supersedes it, so failures while detached are recorded.
  #requestAbortController: AbortController | null = null
  // A src assigned while detached that would otherwise have refreshed (for
  // example the same src after a failure); applied on reconnect.
  #pendingSrc: string | null = null
  #fragmentObserver: MutationObserver | null = null

  static observedAttributes = ['src']

  static validItemRoles = ['menuitem', 'menuitemcheckbox', 'menuitemradio']
  static validSelectors = ActionMenuElement.validItemRoles.map(role => `[role="${role}"]`)
  static menuItemSelectors = ActionMenuElement.validSelectors.map(selector => `:not([hidden]) > ${selector}`)

  get selectVariant(): SelectVariant {
    return this.getAttribute('data-select-variant') as SelectVariant
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

  set dynamicLabelPrefix(value: string) {
    this.setAttribute('data-dynamic-label', value)
  }

  get dynamicLabel(): boolean {
    return this.hasAttribute('data-dynamic-label')
  }

  set dynamicLabel(value: boolean) {
    this.toggleAttribute('data-dynamic-label', value)
  }

  get popoverElement(): HTMLElement | null {
    return (this.invokerElement?.popoverTargetElement as HTMLElement) || null
  }

  // i.e. sub-menus
  get childPopoverElements(): HTMLElement[] {
    return Array.from(this.overlay.querySelectorAll('anchored-position')) as AnchoredPositionElement[]
  }

  get invokerElement(): HTMLButtonElement | null {
    const id = this.querySelector('[role=menu]')?.id
    if (!id) return null
    for (const el of this.querySelectorAll(`[aria-controls]`)) {
      if (el.getAttribute('aria-controls') === id) {
        return el as HTMLButtonElement
      }
    }
    return null
  }

  get invokerLabel(): HTMLElement | null {
    if (!this.invokerElement) return null
    return this.invokerElement.querySelector('.Button-label')
  }

  get selectedItems(): SelectedItem[] {
    const selectedItems = this.querySelectorAll('[aria-checked=true]')
    const results: SelectedItem[] = []

    for (const selectedItem of selectedItems) {
      const labelEl = selectedItem.querySelector('.ActionListItem-label')

      results.push({
        label: labelEl?.textContent,
        value: selectedItem?.getAttribute('data-value'),
        element: selectedItem,
      })
    }

    return results
  }

  connectedCallback() {
    const {signal} = (this.#abortController = new AbortController())
    this.addEventListener('keydown', this, {signal})
    this.addEventListener('click', this, {signal})
    this.addEventListener('mouseover', this, {signal})
    this.addEventListener('focusout', this, {signal})
    this.addEventListener('mousedown', this, {signal})
    this.addEventListener('toggle', this, {signal, capture: true})
    this.#setDynamicLabel()
    this.#updateInput()
    this.#softDisableItems()

    const primaryFragment = this.#deferred ? null : this.#primaryFragment()

    if (this.#deferred) {
      // re-attached
      this.#reconcile()
    } else if (primaryFragment) {
      this.#deferred = true
      this.#template = this.#templateFrom(primaryFragment)
      this.#track(primaryFragment)
      this.#observeFragments()
    } else if (this.includeFragment) {
      // deferred sub-menu
      this.includeFragment.addEventListener('include-fragment-replaced', this, {
        signal,
      })
    }

    // The code below updates the menu (i.e. overlay) position whenever the invoker button
    // changes position within its scroll container.
    //
    // See: https://github.com/primer/view_components/issues/3175

    const scrollUpdater = () => {
      if (this.#isOpen()) {
        this.overlay?.update()
      }
    }

    this.#intersectionObserver = new IntersectionObserver(entries => {
      for (const entry of entries) {
        const elem = entry.target
        if (elem === this.invokerElement) {
          if (entry.isIntersecting) {
            // eslint-disable-next-line github/prefer-observers
            window.addEventListener('scroll', scrollUpdater, {capture: true})
          } else {
            window.removeEventListener('scroll', scrollUpdater, {capture: true})
          }
        }
      }
    })

    observeMutationsUntilConditionMet(
      this,
      () => Boolean(this.invokerElement),
      () => this.#intersectionObserver.observe(this.invokerElement!),
    )

    // If there's no include fragment, then no async fetching will occur and we can
    // mark the component as ready.
    if (!this.includeFragment) {
      this.setAttribute('data-ready', 'true')
    }

    const levelObserver = new MutationObserver(() => this.#updateLevels())
    levelObserver.observe(this, {childList: true, subtree: true})

    this.#updateLevels()

    this.#focusZoneStack = new ActionMenuFocusZoneStack()
  }

  #updateLevels() {
    let idx = 1

    for (const menu of this.querySelectorAll('[role=menu]')) {
      menu.setAttribute('data-level', idx.toString())
      idx++
    }
  }

  disconnectedCallback() {
    this.#abortController.abort()
    this.#focusZoneStack.clear()
    this.#fragmentAbortController?.abort()
    this.#fragmentObserver?.disconnect()
  }

  attributeChangedCallback(name: string, _oldValue: string | null, newValue: string | null) {
    if (name !== 'src' || !this.#deferred || !this.#template || !newValue?.trim()) return
    // An unchanged src only retries a failed request
    if (newValue === this.#request?.src && !this.#request.failed) return
    if (!this.isConnected) {
      this.#pendingSrc = newValue
      return
    }

    this.#refresh(newValue)
  }

  // Catches up with whatever happened to the deferred content while the menu
  // was detached: a src change or requested retry, a still-pending request
  // (whose completion listener was aborted), an inserted fragment, or a
  // completed load.
  #reconcile() {
    this.#observeFragments()

    const src = this.getAttribute('src')
    const pendingSrc = this.#pendingSrc
    this.#pendingSrc = null
    if (src?.trim() && (src !== this.#request?.src || src === pendingSrc)) {
      this.#refresh(src)
      return
    }

    const body = this.#primaryBody()
    const current = this.#request?.fragment

    if (current && body && current.parentElement === body) {
      this.#bind(current)
      return
    }

    const fragment = this.#primaryFragment()

    if (fragment) {
      this.#adopt(fragment)
    } else if (!this.hasAttribute('data-ready')) {
      this.#handleIncludeFragmentReplaced()
    }
  }

  // The current primary overlay's body. Looked up on every call, since other
  // code may replace the body or the overlay.
  #primaryBody(): HTMLElement | null {
    const overlay = this.overlay
    if (!overlay) return null

    for (const body of overlay.querySelectorAll<HTMLElement>('.Overlay-body')) {
      if (body.closest('anchored-position') === overlay) return body
    }

    return null
  }

  #primaryFragment(): IncludeFragmentElement | null {
    const body = this.#primaryBody()
    if (!body) return null

    for (const child of body.children) {
      if (child.localName === 'include-fragment') return child as IncludeFragmentElement
    }

    return null
  }

  #templateFrom(fragment: IncludeFragmentElement): IncludeFragmentElement {
    const template = fragment.cloneNode(true) as IncludeFragmentElement
    template.classList.remove('is-error')
    return template
  }

  // Binds the completion listener to the fragment, dropping any bound to a
  // previous one. Superseded fragments still dispatch events.
  #bind(fragment: IncludeFragmentElement) {
    this.#fragmentAbortController?.abort()
    const {signal} = (this.#fragmentAbortController = new AbortController())

    fragment.addEventListener('include-fragment-replaced', this, {signal})
  }

  // Makes the fragment the current request. Its failure listener outlives
  // disconnects: upstream never replays `error` for a cached rejection.
  #track(fragment: IncludeFragmentElement) {
    this.#request = {fragment, src: fragment.getAttribute('src') || '', failed: false}
    // The response decides the form field name
    this.#inputName = ''

    this.#requestAbortController?.abort()
    const {signal} = (this.#requestAbortController = new AbortController())
    fragment.addEventListener(
      'error',
      () => {
        if (this.#request?.fragment === fragment) this.#request.failed = true
      },
      {signal},
    )

    this.#bind(fragment)
    this.removeAttribute('data-ready')
  }

  // Makes a fragment inserted by other code current and reflects its src.
  #adopt(fragment: IncludeFragmentElement) {
    if (this.#request?.fragment === fragment) return

    this.#template = this.#templateFrom(fragment)
    this.#track(fragment)

    if (this.#isOpen()) {
      this.#keepOpenWhileLoading(fragment)
    } else {
      this.#pruneFocusZones()
    }

    // #request.src already matches, so attributeChangedCallback does nothing
    const src = fragment.getAttribute('src')
    if (src) this.setAttribute('src', src)
  }

  #observeFragments() {
    this.#fragmentObserver?.disconnect()
    this.#fragmentObserver = new MutationObserver(records => this.#adoptAddedFragments(records))
    this.#fragmentObserver.observe(this, {childList: true, subtree: true})
  }

  #adoptAddedFragments(records: MutationRecord[]) {
    const candidates = new Set<IncludeFragmentElement>()

    for (const record of records) {
      for (const node of record.addedNodes) {
        if (!(node instanceof Element)) continue
        if (node.localName === 'include-fragment') candidates.add(node as IncludeFragmentElement)

        for (const fragment of node.querySelectorAll<IncludeFragmentElement>('include-fragment')) {
          candidates.add(fragment)
        }
      }
    }

    if (candidates.size === 0) return

    // Records can describe nodes a later mutation already removed
    const body = this.#primaryBody()

    for (const fragment of candidates) {
      if (body && fragment.isConnected && fragment.parentElement === body) {
        this.#adopt(fragment)
      }
    }
  }

  // Replaces the primary body's children with a new loader for src. An open
  // menu stays open: its loader is eager (this clone only, not #template)
  // and it takes over before the old items are removed.
  #refresh(src: string) {
    const body = this.#primaryBody()
    if (!this.#template || !body) return

    const open = this.#isOpen()
    const clone = this.#template.cloneNode(true) as IncludeFragmentElement
    clone.setAttribute('src', src)
    if (open) clone.setAttribute('loading', 'eager')

    body.prepend(clone)
    this.#track(clone)

    if (open) this.#keepOpenWhileLoading(clone)

    for (const child of Array.from(body.childNodes)) {
      if (child !== clone) child.remove()
    }
  }

  // Keeps the open menu open while fragment loads into its body. Open
  // sub-menus are torn down first, since their toggle events arrive after
  // the nodes are gone, and focus moves to the fragment's spinner before the
  // focusout frame runs, so it never drops to <body> and closes the menu.
  #keepOpenWhileLoading(fragment: IncludeFragmentElement) {
    this.#pruneFocusZones()
    this.#focusZoneStack.popAbove(this.overlay)

    for (const child of this.childPopoverElements) {
      if (child.matches(':popover-open')) child.hidePopover()
    }

    fragment.querySelector<HTMLElement>('[role=menuitem]')?.focus()
  }

  // Drops focus zones of overlays other code removed, such as a replaced
  // primary overlay and its sub-menus.
  #pruneFocusZones() {
    this.#focusZoneStack.prune(element => element.isConnected && this.contains(element))
  }

  #softDisableItems() {
    const {signal} = this.#abortController

    for (const item of this.querySelectorAll(ActionMenuElement.validSelectors.join(','))) {
      item.addEventListener('click', this.#potentiallyDisallowActivation.bind(this), {signal})
      item.addEventListener('keydown', this.#potentiallyDisallowActivation.bind(this), {signal})
    }
  }

  // returns true if activation was prevented
  #potentiallyDisallowActivation(event: Event): boolean {
    if (!this.#isActivation(event)) return false

    const item = (event.target as HTMLElement).closest(ActionMenuElement.menuItemSelectors.join(','))
    if (!item) return false

    if (item.getAttribute('aria-disabled')) {
      event.preventDefault()
      /* eslint-disable-next-line no-restricted-syntax */
      event.stopPropagation()
      /* eslint-disable-next-line no-restricted-syntax */
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

  #isClipboardActivationViaKeyboard(event: Event): boolean {
    return (
      event.target instanceof ClipboardCopyElement &&
      event instanceof KeyboardEvent &&
      event.type === 'keydown' &&
      !(event.ctrlKey || event.altKey || event.metaKey || event.shiftKey) &&
      (event.key === ' ' || event.key === 'Enter')
    )
  }

  #isActivation(event: Event): boolean {
    // Some browsers fire MouseEvents (Firefox) and others fire PointerEvents (Chrome). Activating an item via
    // enter or space counterintuitively fires one of these rather than a KeyboardEvent. Since PointerEvent
    // inherits from MouseEvent, it is enough to check for MouseEvent here.
    return (
      (event instanceof MouseEvent && event.type === 'click') ||
      this.#isAnchorActivationViaSpace(event) ||
      this.#isClipboardActivationViaKeyboard(event)
    )
  }

  handleEvent(event: Event) {
    const targetIsInvoker = this.invokerElement?.contains(event.target as HTMLElement)
    const eventIsActivation = this.#isActivation(event)

    if (event.type === 'toggle' && event instanceof ToggleEvent) {
      this.#handleToggleEvent(event)
      return
    }

    if (targetIsInvoker && event.type === 'mousedown') {
      this.#invokerBeingClicked = true
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
      this.#invokerBeingClicked = false
      return
    }

    if (event.type === 'focusout') {
      if (this.#invokerBeingClicked) return

      // Give the browser time to focus the next element
      requestAnimationFrame(() => {
        if (!this.contains(document.activeElement) || document.activeElement === this.invokerElement) {
          this.#handleFocusOut()
        }
      })

      return
    }

    const item = (event.target as Element).closest(ActionMenuElement.menuItemSelectors.join(',')) as HTMLElement | null
    const targetIsItem = item !== null

    if (targetIsItem && eventIsActivation) {
      if (this.#potentiallyDisallowActivation(event)) return

      const dialogInvoker = item.closest('[data-show-dialog-id]')

      if (dialogInvoker) {
        const dialog = this.ownerDocument.getElementById(dialogInvoker.getAttribute('data-show-dialog-id') || '')

        if (dialog && this.contains(dialogInvoker)) {
          this.#handleDialogItemActivated(event, dialog)
          return
        }
      }

      // Pressing the space key on a link will cause the page to scroll unless preventDefault() is called.
      // We then click it manually to navigate.
      if (this.#isAnchorActivationViaSpace(event)) {
        event.preventDefault()
        item.click()
      }

      const subMenu = this.#subMenuForItem(item)

      if (subMenu) {
        // Prevent submitting a form when clicking on sub-menu items
        event.preventDefault()
        subMenu.showPopover()
        return
      }

      this.#handleItemActivated(item)

      return
    }

    if (event.type === 'include-fragment-replaced') {
      this.#handleIncludeFragmentReplaced()
      return
    }

    if (targetIsItem && event instanceof KeyboardEvent) {
      this.#handleItemKeyboardEvent(event, item)
    }
  }

  #handleItemKeyboardEvent(event: KeyboardEvent, item: HTMLElement) {
    switch (event.key) {
      case 'ArrowRight': {
        const subMenu = this.#subMenuForItem(item)
        subMenu?.showPopover()
        break
      }

      case 'ArrowLeft':
        if (item.closest('role[menu]') !== this.list) {
          const overlay = item.closest('anchored-position') as AnchoredPositionElement | null
          overlay?.hidePopover()
        }

        break
    }
  }

  #handleToggleEvent(event: ToggleEvent) {
    const subMenu = event.target as AnchoredPositionElement

    // Ignore toggle events from non-anchored-position elements (e.g. tooltips inside the menu)
    if (!(event.target instanceof AnchoredPositionElement)) return

    if (event.newState === 'open') {
      // allow tabbing away from primary menu, but trap focus in sub-menus
      const isPrimaryMenu = subMenu === this.overlay
      this.#focusZoneStack.push(subMenu, {trapFocus: !isPrimaryMenu})

      window.requestAnimationFrame(() => {
        const firstItem = subMenu.querySelector(ActionMenuElement.menuItemSelectors.join(',')) as HTMLElement | null
        firstItem?.focus()
      })
    } else {
      // Note that this will also cause focus to return to the invoker button, which is
      // desirable
      this.#focusZoneStack.pop(subMenu)
      const item = this.#itemForSubMenu(subMenu)
      const openPopover = document.querySelector(':popover-open')
      if (item && !openPopover) {
        item.focus()
      }
    }
  }

  #handleInvokerActivated(event: Event) {
    event.preventDefault()
    /* eslint-disable-next-line no-restricted-syntax */
    event.stopPropagation()

    if (this.#isOpen()) {
      this.#hide()
    } else {
      this.#show()
    }
  }

  #handleDialogItemActivated(event: Event, dialog: HTMLElement) {
    if (this.contains(dialog)) {
      this.querySelector<HTMLElement>('.ActionListWrap')!.style.display = 'none'
    }
    const dialog_controller = new AbortController()
    const {signal} = dialog_controller
    const handleDialogClose = () => {
      dialog_controller.abort()
      if (this.contains(dialog)) {
        this.querySelector<HTMLElement>('.ActionListWrap')!.style.display = ''
        if (this.#isOpen()) {
          this.#hide()
        }
      }
      const activeElement = this.ownerDocument.activeElement
      const lostFocus = this.ownerDocument.activeElement === this.ownerDocument.body
      const focusInClosedMenu = this.contains(activeElement)
      const focusInDialog = dialog.contains(activeElement)
      if (lostFocus || focusInClosedMenu || focusInDialog) {
        setTimeout(() => {
          // if the activeElement has changed after a task, then it's likely
          // that other JS has tried to shift focus. We should respect that
          // focus shift as long as it's not back at the document.
          const newActiveElement = this.ownerDocument.activeElement
          if (newActiveElement === activeElement || newActiveElement === this.ownerDocument.body) {
            this.invokerElement?.focus()
          }
        }, 0)
      }
    }
    // a modal <dialog> element will close all popovers
    dialog.addEventListener('close', handleDialogClose, {signal})
    dialog.addEventListener('cancel', handleDialogClose, {signal})
  }

  #handleItemActivated(item: HTMLElement) {
    // Hide popover after current event loop to prevent changes in focus from
    // altering the target of the event. Not doing this specifically affects
    // <a> tags. It causes the event to be sent to the currently focused element
    // instead of the anchor, which effectively prevents navigation, i.e. it
    // appears as if hitting enter does nothing. Curiously, clicking instead
    // works fine.
    if (this.selectVariant !== 'multiple') {
      setTimeout(() => {
        if (this.#isOpen()) {
          this.#hide()
        }
      })
    }

    // The rest of the code below deals with single/multiple selection behavior, and should not
    // interfere with events fired by menu items whose behavior is specified outside the library.
    if (this.selectVariant !== 'multiple' && this.selectVariant !== 'single') return

    const ariaChecked = item.getAttribute('aria-checked')
    const checked = ariaChecked !== 'true'

    if (this.selectVariant === 'single') {
      // Only check, never uncheck here. Single-select mode does not allow unchecking a checked item.
      if (checked) {
        item.setAttribute('aria-checked', 'true')
      }

      for (const checkedItem of this.querySelectorAll('[aria-checked]')) {
        if (checkedItem !== item) {
          checkedItem.setAttribute('aria-checked', 'false')
        }
      }

      this.#setDynamicLabel()
    } else {
      // multi-select mode allows unchecking a checked item
      item.setAttribute('aria-checked', `${checked}`)

      this.#setDynamicLabel()
    }

    this.#updateInput()

    this.dispatchEvent(
      new CustomEvent('itemActivated', {
        bubbles: true,
        detail: {item: item.parentElement, checked: this.isItemChecked(item.parentElement)},
      }),
    )
  }

  #handleIncludeFragmentReplaced() {
    // Content can finish loading while the menu is detached
    if (this.isConnected) {
      const firstItem = this.#firstItem

      if (firstItem) {
        firstItem.focus()
      } else if (this.overlay?.matches(':popover-open')) {
        // Nothing to focus in an empty response: close and return to the
        // button. invokerElement and popoverElement need the removed list.
        this.overlay.hidePopover()
        this.#itemForSubMenu(this.overlay)?.focus()
      }

      this.overlay?.update()
    }
    this.#setDynamicLabel()
    this.#updateInput()
    this.#softDisableItems()

    // async items have loaded, so component is ready
    this.setAttribute('data-ready', 'true')
  }

  // Close when focus leaves menu
  #handleFocusOut() {
    this.#hide()
  }

  #show() {
    this.popoverElement?.showPopover()
  }

  #hide() {
    this.popoverElement?.hidePopover()

    for (const child of this.childPopoverElements) {
      child.hidePopover()
    }
  }

  #isOpen() {
    return this.popoverElement?.matches(':popover-open')
  }

  #setDynamicLabel() {
    if (!this.dynamicLabel) return
    const invokerLabel = this.invokerLabel
    if (!invokerLabel) return
    this.#originalLabel ||= invokerLabel.textContent || ''
    let itemLabel: string | undefined
    if (this.selectVariant === 'single') {
      itemLabel = this.querySelector('[aria-checked=true] .ActionListItem-label')?.textContent?.trim()
    } else if (this.selectVariant === 'multiple') {
      itemLabel = Array.from(this.querySelectorAll(`[aria-checked=true] .ActionListItem-label`))
        .map(label => (label.textContent || '').trim())
        .filter(Boolean)
        .join(', ')
    }
    itemLabel ||= this.#originalLabel
    if (itemLabel && this.dynamicLabel) {
      const prefixSpan = document.createElement('span')
      prefixSpan.classList.add('color-fg-muted')
      const contentSpan = document.createElement('span')
      prefixSpan.textContent = this.dynamicLabelPrefix ? `${this.dynamicLabelPrefix} ` : ''
      contentSpan.textContent = itemLabel
      invokerLabel.replaceChildren(prefixSpan, contentSpan)
    } else {
      invokerLabel.textContent = this.#originalLabel
    }
  }

  #updateInput() {
    if (this.selectVariant === 'single') {
      const input = this.querySelector(`[data-list-inputs=true] input`) as HTMLInputElement | null
      if (!input) return

      const selectedItem = this.selectedItems[0]

      if (selectedItem) {
        input.value = (selectedItem.value || selectedItem.label || '').trim()
        input.removeAttribute('disabled')
      } else {
        input.setAttribute('disabled', 'disabled')
      }
    } else if (this.selectVariant !== 'none') {
      // multiple select variant
      const inputList = this.querySelector('[data-list-inputs=true]')
      if (!inputList) return

      const inputs = inputList.querySelectorAll('input')

      if (inputs.length > 0) {
        this.#inputName ||= (inputs[0] as HTMLInputElement).name
      }

      for (const selectedItem of this.selectedItems) {
        const newInput = document.createElement('input')
        newInput.setAttribute('data-list-input', 'true')
        newInput.type = 'hidden'
        newInput.autocomplete = 'off'
        newInput.name = this.#inputName
        newInput.value = (selectedItem.value || selectedItem.label || '').trim()

        inputList.append(newInput)
      }

      for (const input of inputs) {
        input.remove()
      }
    }
  }

  get #firstItem(): HTMLElement | null {
    return this.querySelector(ActionMenuElement.menuItemSelectors.join(','))
  }

  get items(): HTMLElement[] {
    return Array.from(this.querySelectorAll(ActionMenuElement.menuItemSelectors.join(',')))
  }

  getItemById(itemId: string): HTMLElement | null {
    return this.querySelector(`li[data-item-id="${itemId}"`)
  }

  isItemDisabled(item: Element | null): boolean {
    if (item) {
      return item.classList.contains('ActionListItem--disabled')
    } else {
      return false
    }
  }

  disableItem(item: Element | null) {
    if (item) {
      item.classList.add('ActionListItem--disabled')
      item.querySelector('.ActionListContent')!.setAttribute('aria-disabled', 'true')
    }
  }

  enableItem(item: Element | null) {
    if (item) {
      item.classList.remove('ActionListItem--disabled')
      item.querySelector('.ActionListContent')!.removeAttribute('aria-disabled')
    }
  }

  isItemHidden(item: Element | null): boolean {
    if (item) {
      return item.hasAttribute('hidden')
    } else {
      return false
    }
  }

  hideItem(item: Element | null) {
    if (item) {
      item.setAttribute('hidden', 'hidden')
    }
  }

  showItem(item: Element | null) {
    if (item) {
      item.removeAttribute('hidden')
    }
  }

  isItemChecked(item: Element | null) {
    if (item) {
      return item.querySelector('.ActionListContent')!.getAttribute('aria-checked') === 'true'
    } else {
      return false
    }
  }

  checkItem(item: Element | null) {
    if (item && (this.selectVariant === 'single' || this.selectVariant === 'multiple')) {
      const itemContent = item.querySelector('.ActionListContent')! as HTMLElement
      const ariaChecked = itemContent.getAttribute('aria-checked') === 'true'

      if (!ariaChecked) {
        this.#handleItemActivated(itemContent)
      }
    }
  }

  uncheckItem(item: Element | null) {
    if (item && (this.selectVariant === 'single' || this.selectVariant === 'multiple')) {
      const itemContent = item.querySelector('.ActionListContent')! as HTMLElement
      const ariaChecked = itemContent.getAttribute('aria-checked') === 'true'

      if (ariaChecked) {
        this.#handleItemActivated(itemContent)
      }
    }
  }

  #subMenuForItem(item: HTMLElement): AnchoredPositionElement | null {
    const popoverId = item.getAttribute('popovertarget')

    if (popoverId) {
      return this.querySelector(`[id="${popoverId}"]`) as AnchoredPositionElement
    }

    return null
  }

  #itemForSubMenu(subMenu: HTMLElement): HTMLElement | null {
    const anchorId = subMenu.getAttribute('anchor')

    if (anchorId) {
      return this.querySelector(`[id="${anchorId}"]`) as HTMLElement | null
    }

    return null
  }
}

if (!window.customElements.get('action-menu')) {
  window.ActionMenuElement = ActionMenuElement
  window.customElements.define('action-menu', ActionMenuElement)
}

declare global {
  interface Window {
    ActionMenuElement: typeof ActionMenuElement
  }
}
