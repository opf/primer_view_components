import {controller} from '@github/catalyst'

type SortDirection = 'ASC' | 'DESC' | 'NONE'
type AriaSortDirection = 'ascending' | 'descending'
type SortStrategy = 'basic' | 'datetime' | 'alphanumeric'
type SortValue = string | number

const SortDirection = {
  ASC: 'ASC',
  DESC: 'DESC',
  NONE: 'NONE',
} as const

const DEFAULT_SORT_DIRECTION = SortDirection.ASC

@controller('data-table')
export class DataTableElement extends HTMLElement {
  connectedCallback() {
    if (this.externalSorting) return

    sortTableByAriaSort(this.table)
    updateSortIcons(this.table)
  }

  toggleSort(event: MouseEvent) {
    if (this.externalSorting) return

    const header = (event.target as Element).closest('th')!
    const direction = getSortDirection(header)
    const nextDirection =
      direction === SortDirection.NONE
        ? DEFAULT_SORT_DIRECTION
        : transition(direction as Exclude<SortDirection, 'NONE'>)

    setSortDirection(header, nextDirection)

    const siblings = Array.from(header.parentElement!.children).filter(
      (el): el is HTMLElement => el !== header && el instanceof HTMLElement,
    )

    for (const sibling of siblings) {
      resetSort(sibling)
    }

    sortTableByAriaSort(this.table)
    updateSortIcons(this.table)
  }

  get table(): HTMLTableElement {
    return this.querySelector('table')!
  }

  get externalSorting(): boolean {
    return this.hasAttribute('data-external-sorting')
  }
}

function resetSort(th: HTMLElement) {
  th.removeAttribute('aria-sort')
}

function transition(direction: Exclude<SortDirection, 'NONE'>): Exclude<SortDirection, 'NONE'> {
  if (direction === SortDirection.ASC) {
    return SortDirection.DESC
  }
  return SortDirection.ASC
}

function getSortDirection(header: Element): SortDirection {
  const ariaSort = header.getAttribute('aria-sort')

  if (ariaSort === 'ascending') {
    return SortDirection.ASC
  }

  if (ariaSort === 'descending') {
    return SortDirection.DESC
  }

  return SortDirection.NONE
}

function setSortDirection(header: Element, direction: Exclude<SortDirection, 'NONE'>) {
  header.setAttribute('aria-sort', direction === SortDirection.ASC ? 'ascending' : 'descending')
}

function sortTableByAriaSort(table: HTMLTableElement) {
  const headers = Array.from(table.querySelectorAll<HTMLElement>('thead th'))
  const tbody = table.querySelector('tbody')!

  const sortedHeader = headers.find(
    th => th.getAttribute('aria-sort') === 'ascending' || th.getAttribute('aria-sort') === 'descending',
  )

  if (!sortedHeader) return

  const columnIndex = headers.indexOf(sortedHeader)
  const direction = sortedHeader.getAttribute('aria-sort')
  const strategy = getSortStrategy(sortedHeader)

  const rows = Array.from(tbody.querySelectorAll('tr'))

  const sortedRows = rows
    .map((row, index) => ({row, index}))
    .sort((a, b) => {
      const result = compareRows(a.row, b.row, columnIndex, strategy, direction as AriaSortDirection)
      return result === 0 ? a.index - b.index : result
    })
    .map(({row}) => row)

  tbody.append(...sortedRows)
}

function compareRows(
  rowA: HTMLTableRowElement,
  rowB: HTMLTableRowElement,
  columnIndex: number,
  strategy: SortStrategy,
  direction: AriaSortDirection,
) {
  const cellA = rowA.children[columnIndex] as HTMLElement | undefined
  const cellB = rowB.children[columnIndex] as HTMLElement | undefined
  const valueAIsBlank = isBlankSortValue(cellA)
  const valueBIsBlank = isBlankSortValue(cellB)

  if (!valueAIsBlank && !valueBIsBlank) {
    const result = compareValues(getSortValue(cellA), getSortValue(cellB), strategy)
    return direction === 'ascending' ? result : -result
  }

  if (!valueAIsBlank) {
    return -1
  }

  if (!valueBIsBlank) {
    return 1
  }

  return 0
}

function getSortStrategy(header: HTMLElement): SortStrategy {
  const strategy = header.getAttribute('data-sort-strategy')

  if (strategy === 'datetime' || strategy === 'alphanumeric') {
    return strategy
  }

  return 'basic'
}

function isBlankSortValue(cell: HTMLElement | undefined): boolean {
  if (!cell) {
    return true
  }

  return cell.getAttribute('data-sort-blank') === 'true'
}

function getSortValue(cell: HTMLElement | undefined): SortValue {
  if (!cell) {
    return ''
  }

  const value = cell.getAttribute('data-sort-value') ?? ''

  if (cell.getAttribute('data-sort-type') === 'number') {
    return Number(value)
  }

  return value
}

function compareValues(valueA: SortValue, valueB: SortValue, strategy: SortStrategy) {
  if (strategy === 'alphanumeric') {
    return alphanumeric(String(valueA), String(valueB))
  }

  if (valueA === valueB) {
    return 0
  }

  return valueA < valueB ? -1 : 1
}

function alphanumeric(inputA: string, inputB: string): number {
  const groupsA = getAlphaNumericGroups(inputA)
  const groupsB = getAlphaNumericGroups(inputB)

  while (groupsA.length !== 0 && groupsB.length !== 0) {
    const a = groupsA.shift()
    const b = groupsB.shift()

    if (a === b) {
      continue
    } else if (typeof a === 'string' && typeof b === 'string') {
      return a.localeCompare(b)
    } else if (typeof a === 'number' && typeof b === 'number') {
      return a > b ? 1 : -1
    } else if (typeof a === 'number' && typeof b === 'string') {
      return -1
    } else if (typeof a === 'string' && typeof b === 'number') {
      return 1
    } else if (a === undefined || b === undefined) {
      break
    }
  }

  if (groupsA.length === groupsB.length) {
    return 0
  }

  return groupsA.length > groupsB.length ? 1 : -1
}

function getAlphaNumericGroups(input: string): Array<string | number> {
  const groups: Array<string | number> = []
  let i = 0

  while (i < input.length) {
    let group = input[i]

    if (isNumeric(group)) {
      while (i + 1 < input.length && isNumeric(input[i + 1])) {
        group = group + input[i + 1]
        i++
      }
      groups.push(parseInt(group, 10))
    } else {
      while (i + 1 < input.length && !isNumeric(input[i + 1])) {
        group = group + input[i + 1]
        i++
      }
      groups.push(group)
    }

    i++
  }

  return groups
}

function isNumeric(value: string): boolean {
  return !Number.isNaN(parseInt(value, 10))
}

function updateSortIcons(table: HTMLTableElement) {
  for (const header of Array.from(table.querySelectorAll<HTMLElement>('thead th'))) {
    const direction = getSortDirection(header)
    const ascendingIcon = header.querySelector('.TableSortIcon--ascending')
    const descendingIcon = header.querySelector('.TableSortIcon--descending')

    ascendingIcon?.classList.toggle('d-none', direction === SortDirection.DESC)
    descendingIcon?.classList.toggle('d-none', direction !== SortDirection.DESC)
  }
}

declare global {
  interface Window {
    DataTableElement: typeof DataTableElement
  }
}
