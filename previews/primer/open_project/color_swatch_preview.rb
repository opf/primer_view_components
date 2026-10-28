# frozen_string_literal: true

module Primer
  module OpenProject
    # @label ColorSwatch
    class ColorSwatchPreview < ViewComponent::Preview
      # @label Playground
      # @param hexcode [String] text
      # @param show_value [Boolean] toggle
      def playground(hexcode: "#CC0000", show_value: false)
        render(Primer::OpenProject::ColorSwatch.new(hexcode: hexcode, show_value: show_value))
      end

      # @label Default
      # @snapshot
      def default
        render(Primer::OpenProject::ColorSwatch.new(hexcode: "#CC0000"))
      end

      # @label With value
      # @snapshot
      def with_value
        render(Primer::OpenProject::ColorSwatch.new(hexcode: "#CC0000", show_value: true))
      end
    end
  end
end
