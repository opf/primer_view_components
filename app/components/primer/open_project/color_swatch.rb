# frozen_string_literal: true

module Primer
  module OpenProject
    # Displays a small colored indicator for a given hex color code, optionally
    # showing the hex value next to it.
    class ColorSwatch < Primer::Component
      status :open_project

      # @param hexcode [String] The hex color code to display, e.g. `#FF0000`.
      # @param show_value [Boolean] Whether to display the hex value next to the swatch.
      # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
      def initialize(hexcode:, show_value: false, **system_arguments)
        @hexcode = hexcode
        @show_value = show_value
        @system_arguments = system_arguments
        @system_arguments[:align_items] ||= :center

        @system_arguments[:classes] = class_names(
          @system_arguments[:classes],
          "ColorSwatch"
        )
      end

      def call
        render(Primer::OpenProject::FlexLayout.new(**@system_arguments)) do |flex|
          flex.with_column do
            render(Primer::BaseComponent.new(**swatch_arguments))
          end

          if show_value?
            flex.with_column do
              render(Primer::Beta::Text.new(tag: :span, ml: 2)) { hexcode }
            end
          end
        end
      end

      private

      attr_reader :hexcode

      def show_value?
        @show_value
      end

      def swatch_arguments
        {
          tag: :div,
          classes: "ColorSwatch--indicator",
          aria: { hidden: true },
          style: "background-color: #{hexcode}"
        }
      end
    end
  end
end
