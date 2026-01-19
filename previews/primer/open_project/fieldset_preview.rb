# frozen_string_literal: true

module Primer
  module OpenProject
    class FieldsetPreview < ViewComponent::Preview
      # @label Default
      # @snapshot
      def default
        render_with_template
      end

      def with_legend_text
        render_with_template
      end
    end
  end
end
