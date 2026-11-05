import {afterEach, beforeEach, expect, test} from 'vitest'
import '@github/include-fragment-element'
import {createFetchGate, flush, type FetchGate} from './fetch_gate'

let gate: FetchGate

beforeEach(() => {
  gate = createFetchGate()
  gate.install()
})

afterEach(() => {
  gate.restore()
  document.body.replaceChildren()
})

test('include_fragment_is_defined', () => {
  expect(customElements.get('include-fragment')).toBeTruthy()
})

test('holds_and_releases_a_request', async () => {
  const fragment = document.createElement('include-fragment')
  fragment.setAttribute('src', '/items?x=1')
  document.body.append(fragment)

  await gate.started('/items?x=1')
  expect(gate.count('/items?x=1')).toBe(1)

  // eslint-disable-next-line github/unescaped-html-literal -- static fixture markup
  gate.release('/items?x=1', {body: '<p id="r">ok</p>'})
  await flush()
  expect(document.getElementById('r')).not.toBeNull()
})

test('failed_release_sets_is_error', async () => {
  const fragment = document.createElement('include-fragment')
  fragment.setAttribute('src', '/items?x=2')
  document.body.append(fragment)

  await gate.started('/items?x=2')
  gate.release('/items?x=2', {status: 500})
  await flush()
  expect(fragment.classList.contains('is-error')).toBe(true)
})
