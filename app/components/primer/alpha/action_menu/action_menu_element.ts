import {controller, target} from '@github/catalyst'
import '@oddbird/popover-polyfill'
import type {IncludeFragmentElement} from '@github/include-fragment-element'
import AnchoredPositionElement from '../../anchored_position'
import {observeMutationsUntilConditionMet} from '../../utils'
import {ActionMenuFocusZoneStack} from './action_menu_focus_zone_stack'
import {ClipboardCopyElement} from '@github/clipboard-copy-element'
import {MenuLoader} from './menu_loader'

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
  @target overlayBody: HTMLElement | undefined
  @target loaderTemplate: HTMLTemplateElement | undefined

  #abortController: AbortController
  #originalLabel = ''
  #inputName = ''
  #invokerBeingClicked = false
  #intersectionObserver: IntersectionObserver
  #focusZoneStack: ActionMenuFocusZoneStack

  // Loads a deferred primary menu's items; see MenuLoader
  #loader: MenuLoader

  #scrollUpdater = () => {
    if (this.#isOpen()) {
      this.overlay?.update()
    }
  }

  constructor() {
    super()

    // Never disconnected: it observes the element's own subtree, so it keeps
    // working while the element is detached. A local, not a field: the
    // registration keeps it alive as long as the element is.
    this.#loader = new MenuLoader({
      element: this,
      body: () => this.overlayBody,
      template: () => this.loaderTemplate,
      isOpen: () => this.#isOpen(),
      onLoadStart: (fragment, keepOpen) => {
        // The response decides the form field name
        this.#inputName = ''
        if (keepOpen) this.#keepOpenWhileLoading(fragment)
      },
      onLoaded: () => this.#handleIncludeFragmentReplaced(),
    })

    const observer = new MutationObserver(records => {
      // A replaced overlay may have taken open sub-menus with it
      this.#pruneFocusZones()
      this.#loader.mutated(records)
      this.#updateLevels()
    })
    observer.observe(this, {childList: true, subtree: true})

    this.#focusZoneStack = new ActionMenuFocusZoneStack()

    // The code below updates the menu (i.e. overlay) position whenever the invoker button
    // changes position within its scroll container.
    //
    // See: https://github.com/primer/view_components/issues/3175
    this.#intersectionObserver = new IntersectionObserver(entries => {
      for (const entry of entries) {
        if (entry.target !== this.invokerElement) continue

        if (entry.isIntersecting) {
          // eslint-disable-next-line github/prefer-observers
          window.addEventListener('scroll', this.#scrollUpdater, {capture: true})
        } else {
          window.removeEventListener('scroll', this.#scrollUpdater, {capture: true})
        }
      }
    })
  }

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
    if (id) {
      const el = this.querySelector<HTMLButtonElement>(`[aria-controls="${CSS.escape(id)}"]`)
      if (el) return el
    }
    const overlayId = this.overlay?.id
    return overlayId ? this.querySelector<HTMLButtonElement>(`[popovertarget="${CSS.escape(overlayId)}"]`) : null
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
    this.#bindHostListeners()
    // Kept inputs stand for the selection until a response replaces them;
    // the body holds no items to sync from meanwhile
    if (!this.#loader.keepingInputs) {
      this.#setDynamicLabel()
      this.#updateInput()
    }
    this.#softDisableItems()
    this.#setupSubMenuLoading()
    this.#loader.sync()
    this.#observeInvokerPosition()

    if (this.#loader.deferred) {
      this.#loader.updateReady()
    } else if (!this.includeFragment?.isConnected) {
      this.setAttribute('data-ready', 'true')
    }

    this.#updateLevels()
  }

  disconnectedCallback() {
    this.#abortController.abort()
    this.#focusZoneStack.clear()
    this.#intersectionObserver.disconnect()
    window.removeEventListener('scroll', this.#scrollUpdater, {capture: true})
  }

  attributeChangedCallback(name: string) {
    if (name === 'src') this.#loader.sync()
  }

  // Forgets the current request so the menu loads again at the current src:
  // at once when open or preloaded, otherwise when it next opens.
  refresh() {
    this.#loader.refresh()
  }

  #bindHostListeners() {
    const {signal} = (this.#abortController = new AbortController())
    this.addEventListener('keydown', this, {signal})
    this.addEventListener('click', this, {signal})
    this.addEventListener('mouseover', this, {signal})
    this.addEventListener('focusout', this, {signal})
    this.addEventListener('mousedown', this, {signal})
    this.addEventListener('beforetoggle', this, {signal, capture: true})
    this.addEventListener('toggle', this, {signal, capture: true})
  }

  // A static primary menu with a deferred sub-menu
  #setupSubMenuLoading() {
    if (this.#loader.deferred || !this.includeFragment) return

    this.includeFragment.addEventListener('include-fragment-replaced', this, {
      signal: this.#abortController.signal,
    })
  }

  #observeInvokerPosition() {
    observeMutationsUntilConditionMet(
      this,
      () => Boolean(this.invokerElement),
      () => this.#intersectionObserver.observe(this.invokerElement!),
    )
  }

  #updateLevels() {
    for (const [index, menu] of this.querySelectorAll('[role=menu]').entries()) {
      menu.setAttribute('data-level', String(index + 1))
    }
  }

  // Keeps the open (or opening) menu open while fragment loads into its
  // body. Open sub-menus are torn down first, since their toggle events
  // arrive after the nodes are gone, and focus moves to the fragment's
  // spinner before the focusout frame runs, so it never drops to <body> and
  // closes the menu. Called from beforetoggle, before the popover shows, the
  // focus() is a no-op; the toggle frame then focuses the spinner.
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

    if (event.type === 'beforetoggle' && event instanceof ToggleEvent) {
      this.#handleBeforeToggleEvent(event)
      return
    }

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
      // A static menu's deferred sub-menu
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

      case 'ArrowLeft': {
        const overlay = item.closest('anchored-position') as AnchoredPositionElement | null
        if (overlay && overlay !== this.overlay) {
          overlay.hidePopover()
        }

        break
      }
    }
  }

  #handleBeforeToggleEvent(event: ToggleEvent) {
    if (event.newState === 'open') {
      // A closed lazy menu catches up, and a failed load retries, as it opens
      if (event.target === this.overlay) this.#loader.sync(true)
      return
    }

    if (event.newState !== 'closed') return

    const menu = this.#toggledMenu(event)
    if (!menu) return

    this.#focusZoneStack.pop(menu)

    // The primary menu's popover hands focus back to the invoker itself
    if (menu === this.overlay) return

    // A nested popover does not hand focus back when it closes, so a sub-menu closed
    // with ArrowLeft or Escape would leave focus on the body and the focusout handler
    // would then close the whole menu. Move focus to the sub-menu's item before the
    // sub-menu hides, while focus is still inside it. Doing this synchronously, rather
    // than in the async toggle event, keeps focus from ever reaching the body.
    if (!menu.contains(document.activeElement)) return

    this.#itemForSubMenu(menu)?.focus()
  }

  #handleToggleEvent(event: ToggleEvent) {
    const menu = this.#toggledMenu(event)
    if (!menu) return

    if (event.newState === 'open') {
      // allow tabbing away from primary menu, but trap focus in sub-menus
      const isPrimaryMenu = menu === this.overlay
      this.#focusZoneStack.push(menu, {trapFocus: !isPrimaryMenu})

      // Picks up a src set by a beforetoggle listener that ran after ours
      if (isPrimaryMenu) this.#loader.sync(true)

      window.requestAnimationFrame(() => {
        const firstItem = menu.querySelector(ActionMenuElement.menuItemSelectors.join(',')) as HTMLElement | null
        firstItem?.focus()
      })
    } else if (menu === this.overlay && !document.querySelector(':popover-open')) {
      // A light-dismissed menu (e.g. a click outside it) leaves focus on the body;
      // hand it back to the invoker so the menu stays reachable from the keyboard.
      this.invokerElement?.focus()
    }
  }

  // The primary menu or a sub-menu, or null for popovers that are not menus
  // (e.g. tooltips inside the menu)
  #toggledMenu(event: ToggleEvent): AnchoredPositionElement | null {
    return event.target instanceof AnchoredPositionElement ? event.target : null
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
    // Selection first: focusing afterwards can run a consumer handler that
    // starts another load
    this.#setDynamicLabel()
    this.#updateInput()
    this.#softDisableItems()

    // Focus moves in a microtask: after the list's focus zone has processed
    // the new items (its observer would otherwise drop the focused item's
    // tab stop), and before the focusout frame would close the menu
    const activeOnLoad = document.activeElement
    queueMicrotask(() => this.#focusLoadedMenu(activeOnLoad))

    // A deferred menu's loader decides readiness
    if (!this.#loader.deferred) this.setAttribute('data-ready', 'true')
  }

  #focusLoadedMenu(activeOnLoad: Element | null) {
    // Content can finish loading while the menu is detached
    if (!this.isConnected) return

    // A consumer's completion listener, or a load it started, moved focus
    // meanwhile: keep it there
    const active = document.activeElement
    if (active !== activeOnLoad) {
      this.#restoreTabStop(active)
      return
    }

    const firstItem = this.#firstItem

    if (firstItem) {
      firstItem.focus()
    } else if (this.#isOpen()) {
      // Nothing to focus in an empty response: close and return to the
      // button.
      this.overlay.hidePopover()
      this.invokerElement?.focus()
    }

    this.overlay?.update()
  }

  // An item focused before the focus zone processed it lost its tab stop
  #restoreTabStop(element: Element | null) {
    if (
      element instanceof HTMLElement &&
      this.overlay?.contains(element) &&
      element.matches(ActionMenuElement.validSelectors.join(','))
    ) {
      element.setAttribute('tabindex', '0')
    }
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

  #isOpen(): boolean {
    return this.overlay?.matches(':popover-open') ?? false
  }

  #setDynamicLabel() {
    if (!this.dynamicLabel) return
    const invokerLabel = this.invokerLabel
    if (!invokerLabel) return
    // Kept on the host, since the button of a cloned or restored menu
    // already shows a selection
    if (!this.#originalLabel) {
      this.#originalLabel = this.getAttribute('data-original-label') ?? (invokerLabel.textContent || '')
      this.setAttribute('data-original-label', this.#originalLabel)
    }
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
      // Kept on the container too, so a cloned or restored menu with nothing
      // selected still names the inputs it creates
      this.#inputName ||= inputList.getAttribute('data-input-name') ?? ''
      if (this.#inputName) inputList.setAttribute('data-input-name', this.#inputName)

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
