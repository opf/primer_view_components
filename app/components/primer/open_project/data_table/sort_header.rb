# frozen_string_literal: true

module Primer
  module OpenProject
    module DataTable
      # A component to be used inside Primer::Beta::BorderBox.
      # It will toggle the visibility of the complete Box body
      class SortHeader < Primer::Component
        status :open_project
        DEFAULT_DIRECTION = :ASC
        DIRECTION_OPTIONS = [DEFAULT_DIRECTION, :DESC, :NONE].freeze

        ARIA_SORT_OPTIONS = { ASC: "ascending", DESC: "descending" }.freeze

        # @param direction [Symbol] Specify the sort direction for the header. <%= one_of(DIRECTION_OPTIONS) %>
        # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
        def initialize(direction: DEFAULT_DIRECTION, **system_arguments) # rubocop:disable Lint/MissingSuper
          @direction = fetch_or_fallback(DIRECTION_OPTIONS, direction, DEFAULT_DIRECTION)
          aria_sort = ARIA_SORT_OPTIONS.fetch(@direction, nil)

          @system_arguments = system_arguments
          @system_arguments[:classes] = class_names(
            @system_arguments[:classes],
            "TableHeader"
          )
          @system_arguments[:aria] = merge_aria(
            @system_arguments, { aria: { sort: aria_sort } }
          )
        end
      end
    end
  end
end
