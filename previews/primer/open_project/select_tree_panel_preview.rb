# frozen_string_literal: true

module Primer
  module OpenProject
    # @label SelectTreePanelPreview
    class SelectTreePanelPreview < ViewComponent::Preview
      # @label Multiselect
      #
      # @snapshot interactive
      # @param open_on_load toggle
      # @param expanded [Boolean] toggle
      def multiselect(open_on_load: false, expanded: false)
        render_with_template(locals: { open_on_load: open_on_load, expanded: expanded })
      end
    end
  end
end
