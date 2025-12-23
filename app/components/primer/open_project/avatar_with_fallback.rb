# frozen_string_literal: true

module Primer
  module OpenProject
    # OpenProject-specific Avatar component that extends Primer::Beta::Avatar
    # to support fallback rendering with initials when no image source is provided.
    #
    # When `src` is nil, this component renders an SVG with initials extracted from
    # the alt text. The AvatarFallbackElement web component then enhances it client-side
    # by applying a consistent background color based on the user's unique_id (using the
    # same hash function as OP Core for consistency).
    #
    # This component follows the "extension over mutation" pattern - it extends
    # Primer::Beta::Avatar without modifying its interface, ensuring compatibility
    # with upstream changes.
    class AvatarWithFallback < Primer::Beta::Avatar
      status :open_project

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
        require_src_or_alt_arguments(src, alt)

        @unique_id = unique_id
        @use_fallback = src.blank?
        final_src = @use_fallback ? generate_fallback_svg(alt, size) : src

        super(src: final_src, alt: alt, size: size, shape: shape, href: href, **system_arguments)
      end

      def call
        render(
          Primer::ConditionalWrapper.new(
            condition: @use_fallback,
            tag: :"avatar-fallback",
            data: {
              unique_id: @unique_id,
              alt_text: @system_arguments[:alt]
            }
          )
        ) { super }
      end

      private

      def require_src_or_alt_arguments(src, alt)
        return if src.present? || alt.present?

        raise ArgumentError, "`src` or `alt` is required"
      end

      def generate_fallback_svg(alt, size)
        svg_content = content_tag(
          :svg,
          safe_join([
            # Use a neutral dark gray as default to minimize flicker in both light/dark modes
            # JS will replace with the hashed color (hsl(hue, 50%, 30%))
            tag.rect(width: "100%", height: "100%", fill: "hsl(0, 0%, 35%)"),
            content_tag(
              :text,
              extract_initials(alt),
              x: "50%",
              y: "50%",
              "text-anchor": "middle",
              "dominant-baseline": "central",
              fill: "white",
              "font-size": fallback_font_size(size),
              "font-weight": "600",
              "font-family": FONT_STACK,
              style: "user-select: none; text-transform: uppercase;"
            )
          ]),
          xmlns: "http://www.w3.org/2000/svg",
          width: size,
          height: size,
          viewBox: "0 0 #{size} #{size}",
        )

        "data:image/svg+xml;base64,#{Base64.strict_encode64(svg_content)}"
      end

      def extract_initials(name)
        return "" if name.blank?

        chars = name.chars
        first = chars[0]&.upcase || ""

        last_space = name.rindex(" ")
        if last_space && last_space < name.length - 1
          last = name[last_space + 1]&.upcase || ""
          "#{first}#{last}"
        else
          first
        end
      end

      def fallback_font_size(size)
        # Font size is 45% of avatar size for good readability, with a minimum of 8px
        [(size * 0.45).round, 8].max
      end
    end
  end
end
