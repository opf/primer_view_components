# frozen_string_literal: true

module Primer
  module OpenProject
    class Table
      # A `Table` cell.
      #
      # This component should not be used directly, except for advanced use
      # cases.
      class Cell < Primer::Component
        status :open_project

        attr_reader :text

        DEFAULT_ALIGNMENT = :start
        ALIGNMENT_OPTIONS = [DEFAULT_ALIGNMENT, :end].freeze

        # @param text [String, nil] Cell content, alternatively to a block
        # @param align [Symbol] Horizontal alignment of the cell content
        # @param explicit_roles [Boolean] Whether the cell renders its implicit
        #   ARIA role as an explicit `role` attribute
        # @param system_arguments [Hash]
        #   System arguments passed to the root element
        def initialize(text: nil, align: DEFAULT_ALIGNMENT, explicit_roles: false, **system_arguments)
          resolved_align = fetch_or_fallback(ALIGNMENT_OPTIONS, align, DEFAULT_ALIGNMENT)
          @text = text

          @system_arguments = deny_tag_argument(**system_arguments)
          @system_arguments[:tag] = :td
          @system_arguments[:role] = :cell if explicit_roles
          @system_arguments[:data] = merge_data(
            @system_arguments, data: { cell_align: resolved_align }
          )
        end

        def call
          render(Primer::BaseComponent.new(**@system_arguments)) { cell_content }
        end

        private

        def cell_content
          @cell_content ||= content || text
        end
      end
    end
  end
end
