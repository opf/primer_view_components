# frozen_string_literal: true

module Primer
  module OpenProject
    # @label AvatarWithFallback
    class AvatarWithFallbackPreview < ViewComponent::Preview
      # @label Playground
      #
      # @param size [Integer] select [16, 20, 24, 32, 40, 48, 64, 80]
      # @param shape [Symbol] select [circle, square]
      # @param href [String] text
      # @param with_src [Boolean] toggle
      def playground(size: 24, shape: :circle, href: nil, with_src: false)
        if with_src
          render(Primer::OpenProject::AvatarWithFallback.new(src: Primer::ExampleImage::BASE64_SRC, alt: "@kittenuser", size: size, shape: shape, href: href))
        else
          render(Primer::OpenProject::AvatarWithFallback.new(alt: "OpenProject Admin", unique_id: 4, size: size, shape: shape, href: href))
        end
      end

      # @label Default
      # @snapshot
      def default
        render(Primer::OpenProject::AvatarWithFallback.new(src: Primer::ExampleImage::BASE64_SRC, alt: "@kittenuser"))
      end

      # @label With image src
      # @snapshot
      def with_image
        render(Primer::OpenProject::AvatarWithFallback.new(src: Primer::ExampleImage::BASE64_SRC, alt: "@kittenuser"))
      end

      # @!group Fallback (Initials)
      #
      # @label Fallback with initials
      # @snapshot
      def fallback_default
        render(Primer::OpenProject::AvatarWithFallback.new(alt: "OpenProject Admin", unique_id: 4))
      end

      # @label Fallback single name
      # @snapshot
      def fallback_single_name
        render(Primer::OpenProject::AvatarWithFallback.new(alt: "John", unique_id: 2))
      end

      # @label Fallback multiple users
      def fallback_multiple
        render_with_template(locals: {})
      end

      # @label Fallback sizes
      def fallback_sizes
        render_with_template(locals: {})
      end

      # @label Fallback square shape
      # @snapshot
      def fallback_square
        render(Primer::OpenProject::AvatarWithFallback.new(alt: "OpenProject Org", unique_id: 100, shape: :square))
      end

      # @label Fallback as link
      def fallback_as_link
        render(Primer::OpenProject::AvatarWithFallback.new(alt: "Jane Doe", unique_id: 3, href: "#"))
      end
      #
      # @!endgroup

      # @!group Error Handling (404 Fallback)
      #
      # @label Broken image (404)
      # @snapshot
      def broken_image_404
        # Uses a non-existent URL - will trigger error handler and show fallback SVG
        render(Primer::OpenProject::AvatarWithFallback.new(
          src: "/non-existent-avatar.png",
          alt: "User With Missing Avatar",
          unique_id: 42
        ))
      end

      # @label Multiple broken images
      def multiple_broken_images
        render_with_template(locals: {})
      end
      #
      # @!endgroup
    end
  end
end
