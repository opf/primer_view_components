import {attr, controller} from '@github/catalyst'

@controller
export class AvatarFallbackElement extends HTMLElement {
  @attr uniqueId = ''
  @attr altText = ''

  connectedCallback() {
    // If either uniqueId or altText is missing, skip color customization so the SVG
    // keeps its default gray fill defined in the source and no color override is applied.
    if (!this.uniqueId || !this.altText) return

    const img = this.querySelector<HTMLImageElement>('img[src^="data:image/svg+xml"]')
    if (!img) return

    // Generate consistent color based on uniqueId and altText (hash must match OP Core)
    const text = `${this.uniqueId}${this.altText}`
    const hue = this.valueHash(text)
    const color = `hsl(${hue}, 50%, 30%)`

    this.updateSvgColor(img, color)
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

  private updateSvgColor(img: HTMLImageElement, color: string) {
    const dataUri = img.src
    const base64 = dataUri.replace('data:image/svg+xml;base64,', '')

    try {
      const svg = atob(base64)
      const updatedSvg = svg.replace(/fill="hsl\([^"]+\)"/, `fill="${color}"`)
      img.src = `data:image/svg+xml;base64,${btoa(updatedSvg)}`
    } catch {
      // If the SVG data is malformed or not valid base64, skip updating the color
      // to avoid breaking the component.
    }
  }
}
