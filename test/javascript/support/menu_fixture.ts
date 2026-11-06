/* eslint-disable github/unescaped-html-literal -- static fixture markup */
import {vi} from 'vitest'
import type {IncludeFragmentElement} from '@github/include-fragment-element'
import {MenuLoader} from '../../../app/components/primer/alpha/action_menu/menu_loader'

// A stand-in for <action-menu>: it reflects `src` changes to the loader the
// way ActionMenuElement's attributeChangedCallback does, and observes its
// subtree the way the element's constructor does.
class TestMenu extends HTMLElement {
  static observedAttributes = ['src']
  loader?: MenuLoader

  attributeChangedCallback() {
    this.loader?.sync()
  }
}

if (!customElements.get('test-menu')) customElements.define('test-menu', TestMenu)

export type MenuFixture = {
  host: TestMenu
  loader: MenuLoader
  body(): HTMLElement
  setSrc(src: string): void
  setOpen(open: boolean): void
  spies: {
    onLoadStart: ReturnType<typeof vi.fn<(loader: IncludeFragmentElement, keepOpen: boolean) => void>>
    onLoaded: ReturnType<typeof vi.fn<() => void>>
  }
}

export function buildMenu({src = '/items', preload = false, open = false} = {}): MenuFixture {
  const host = document.createElement('test-menu') as TestMenu
  host.setAttribute('src', src)

  const body = document.createElement('div')
  body.setAttribute('data-body', '')

  const template = document.createElement('template')
  const loaderMarkup = document.createElement('include-fragment')
  loaderMarkup.setAttribute('src', src)
  loaderMarkup.setAttribute('loading', preload ? 'eager' : 'lazy')
  const spinner = document.createElement('li')
  spinner.setAttribute('role', 'menuitem')
  spinner.textContent = 'Loading'
  const list = document.createElement('ul')
  list.append(spinner)
  loaderMarkup.append(list)
  template.content.append(loaderMarkup)

  host.append(body, template)
  document.body.append(host)

  let isOpen = open
  const spies = {
    onLoadStart: vi.fn<(loader: IncludeFragmentElement, keepOpen: boolean) => void>(),
    onLoaded: vi.fn<() => void>(),
  }

  const loader = new MenuLoader({
    element: host,
    body: () => host.querySelector<HTMLElement>(':scope > [data-body]') ?? undefined,
    template: () => template,
    isOpen: () => isOpen,
    onLoadStart: (fragment, keepOpen) => spies.onLoadStart(fragment, keepOpen),
    onLoaded: () => spies.onLoaded(),
  })
  host.loader = loader
  new MutationObserver(records => loader.mutated(records)).observe(host, {childList: true, subtree: true})

  return {
    host,
    loader,
    spies,
    body: () => host.querySelector<HTMLElement>(':scope > [data-body]')!,
    setSrc: value => host.setAttribute('src', value),
    setOpen: value => {
      isOpen = value
    },
  }
}

// A response with one menu item per label
export function items(...labels: string[]): string {
  return `<ul>${labels.map(label => `<li><button role="menuitem">${label}</button></li>`).join('')}</ul>`
}

export function inputs(name: string, value: string): string {
  return `<span data-list-inputs="true"><input type="hidden" name="${name}" value="${value}"></span>`
}
