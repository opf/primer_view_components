import { attr, controller } from '@github/catalyst'

@controller
export class AvatarFallbackElement extends HTMLElement {
  @attr uniqueId = ''
  @attr altText = ''

  connectedCallback() {
    if (!this.uniqueId || !this.altText) {
      console.warn('AvatarFallbackElement: uniqueId and altText attributes are required for proper fallback rendering')
      return
    }

    const fallbackSvg = this.querySelector('svg[role="img"]')
    if (!fallbackSvg) return

    // Extract initials from alt text
    const initials = this.extractInitials(this.altText)

    // Generate consistent color based on uniqueId and altText (hash must match OP Core)
    const text = `${this.uniqueId}${this.altText}`
    const hue = this.valueHash(text)
    const color = `hsl(${hue}, 50%, 30%)`

    // Set background color on rect element and initials on text element
    const rectElement = fallbackSvg.querySelector('rect')
    const textElement = fallbackSvg.querySelector('text')

    if (rectElement) {
      rectElement.setAttribute('fill', color)
    }

    if (textElement) {
      textElement.textContent = initials
    }
  }

  /*
   * Extracts initials from a name string (first letter + last letter of last word)
   * @param name - The name to extract initials from
   * @returns The initials (1-2 characters)
   */
  private extractInitials(name: string): string {
    if (!name) return ''

    const trimmed = name.trim()
    if (!trimmed) return ''

    const first = trimmed.charAt(0).toUpperCase()

    const lastSpace = trimmed.lastIndexOf(' ')
    if (lastSpace > 0 && lastSpace < trimmed.length - 1) {
      const last = trimmed.charAt(lastSpace + 1).toUpperCase()
      return `${first}${last}`
    }

    return first
  }

  /*
   * Mimics OP Core's string hash function to ensure consistent color generation
   * @see https://github.com/opf/openproject/blob/1b6eb3f9e45c3bdb05ce49d2cbe92995b87b4df5/frontend/src/app/shared/components/colors/colors.service.ts#L19-L26
   */
  private valueHash(value: string): number {
    let hash = 0
    for (let i = 0; i < value.length; i++) {
      hash = value.charCodeAt(i) + ((hash << 5) - hash)
    }
    return hash % 360
  }
}

// Custom element registration is handled automatically by the @controller decorator
