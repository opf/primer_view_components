# frozen_string_literal: true

module Primer
  module OpenProject
    # OpenProject-specific Avatar component that extends Primer::Beta::Avatar
    # to support fallback rendering with initials when no image source is provided.
    #
    # When `src` is nil, this component renders a minimal SVG placeholder that is
    # enhanced client-side by the AvatarFallbackElement web component to display
    # initials with a consistent color based on the user's unique_id.
    #
    # This component follows the "extension over mutation" pattern - it extends
    # Primer::Beta::Avatar without modifying its interface, ensuring compatibility
    # with upstream changes.
    class AvatarWithFallback < Primer::Beta::Avatar
      # @see
      #   - https://primer.style/foundations/typography/
      #   - https://github.com/primer/css/blob/main/src/support/variables/typography.scss
      FONT_STACK = "-apple-system, BlinkMacSystemFont, 'Segoe UI', 'Noto Sans', Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji'"

      # @param src [String] The source url of the avatar image. When nil, renders a fallback with initials.
      # @param alt [String] Alt text for the avatar. Used for accessibility and to generate initials when src is nil.
      # @param size [Integer] <%= one_of(Primer::Beta::Avatar::SIZE_OPTIONS) %>
      # @param shape [Symbol] Shape of the avatar. <%= one_of(Primer::Beta::Avatar::SHAPE_OPTIONS) %>
      # @param href [String] The URL to link to. If used, component will be wrapped by an `<a>` tag.
      # @param unique_id [String, Integer] Unique identifier for generating consistent avatar colors across renders.
      # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
      def initialize(src: nil, alt: nil, size: DEFAULT_SIZE, shape: DEFAULT_SHAPE, href: nil, unique_id: nil, **system_arguments)
        @unique_id = unique_id
        @src = src

        if src.present?
          super(src: src, alt: alt, size: size, shape: shape, href: href, **system_arguments)
        else
          @alt = alt
          @href = href
          @size = fetch_or_fallback(SIZE_OPTIONS, size, DEFAULT_SIZE)
          @shape = fetch_or_fallback(SHAPE_OPTIONS, shape, DEFAULT_SHAPE)
          @system_arguments = deny_tag_argument(**system_arguments)

          validate_src_or_alt(nil, alt)
        end
      end

      def call
        if @src.present?
          super
        else
          render_fallback
        end
      end

      private

      def validate_src_or_alt(src, alt)
        return if src.present? || alt.present?

        raise ArgumentError, "`src` or `alt` is required"
      end

      def fallback_font_size
        # Calculate font size for initials (45% of avatar size, min 8px)
        [(@size * 0.45).round, 8].max
      end

      def fallback_avatar_classes
        class_names(
          @system_arguments[:classes],
          "avatar",
          "avatar-#{@size}",
          "avatar-small" => @size < SMALL_THRESHOLD,
          "circle" => @shape == DEFAULT_SHAPE
        )
      end

      def render_fallback
        svg_content = content_tag(
          :svg,
          safe_join([
            tag.rect(width: "100%", height: "100%", fill: "currentColor"),
            content_tag(
              :text,
              nil,
              x: "50%",
              y: "50%",
              "text-anchor": "middle",
              "dominant-baseline": "central",
              fill: "white",
              "font-size": fallback_font_size,
              "font-weight": "600",
              "font-family": FONT_STACK,
              style: "user-select: none; text-transform: uppercase;"
            )
          ]),
          width: @size,
          height: @size,
          viewBox: "0 0 #{@size} #{@size}",
          role: "img",
          "aria-label": @alt,
          class: fallback_avatar_classes
        )

        render(Primer::BaseComponent.new(
          tag: :"avatar-fallback",
          data: {
            unique_id: @unique_id,
            alt_text: @alt
          }
        )) do
          render(Primer::ConditionalWrapper.new(
            condition: @href.present?,
            component: Primer::Beta::Link,
            **(@href.present? ? { href: @href } : {})
          )) { svg_content }
        end
      end
    end
  end
end
