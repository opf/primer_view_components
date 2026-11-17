import {test, expect} from '@playwright/test'
import type {Page} from '@playwright/test'

const computedStyleOf = (page: Page, label: string, property: string): Promise<string> =>
  page.evaluate(
    ({wanted, prop}) => {
      const item = [...document.querySelectorAll('.ActionListItem--divided')].find(
        el => el.querySelector('.ActionListItem-label')?.textContent?.trim() === wanted,
      )
      if (!item) throw new Error(`no item with a divider labelled "${wanted}"`)
      return getComputedStyle(item).getPropertyValue(prop).trim()
    },
    {wanted: label, prop: property},
  )

/**
 * `ActionListItem--divided` resolves `--actionListItem-dividerVisibility` per item, and the
 * `::before` of its content paints the line with it. These tests read that variable rather than
 * the selectors that set it, so the rules can be rewritten without rewriting the tests.
 */
const lineOn = (page: Page, label: string) => computedStyleOf(page, label, '--actionListItem-dividerVisibility')

const backgroundOf = (page: Page, label: string) => computedStyleOf(page, label, 'background-color')

const contentOf = (page: Page, label: string) =>
  page.locator('.ActionListItem--divided', {hasText: label}).first().locator('.ActionListContent')

const hoverItem = (page: Page, label: string) => contentOf(page, label).hover()

test.describe('ActionList dividers', () => {
  test.beforeEach(async ({page}) => {
    await page.goto('/rails/view_components/primer/alpha/action_list/with_dividers')
  })

  test('the first visible item has no line, so a list never opens with a rule above it', async ({page}) => {
    expect(await lineOn(page, 'First visible item')).toBe('hidden')
  })

  test('every item after the first has a line', async ({page}) => {
    expect(await lineOn(page, 'Leading visual')).toBe('visible')
  })

  test('a hidden item does not leave the line of the item after it behind', async ({page}) => {
    expect(await lineOn(page, 'After a hidden item')).toBe('visible')
  })

  test('an item after a manual divider has no line, so the two never double up', async ({page}) => {
    expect(await lineOn(page, 'After a divider')).toBe('hidden')
  })

  test('hovering an item clears the line on both of its edges', async ({page}) => {
    await hoverItem(page, 'Leading visual')

    expect(await lineOn(page, 'Leading visual')).toBe('hidden')
    expect(await lineOn(page, 'Trailing visual')).toBe('hidden')
  })

  test('hovering leaves the lines of items further down alone', async ({page}) => {
    await hoverItem(page, 'Leading visual')

    expect(await lineOn(page, 'Inline description')).toBe('visible')
  })

  test('a disabled item is highlighted on hover like any other, so it loses its line too', async ({page}) => {
    const atRest = await backgroundOf(page, 'Disabled item')
    await hoverItem(page, 'Disabled item')

    // The premise: ActionList does not hold the highlight back for disabled items. Should it
    // ever start to, this item would have to keep its line again.
    expect(await backgroundOf(page, 'Disabled item')).not.toBe(atRest)
    expect(await lineOn(page, 'Disabled item')).toBe('hidden')
  })

  test('a disabled item takes focus and draws a ring, so it loses its line then as well', async ({page}) => {
    await contentOf(page, 'Disabled item').focus()

    expect(await lineOn(page, 'Disabled item')).toBe('hidden')
  })

  test('a divider after a hidden item is collapsed, so the item below it keeps its line', async ({page}) => {
    // The divider itself drops out (.ActionListItem[hidden] + .ActionList-sectionDivider), so
    // without the line nothing at all would separate this item from the one above it.
    const divider = page.locator('.ActionList-sectionDivider').last()
    expect(await divider.evaluate(el => getComputedStyle(el).display)).toBe('none')

    expect(await lineOn(page, 'After a collapsed divider')).toBe('visible')
  })

  test.describe('without hover', () => {
    // A coarse pointer never matches `(hover: hover)`, so this reads the `:active` rule alone.
    test.use({hasTouch: true, isMobile: true})

    test('pressing an item clears the line on both of its edges', async ({page}) => {
      // The premise: were hover still available, the hover rule alone would clear these lines.
      expect(await page.evaluate(() => matchMedia('(hover: hover)').matches)).toBe(false)

      const box = (await contentOf(page, 'Leading visual').boundingBox())!
      await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2)
      expect(await lineOn(page, 'Leading visual')).toBe('visible')

      await page.mouse.down()

      expect(await lineOn(page, 'Leading visual')).toBe('hidden')
      expect(await lineOn(page, 'Trailing visual')).toBe('hidden')
      expect(await lineOn(page, 'Inline description')).toBe('visible')
    })
  })
})
