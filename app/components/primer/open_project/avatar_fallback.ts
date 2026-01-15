import {controller} from '@github/catalyst'

/**
 * AvatarFallbackElement implements "fallback first" loading pattern:
 * 1. Fallback SVG is rendered immediately as <img> src
 * 2. Real avatar URL is test-loaded in background using new Image()
 * 3. On success, swaps to real image; on failure, fallback stays visible
 *
 * This approach prevents flicker by never showing a broken image state.
 * Inspired by OpenProject's Angular PrincipalRendererService.
 *
 * Note: We read attributes directly via getAttribute() instead of using @attr
 * due to a Catalyst bug where @attr accessors aren't properly initialized
 * when elements have pre-existing attribute values.
 */
@controller
export class AvatarFallbackElement extends HTMLElement {
  private img: HTMLImageElement | null = null
  private testImage: HTMLImageElement | null = null

  connectedCallback() {
    this.img = this.querySelector<HTMLImageElement>('img') ?? null
    if (!this.img) return

    const uniqueId = this.getAttribute('data-unique-id') || ''
    const altText = this.getAttribute('data-alt-text') || ''
    const avatarSrc = this.getAttribute('data-avatar-src') || ''

    // Apply hashed color to fallback SVG immediately
    this.applyColor(this.img, uniqueId, altText)

    // Test-load real avatar URL in background
    if (avatarSrc) {
      this.testLoadImage(avatarSrc)
    }
  }

  disconnectedCallback() {
    // Clean up test image and its event handler to prevent memory leaks
    if (this.testImage) {
      this.testImage.onload = null
      this.testImage = null
    }
    this.img = null
  }

  /**
   * Test-loads the real avatar URL in background.
   * On success, swaps the visible img to the real URL.
   * On failure, does nothing - fallback stays visible.
   */
  private testLoadImage(url: string) {
    this.testImage = new Image()

    this.testImage.onload = () => {
      // Success - swap to real image
      if (this.img) {
        this.img.src = url
      }
    }

    // On error: do nothing, fallback stays visible (no flicker)
    this.testImage.src = url
  }

  private applyColor(img: HTMLImageElement, uniqueId: string, altText: string) {
    // If either uniqueId or altText is missing, skip color customization so the SVG
    // keeps its default gray fill defined in the source and no color override is applied.
    if (!uniqueId || !altText) return

    const text = `${uniqueId}${altText}`
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
    if (!dataUri.startsWith('data:image/svg+xml;base64,')) return

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
