# frozen_string_literal: true

module Primer
  module OpenProject
    class FieldsetComponent < Primer::Component
      attr_reader :legend_text

      renders_one :legend, ->(**system_arguments) {
        LegendComponent.new(visually_hide_legend: @visually_hide_legend, **system_arguments)
      }

      # @param legend_text [String] A legend should be short and concise. The String will also be read by assistive technology.
      # @param visually_hide_legend [Boolean] Controls if the legend is visible. If `true`, screen reader only text will be added.
      # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
      def initialize(legend_text: nil, visually_hide_legend: false, **system_arguments) # rubocop:disable Lint/MissingSuper
        @legend_text = legend_text
        @visually_hide_legend = visually_hide_legend
        @system_arguments = deny_tag_argument(**system_arguments)
        @system_arguments[:tag] = :fieldset

        deny_aria_key(
          :label,
          "instead of `aria-label`, include `legend_text` and set `visually_hide_legend` to `true` on the component initializer.",
          **@system_arguments
        )
      end

      def render?
        content? && (legend_text.present? || legend?)
      end

      class LegendComponent < Primer::Component
        attr_reader :text

        def initialize(text: nil, visually_hide_legend: false, **system_arguments) # rubocop:disable Lint/MissingSuper
          @text = text

          @system_arguments = deny_tag_argument(**system_arguments)
          @system_arguments[:tag] = :legend
          @system_arguments[:classes] = class_names(
            @system_arguments[:classes],
            { "sr-only" => visually_hide_legend }
          )
        end

        def call
          render(Primer::BaseComponent.new(**@system_arguments)) { legend_content }
        end

        private

        def legend_content
          @legend_content ||= content || text
        end
      end
    end
  end
end
