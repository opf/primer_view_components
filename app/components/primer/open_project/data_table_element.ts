import {controller} from '@github/catalyst'

@controller
export class DataTableElement extends HTMLElement {
  constructor() {
    super()
  }

  connectedCallback() {
    sortTableByAriaSort(this.table)
  }

  toggleSort(event: MouseEvent) {
    const header = (event.target as Element).closest('th')!
    const ariaSort = header.getAttribute('aria-sort')
    const sortAscendingIcon = header.querySelector('.TableSortIcon--ascending')
    const sortDescendingIcon = header.querySelector('.TableSortIcon--descending')

    if (ariaSort === 'descending') {
      header.setAttribute('aria-sort', 'ascending')
      sortAscendingIcon?.classList.remove('d-none')
      sortDescendingIcon?.classList.add('d-none')
    } else {
      header.setAttribute('aria-sort', 'descending')
      sortDescendingIcon?.classList.remove('d-none')
      sortAscendingIcon?.classList.add('d-none')
    }

    const siblings = Array.from(header.parentElement!.children).filter(
      (el): el is HTMLElement => el !== header && el instanceof HTMLElement,
    )

    for (const sibling of siblings) {
      resetSort(sibling)
    }

    sortTableByAriaSort(this.table)
  }

  get table(): HTMLTableElement {
    return this.querySelector('table')!
  }
}

function resetSort(th: HTMLElement) {
  th.removeAttribute('aria-sort')
  const sortAscendingIcon = th.querySelector('.TableSortIcon--ascending')
  const sortDescendingIcon = th.querySelector('.TableSortIcon--descending')
  sortAscendingIcon?.classList.remove('d-none')
  sortDescendingIcon?.classList.add('d-none')
}

function sortTableByAriaSort(table: HTMLTableElement) {
  const headers = Array.from(table.querySelectorAll('thead th'))
  const tbody = table.querySelector('tbody')!

  const sortedHeader = headers.find(
    th => th.getAttribute('aria-sort') === 'ascending' || th.getAttribute('aria-sort') === 'descending',
  )

  if (!sortedHeader) return

  const columnIndex = headers.indexOf(sortedHeader)
  const direction = sortedHeader.getAttribute('aria-sort')

  const rows = Array.from(tbody.querySelectorAll('tr'))

  const sortedRows = rows.sort((a, b) => {
    const aText = a.children[columnIndex].textContent?.trim() ?? ''
    const bText = b.children[columnIndex].textContent?.trim() ?? ''

    const aNum = parseFloat(aText)
    const bNum = parseFloat(bText)

    const valueA = isNaN(aNum) ? aText : aNum
    const valueB = isNaN(bNum) ? bText : bNum

    if (valueA < valueB) return direction === 'ascending' ? -1 : 1
    if (valueA > valueB) return direction === 'ascending' ? 1 : -1
    return 0
  })

  tbody.append(...sortedRows)
}

declare global {
  interface Window {
    DataTableElement: typeof DataTableElement
  }
}
