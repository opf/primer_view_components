# frozen_string_literal: true

module Primer
  module Beta
    # `Avatar` can be used to represent users and organizations on GitHub.
    #
    # - Use the default circle avatar for users, and the square shape
    # for organizations or any other non-human avatars.
    # - By default, `Avatar` will render a static `<img>`. To have `Avatar` function as a link, set the `href` which will wrap the `<img>` in a `<a>`.
    # - Set `size` to update the height and width of the `Avatar` in pixels.
    # - To stack multiple avatars together, use <%= link_to_component(Primer::Beta::AvatarStack) %>.
    #
    # @accessibility
    #   Images should have text alternatives that describe the information or function represented.
    #   If the avatar functions as a link, provide alt text that helps convey the function. For instance,
    #   if `Avatar` is a link to a user profile, the alt attribute should be `@kittenuser profile`
    #   rather than `@kittenuser`.
    #   [Learn more about best image practices (WAI Images)](https://www.w3.org/WAI/tutorials/images/)
    class Avatar < Primer::Component
      status :beta

      DEFAULT_SIZE = 20
      SMALL_THRESHOLD = 24

      DEFAULT_SHAPE = :circle
      SHAPE_OPTIONS = [DEFAULT_SHAPE, :square].freeze

      SIZE_OPTIONS = [16, DEFAULT_SIZE, SMALL_THRESHOLD, 32, 40, 48, 64, 80].freeze

      # @see
      #   - https://primer.style/foundations/typography/
      #   - https://github.com/primer/css/blob/main/src/support/variables/typography.scss
      FONT_STACK = "-apple-system, BlinkMacSystemFont, 'Segoe UI', 'Noto Sans', Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji'"

      # @param src [String] The source url of the avatar image. If nil/blank, generates an SVG with initials from alt text.
      # @param alt [String] Passed through to alt on img tag. Used to generate initials when src is nil/blank.
      # @param size [Integer] <%= one_of(Primer::Beta::Avatar::SIZE_OPTIONS) %>
      # @param shape [Symbol] Shape of the avatar. <%= one_of(Primer::Beta::Avatar::SHAPE_OPTIONS) %>
      # @param href [String] The URL to link to. If used, component will be wrapped by an `<a>` tag.
      # @param unique_id [String, Integer] Optional unique identifier for generating consistent avatar colors across renders.
      # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
      def initialize(src: nil, alt: nil, size: DEFAULT_SIZE, shape: DEFAULT_SHAPE, href: nil, unique_id: nil, **system_arguments)
        @href = href
        @unique_id = unique_id
        @shape = fetch_or_fallback(SHAPE_OPTIONS, shape, DEFAULT_SHAPE)
        @alt = alt
        @size = fetch_or_fallback(SIZE_OPTIONS, size, DEFAULT_SIZE)

        # Validate that either src or alt is provided
        validate_src_or_alt(src, alt)

        @system_arguments = deny_tag_argument(**system_arguments)
        @system_arguments[:tag] = :img
        @system_arguments[:alt] = alt
        @system_arguments[:size] = @size
        @system_arguments[:height] = @size
        @system_arguments[:width] = @size

        # Generate SVG fallback if src is nil/blank (must happen after @size is set)
        @system_arguments[:src] = src.presence || generate_fallback_svg

        @system_arguments[:classes] = class_names(
          system_arguments[:classes],
          "avatar",
          "avatar-small" => size < SMALL_THRESHOLD,
          "circle" => shape == DEFAULT_SHAPE,
          "lh-0" => href # Addresses an overflow issue with linked avatars
        )
      end

      def call
        if @href
          render(Primer::Beta::Link.new(href: @href, classes: @system_arguments[:classes])) do
            render(Primer::BaseComponent.new(**@system_arguments.except(:classes))) { content }
          end
        else
          render(Primer::BaseComponent.new(**@system_arguments)) { content }
        end
      end

      private

      def validate_src_or_alt(src, alt)
        return if src.present? || alt.present?

        raise ArgumentError, "`src` or `alt` is required." unless Rails.env.production?
      end

      def generate_fallback_svg
        require "base64"
        require "cgi"

        initials = extract_initials(@alt)
        color = generate_avatar_color
        font_size = calculate_font_size
        radius = calculate_border_radius

        svg = <<~SVG.strip
          <svg xmlns="http://www.w3.org/2000/svg" width="#{@size}" height="#{@size}" viewBox="0 0 #{@size} #{@size}">
            <rect width="#{@size}" height="#{@size}" fill="#{color}" rx="#{radius}" ry="#{radius}"/>
            <text x="50%" y="50%" text-anchor="middle" dy="0.35em" fill="white" font-size="#{font_size}" font-weight="600" font-family="#{FONT_STACK}">
              #{CGI.escapeHTML(initials)}
            </text>
          </svg>
        SVG

        "data:image/svg+xml;base64,#{Base64.strict_encode64(svg)}"
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

      def generate_avatar_color
        # Generate consistent color based on unique_id and name
        # Works for both light and dark themes with good contrast
        text = [@unique_id, @alt].compact.join("")
        "hsl(#{value_hash(text)}, 50%, 30%)"
      end

      def value_hash(value)
        return 0 if value.blank?

        hash = 0
        value.to_s.each_char do |char|
          hash = char.ord + ((hash << 5) - hash)
        end
        hash % 360
      end

      def calculate_font_size
        # Font size is 45% of avatar size for good readability, with a minimum of 8px
        [(@size * 0.45).round, 8].max
      end

      def calculate_border_radius
        if @shape == DEFAULT_SHAPE
          # Circle: 50% border radius
          @size / 2.0
        else
          # Square: Use Primer's small border radius (approximately 6px equivalent)
          [@size * 0.125, 6].min
        end
      end
    end
  end
end
