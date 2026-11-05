/* eslint-disable github/unescaped-html-literal, github/no-inner-html -- static fixture markup */
import {afterEach, beforeEach, expect, test} from 'vitest'
import '@github/include-fragment-element'
import {createFetchGate, flush, type FetchGate} from './support/fetch_gate'
import {buildMenu, inputs, items} from './support/menu_fixture'

let gate: FetchGate

beforeEach(() => {
  gate = createFetchGate()
  gate.install()
})

afterEach(() => {
  gate.restore()
  document.body.replaceChildren()
})

const keptInputs = (host: HTMLElement) => host.querySelectorAll(':scope > [data-list-inputs]')

test('closed_lazy_menu_loads_on_open', async () => {
  const m = buildMenu()
  m.loader.sync()
  await flush()
  expect(gate.count('/items')).toBe(0)

  m.loader.sync(true)
  await gate.started('/items')
  expect(m.spies.onLoadStart).toHaveBeenCalledWith(expect.anything(), true)
})

test('preloaded_menu_loads_on_sync', async () => {
  const m = buildMenu({preload: true})
  m.loader.sync()
  await gate.started('/items')
  expect(gate.count('/items')).toBe(1)
})

test('same_src_does_nothing_after_load', async () => {
  const m = buildMenu()
  m.loader.sync(true)
  await gate.started('/items')
  gate.release('/items', {body: items('A')})
  await flush()

  m.setSrc('/items')
  m.loader.sync(true)
  await flush()
  expect(gate.count('/items')).toBe(1)
  expect(m.body().textContent).toContain('A')
})

test('src_away_and_back_on_closed_menu_keeps_completed_request', async () => {
  const m = buildMenu({src: '/items?l=A'})
  m.loader.sync(true)
  await gate.started('/items?l=A')
  gate.release('/items?l=A', {body: items('A')})
  await flush()

  m.setSrc('/items?l=B')
  m.setSrc('/items?l=A')
  m.loader.sync(true)
  await flush()
  expect(gate.count('/items?l=A')).toBe(1)
  expect(gate.count('/items?l=B')).toBe(0)
})

test('failed_load_retries_on_open', async () => {
  const m = buildMenu()
  m.loader.sync(true)
  await gate.started('/items')
  gate.release('/items', {status: 500})
  await flush()

  m.loader.sync(true)
  await gate.started('/items', 2)
})

test('rewritten_failed_loader_loads_host_src_and_rejects_its_response', async () => {
  const m = buildMenu()
  m.loader.sync(true)
  await gate.started('/items')
  gate.release('/items', {status: 500})
  await flush()

  // a morph rewrites the failed loader's src; upstream fetches it at once
  m.body().querySelector('include-fragment')!.setAttribute('src', '/items?l=X')
  await gate.started('/items?l=X')
  gate.release('/items?l=X', {body: items('X')})
  await flush()
  expect(m.body().textContent).not.toContain('X')

  m.loader.sync(true)
  await gate.started('/items', 2)
})

test('superseded_response_is_ignored', async () => {
  const m = buildMenu({open: true})
  m.setSrc('/items?l=A')
  await gate.started('/items?l=A')
  m.setSrc('/items?l=B')
  await gate.started('/items?l=B')

  gate.release('/items?l=A', {body: items('A')})
  await flush()
  gate.release('/items?l=B', {body: items('B')})
  await flush()
  expect(m.body().textContent).toContain('B')
  expect(m.body().textContent).not.toContain('A')
  expect(m.spies.onLoaded).toHaveBeenCalledTimes(1)
})

test('completion_does_not_mark_newer_request_ready', async () => {
  const m = buildMenu({open: true})
  m.setSrc('/items?l=A')
  await gate.started('/items?l=A')
  m.spies.onLoaded.mockImplementationOnce(() => m.setSrc('/items?l=C'))

  gate.release('/items?l=A', {body: items('A')})
  await flush()
  expect(gate.count('/items?l=C')).toBe(1)
  expect(m.host.hasAttribute('data-ready')).toBe(false)
})

test('completion_stops_when_onLoaded_starts_a_newer_load', async () => {
  const m = buildMenu({open: true})
  m.body().innerHTML = inputs('a', '1') + items('Old')
  m.setSrc('/items?l=A')
  await gate.started('/items?l=A')
  m.spies.onLoaded.mockImplementationOnce(() => m.setSrc('/items?l=B'))

  gate.release('/items?l=A', {body: inputs('a', '2') + items('A')})
  await flush()
  // B is pending: A's inputs are kept on the host, and the menu is not ready
  expect(keptInputs(m.host)).toHaveLength(1)
  expect(m.host.querySelector<HTMLInputElement>(':scope > [data-list-inputs] input')!.value).toBe('2')
  expect(m.host.hasAttribute('data-ready')).toBe(false)

  await gate.started('/items?l=B')
  gate.release('/items?l=B', {body: inputs('b', '3') + items('B')})
  await flush()
  expect(keptInputs(m.host)).toHaveLength(0)
  expect(m.body().querySelector('input')!.getAttribute('name')).toBe('b')
  expect(m.host.getAttribute('data-ready')).toBe('true')
})

test('load_stops_when_onLoadStart_starts_a_newer_load', async () => {
  const m = buildMenu({open: true})
  m.spies.onLoadStart.mockImplementationOnce(() => m.setSrc('/items?l=B'))

  m.setSrc('/items?l=A')
  await gate.started('/items?l=B')
  const loaders = m.body().querySelectorAll('include-fragment')
  expect(loaders).toHaveLength(1)
  expect(loaders[0].getAttribute('src')).toBe('/items?l=B')
  expect(gate.count('/items?l=B')).toBe(1)
})

test('completion_drops_kept_inputs_before_onLoaded', async () => {
  const m = buildMenu({open: true})
  m.body().innerHTML = inputs('a', '1') + items('Old')
  m.setSrc('/items?l=A')
  await gate.started('/items?l=A')
  expect(keptInputs(m.host)).toHaveLength(1)

  let keptDuringOnLoaded = -1
  m.spies.onLoaded.mockImplementationOnce(() => {
    keptDuringOnLoaded = keptInputs(m.host).length
  })
  gate.release('/items?l=A', {body: inputs('a', '2') + items('A')})
  await flush()
  expect(keptDuringOnLoaded).toBe(0)
})

test('kept_inputs_survive_failure', async () => {
  const m = buildMenu({open: true})
  m.body().innerHTML = inputs('a', '1') + items('Old')
  m.setSrc('/items?l=A')
  await gate.started('/items?l=A')

  gate.release('/items?l=A', {status: 500})
  await flush()
  expect(keptInputs(m.host)).toHaveLength(1)
  expect(m.host.querySelector<HTMLInputElement>(':scope > [data-list-inputs] input')!.value).toBe('1')
})

test('empty_response_is_discarded_and_waits_for_open', async () => {
  const m = buildMenu({preload: true})
  m.loader.sync()
  await gate.started('/items')
  gate.release('/items', {body: '<ul></ul>'})
  await flush()
  expect(m.body().childElementCount).toBe(0)

  // an unrelated mutation outside the body
  m.host.append(document.createElement('span'))
  await flush()
  expect(gate.count('/items')).toBe(1)

  m.loader.sync(true)
  await gate.started('/items', 2)
})

test('replaced_body_after_empty_response_reloads_preloaded_menu', async () => {
  const m = buildMenu({preload: true})
  m.loader.sync()
  await gate.started('/items')
  gate.release('/items', {body: '<ul></ul>'})
  await flush()

  m.body().replaceWith(m.body().cloneNode(false))
  await gate.started('/items', 2)
})

test('emptied_body_reloads_pending_loader_at_once_when_open', async () => {
  const m = buildMenu({open: true})
  m.setSrc('/items?l=A')
  await gate.started('/items?l=A')

  m.body().replaceChildren()
  await gate.started('/items?l=A', 2)
})

test('adopts_last_inserted_fragment_and_reflects_src', async () => {
  const m = buildMenu()
  const x = document.createElement('include-fragment')
  x.setAttribute('src', '/items?l=X')
  x.setAttribute('loading', 'lazy')
  const y = document.createElement('include-fragment')
  y.setAttribute('src', '/items?l=Y')
  y.setAttribute('loading', 'lazy')

  m.body().append(x, y)
  await flush()
  expect(m.host.getAttribute('src')).toBe('/items?l=Y')
  expect(Array.from(m.body().children)).toEqual([y])
})

test('response_sub_menu_fragment_is_not_adopted', async () => {
  const m = buildMenu({open: true})
  m.setSrc('/items?l=A')
  await gate.started('/items?l=A')

  gate.release('/items?l=A', {
    body: '<ul><li><button role="menuitem">A</button><include-fragment src="/sub"></include-fragment></li></ul>',
  })
  await flush()
  expect(m.host.getAttribute('src')).toBe('/items?l=A')
})

test('completes_while_host_is_detached', async () => {
  const m = buildMenu()
  m.loader.sync(true)
  await gate.started('/items')

  m.host.remove()
  gate.release('/items', {body: items('A')})
  await flush()
  expect(m.spies.onLoaded).toHaveBeenCalledTimes(1)
  expect(m.host.getAttribute('data-ready')).toBe('true')
})
