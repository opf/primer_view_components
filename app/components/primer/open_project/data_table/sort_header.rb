# frozen_string_literal: true

module Primer
  module OpenProject
    class DataTable
      # This component is part of `Primer::OpenProject::DataTable` and should
      # not be used as a standalone component.
      class SortHeader < Primer::Component
        status :open_project

        DEFAULT_DIRECTION = :ASC
        DIRECTION_OPTIONS = [DEFAULT_DIRECTION, :DESC, :NONE].freeze

        ARIA_SORT_OPTIONS = { ASC: "ascending", DESC: "descending" }.freeze

        # @param direction [Symbol] select [:ASC, :DESC, :NONE]
        #   Specify the sort direction for the header.
        # @param href [String, nil]
        #   When given, the header renders a plain sort link to this URL instead
        #   of the client-side sort button (used for external sorting).
        # @param system_arguments [Hash]
        #   System arguments passed to the root element
        def initialize(direction: DEFAULT_DIRECTION, href: nil, **system_arguments)
          @direction = fetch_or_fallback(DIRECTION_OPTIONS, direction, DEFAULT_DIRECTION)
          @href = href
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

        private

        def sort_control
          if @href
            Primer::Beta::Link.new(
              href: @href,
              muted: true,
              classes: "TableSortButton TableSortLink"
            )
          else
            Primer::Beta::BaseButton.new(
              classes: "TableSortButton",
              data: { action: "click:data-table#toggleSort" }
            )
          end
        end
      end
    end
  end
end
