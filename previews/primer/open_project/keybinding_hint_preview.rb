# frozen_string_literal: true

module Primer
  module OpenProject
    # @label KeybindingHint
    class KeybindingHintPreview < ViewComponent::Preview
      # `platform` is forced on snapshotted previews so CI (Linux) and
      # developer machines (macOS) render the same glyphs.
      #
      # @label Default
      # @snapshot
      def default
        render(Primer::OpenProject::KeybindingHint.new(keys: "Mod+Shift+p", data: { platform: "other" }))
      end

      # @label Playground
      # @param keys text
      # @param format [Symbol] select [condensed, full]
      # @param scheme [Symbol] select [default, emphasis]
      # @param size [Symbol] select [medium, small]
      # @param platform [Symbol] select [detect, apple, windows, other]
      def playground(keys: "Mod+Shift+p", format: :condensed, scheme: :default, size: :medium, platform: :detect)
        render_with_template(locals: { keys: keys, format: format.to_sym, scheme: scheme.to_sym, size: size.to_sym, platform: platform.to_sym })
      end

      # @label Full format
      def full_format
        render_with_template
      end

      # @label Sequence
      def sequence
        render_with_template
      end

      # @label Sizes
      def sizes
        render_with_template
      end

      # @label Schemes
      def schemes
        render_with_template
      end

      # @label Platforms
      # @snapshot
      def platforms
        render_with_template
      end

      # @label In prose
      def prose
        render_with_template
      end
    end
  end
end
