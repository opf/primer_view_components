# frozen_string_literal: true

module Primer
  module OpenProject
    class FieldsetPreview < ViewComponent::Preview
      # @label Default
      # @snapshot
      def default
        render_with_template
      end

      # @param legend_text [String] text
      # @param visually_hide_legend [Boolean]
      def playground(
        legend_text: "Hello fieldset",
        visually_hide_legend: true
      )
        render_with_template(locals: { legend_text: legend_text,
                                       visually_hide_legend: visually_hide_legend })
      end

      def with_legend_text
        render_with_template
      end
    end
  end
end
