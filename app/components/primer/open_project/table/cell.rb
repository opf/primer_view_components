# frozen_string_literal: true

module Primer
  module OpenProject
    class Table
      # A `Table` cell.
      #
      # This component is should not be used directly, except for advanced user
      # cases.
      class Cell < Primer::Component
        status :open_project

        attr_reader :text

        DEFAULT_ALIGNMENT = :start
        ALIGNMENT_OPTIONS = [DEFAULT_ALIGNMENT, :end].freeze

        def initialize(text: nil, align: DEFAULT_ALIGNMENT, **system_arguments)
          resolved_align = fetch_or_fallback(ALIGNMENT_OPTIONS, align, DEFAULT_ALIGNMENT)
          @text = text

          @system_arguments = deny_tag_argument(**system_arguments)
          @system_arguments[:tag] = :td
          @system_arguments[:role] = :cell
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
