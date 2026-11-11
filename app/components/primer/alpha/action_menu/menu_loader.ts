import type {IncludeFragmentElement} from '@github/include-fragment-element'

// What MenuLoader needs from the menu it loads into. The loader owns
// requests, adoption, readiness and kept form inputs; the menu owns focus,
// popover state, the dynamic label and input sync.
export type MenuLoaderHost = {
  // The <action-menu>: its `src` is the state, and it receives `data-ready`
  // and the form inputs kept while a load is pending
  element: HTMLElement
  // The primary overlay's body, looked up on every call, since other code
  // may replace the body or the overlay
  body(): HTMLElement | undefined
  template(): HTMLTemplateElement | undefined
  // Matches the menu's items; a response without a match is empty
  itemSelector: string
  isOpen(): boolean
  // A loader is in the body and about to replace its old content; keepOpen
  // when the menu is open or opening
  onLoadStart(fragment: IncludeFragmentElement, keepOpen: boolean): void
  // The current loader's response is in the body
  onLoaded(): void
}

type LoaderRequest = Readonly<{loader: IncludeFragmentElement; src: string}>

// Loads a deferred menu's items. The one rule (`sync`): a load starts when
// there is no current request, when the host src differs from the current
// request's, or when the body holds no element (other code emptied it, or
// the last response was empty); the current loader still in the body is
// retried. A closed lazy menu waits for the open moment (`opening`) instead.
export class MenuLoader {
  #host: MenuLoaderHost

  // The current request: the loader it was made with and the src it was
  // made for. Never updated; a new request replaces it. The src is recorded
  // because the loader's attribute is configuration a morph may rewrite while
  // the request is in flight; the record is what was requested, so a
  // rewritten loader cannot pass an old response off as new.
  #request: LoaderRequest | null = null
  // Every loader this module created or adopted, so completions of
  // superseded ones can be told apart
  #ownedLoaders = new WeakSet<IncludeFragmentElement>()
  // Loaders whose response had no menu items, with the body they left
  // empty. That body staying empty is not a reason to load again before the
  // next open; a body other code puts in its place is.
  #emptyLoaders = new WeakMap<IncludeFragmentElement, HTMLElement>()

  constructor(host: MenuLoaderHost) {
    this.#host = host
  }

  // A primary menu with `src` renders its loader as a template
  get deferred(): boolean {
    return Boolean(this.#host.template())
  }

  get #preload(): boolean {
    return this.#host.template()?.content.firstElementChild?.getAttribute('loading') === 'eager'
  }

  // The current loader is still waiting in the body
  get pending(): boolean {
    const loader = this.#request?.loader
    return Boolean(loader) && loader!.parentElement === (this.#host.body() ?? null)
  }

  // `data-ready` means no load is pending
  updateReady() {
    if (!this.deferred) return

    if (this.pending) {
      this.#host.element.removeAttribute('data-ready')
    } else {
      this.#host.element.setAttribute('data-ready', 'true')
    }
  }

  sync(opening = false) {
    const src = (this.#host.element.getAttribute('src') ?? '').trim()
    if (!this.deferred || !src) return

    if (!(opening || this.#host.isOpen() || this.#preload)) {
      // A pending or failed loader for another src must not render meanwhile;
      // a completed one is kept, so setting its src again does not reload
      if (this.#request && src !== this.#request.src && this.pending) this.#invalidate()
      return
    }

    const loader = this.#request?.loader
    if (!this.#request || src !== this.#request.src || !this.#host.body()?.firstElementChild) {
      this.#load(src, opening)
    } else if (loader?.isConnected) {
      // A retry fetches the loader's own src, which a morph may have rewritten
      if ((loader.getAttribute('src') ?? '').trim() === this.#request.src) {
        loader.classList.remove('is-error')
        loader.refetch()
      } else {
        this.#load(src, opening)
      }
    }
  }

  // Forgets the current request so the menu loads again at the current src:
  // at once when open or preloaded, otherwise when it next opens.
  refresh() {
    this.#invalidate()
    this.sync()
  }

  // Picks up loaders other code inserts into the body (the last one wins, so
  // a loader appended next to a pending one supersedes it), and loads again
  // when other code empties the body, such as a morph of the server markup,
  // which renders the body empty.
  mutated(records: MutationRecord[]) {
    if (!this.deferred) return

    const body = this.#host.body()
    if (!body) return

    if (records.some(record => record.addedNodes.length > 0)) {
      const fragments = Array.from(body.querySelectorAll<IncludeFragmentElement>(':scope > include-fragment')).filter(
        fragment => !this.#ownedLoaders.has(fragment),
      )
      const fragment = fragments.at(-1)
      if (fragment) this.#adopt(fragment)
    }

    // An empty body was emptied or replaced by other code, unless it is the
    // one the current loader left empty; loading again there would loop on a
    // preloaded menu, so that one waits for the next open
    const loader = this.#request?.loader
    if (!body.firstElementChild && !(loader && this.#emptyLoaders.get(loader) === body)) this.sync()

    this.updateReady()
  }

  // Drops the current request. Its loader is removed even while the menu is
  // detached, since upstream still completes the fetch there.
  #invalidate() {
    this.#request?.loader.remove()
    this.#request = null
    this.updateReady()
  }

  // Starts a request for src with a fresh loader from the template, which
  // replaces whatever the body holds.
  #load(src: string, opening: boolean) {
    const body = this.#host.body()
    const template = this.#host.template()?.content.firstElementChild
    if (!body || !template) return

    // Imported, not cloned, so the loader is upgraded before it connects
    const loader = this.#host.element.ownerDocument.importNode(template, true) as IncludeFragmentElement
    loader.setAttribute('src', src)
    loader.setAttribute('loading', 'eager')

    this.#request = {loader, src}
    this.#own(loader)
    this.#keepInputs(body)

    body.prepend(loader)
    this.#host.onLoadStart(loader, opening || this.#host.isOpen())
    // A focus handler may have started a newer load meanwhile
    if (this.#request?.loader !== loader) return

    for (const child of Array.from(body.childNodes)) {
      if (child !== loader) child.remove()
    }

    this.updateReady()
  }

  // Makes an inserted loader the current request. Its src is reflected onto
  // the host, so the rule sees the request as current: an open or preloaded
  // menu loads it at once (upstream's busy guard drops the duplicate for an
  // eager loader), a closed lazy one when it opens, unless the loader is eager
  // and has already started itself. Idiomorph inserts a loader before setting
  // its attributes, but sets them synchronously, so the loader arrives here
  // with its src; one that gets its src only in a later task is replaced with
  // a load at the host src. The template is not touched.
  #adopt(fragment: IncludeFragmentElement) {
    const body = this.#host.body()
    if (!body) return

    const src = (fragment.getAttribute('src') ?? '').trim()

    this.#request = {loader: fragment, src}
    this.#own(fragment)
    this.#keepInputs(body)

    const open = this.#host.isOpen()
    this.#host.onLoadStart(fragment, open)
    // A focus handler may have started a newer load meanwhile
    if (this.#request?.loader !== fragment) return

    for (const child of Array.from(body.childNodes)) {
      if (child !== fragment) child.remove()
    }

    const element = this.#host.element
    if (src && src !== element.getAttribute('src')) {
      element.setAttribute('src', src)
    } else if (this.#host.isOpen() || this.#preload) {
      // An unchanged src does not run the rule, and a lazy loader inserted
      // before its attributes never starts on its own
      this.sync()
    }
  }

  // Loaders are never reused, so the listeners need no lifetime of their own
  #own(loader: IncludeFragmentElement) {
    this.#ownedLoaders.add(loader)
    loader.addEventListener('include-fragment-replace', event => this.#onReplace(loader, event))
    loader.addEventListener('include-fragment-replaced', () => this.#onReplaced(loader))
  }

  #onReplace(loader: IncludeFragmentElement, event: Event) {
    if (loader !== this.#request?.loader) return

    // Other code removed the current loader before it completed, eg. by
    // emptying the body, or rewrote its src, eg. by a morph: its response is
    // not the one requested and must not render or mark the menu ready
    const body = this.#host.body()
    if (!body || loader.parentElement !== body || (loader.getAttribute('src') ?? '').trim() !== this.#request.src) {
      event.preventDefault()
      return
    }

    // A response without menu items is discarded, so the body stays empty
    // and the menu loads again when it next opens
    const fragment: unknown = event instanceof CustomEvent ? event.detail?.fragment : null
    if (!(fragment instanceof DocumentFragment)) return

    if (!fragment.querySelector(this.#host.itemSelector)) {
      fragment.replaceChildren()
      this.#emptyLoaders.set(loader, body)
    }
  }

  #onReplaced(loader: IncludeFragmentElement) {
    // A superseded loader that completed late
    if (loader !== this.#request?.loader) return

    // Before the menu syncs its inputs, so they come from the response; a
    // load the menu's completion work starts keeps the response's inputs
    this.#dropKeptInputs()
    this.#host.onLoaded()
    this.updateReady()
  }

  // Keeps the current form inputs submitting while a load replaces the body,
  // also when it fails: they move to the host until a response brings its own
  #keepInputs(body: HTMLElement) {
    const inputs = body.querySelector('[data-list-inputs]')
    if (!inputs) return

    this.#dropKeptInputs()
    this.#host.element.append(inputs)
  }

  // Form inputs are kept on the host for a pending or failed load
  get keepingInputs(): boolean {
    return Boolean(this.#host.element.querySelector(':scope > [data-list-inputs]'))
  }

  #dropKeptInputs() {
    for (const inputs of this.#host.element.querySelectorAll(':scope > [data-list-inputs]')) inputs.remove()
  }
}
