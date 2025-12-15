import {attr, controller} from '@github/catalyst'

@controller
export class AvatarFallbackElement extends HTMLElement {
  @attr uniqueId = ''
  @attr altText = ''

  connectedCallback() {
    if (!this.uniqueId || !this.altText) return

    const fallbackSvg = this.querySelector('svg[role="img"]')
    if (!fallbackSvg) return

    // Generate consistent color based on uniqueId and altText (hash must match OP Core)
    const text = `${this.uniqueId}${this.altText}`
    const hue = this.valueHash(text)
    const color = `hsl(${hue}, 50%, 30%)`

    // Set background color on rect element
    const rectElement = fallbackSvg.querySelector('rect')
    if (rectElement) {
      rectElement.setAttribute('fill', color)
    }
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
