import { attr, controller } from '@github/catalyst'

@controller
export class AvatarFallbackElement extends HTMLElement {
  @attr uniqueId = ''
  @attr altText = ''

  connectedCallback() {
    // Only update color if we have the necessary data and an SVG fallback
    if (!this.uniqueId || !this.altText) return

    const img = this.querySelector('img[src^="data:image/svg+xml"]')
    if (!img) return

    // Calculate correct color using OP Core hash algorithm
    const text = `${this.uniqueId}${this.altText}`
    const hue = this.valueHash(text)
    const color = `hsl(${hue}, 50%, 30%)`

    // Update SVG with correct color
    this.updateSvgColor(img as HTMLImageElement, color)
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
    // Decode current SVG
    const dataUri = img.src
    const base64 = dataUri.replace('data:image/svg+xml;base64,', '')
    const svg = atob(base64)

    // Replace fill color in rect element
    const updatedSvg = svg.replace(/fill="hsl\([^"]+\)"/, `fill="${color}"`)

    // Encode and update
    img.src = `data:image/svg+xml;base64,${btoa(updatedSvg)}`
  }
}

declare global {
  interface Window {
    AvatarFallbackElement: typeof AvatarFallbackElement
  }
}

if (!window.customElements.get('avatar-fallback')) {
  window.AvatarFallbackElement = AvatarFallbackElement
  window.customElements.define('avatar-fallback', AvatarFallbackElement)
}
