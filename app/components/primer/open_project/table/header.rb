# frozen_string_literal: true

module Primer
  module OpenProject
    class Table
      # A `Table`'s header cell.
      #
      # This component is should not be used directly, except for advanced user
      # cases.
      class Header < Primer::Component
        status :open_project

        DEFAULT_SCOPE = :col
        SCOPE_OPTIONS = [DEFAULT_SCOPE, :row].freeze

        def initialize(scope: DEFAULT_SCOPE, align: Cell::DEFAULT_ALIGNMENT, **system_arguments)
          resolved_scope = fetch_or_fallback(SCOPE_OPTIONS, scope, DEFAULT_SCOPE)
          resolved_align = fetch_or_fallback(
            Cell::ALIGNMENT_OPTIONS,
            align,
            Cell::DEFAULT_ALIGNMENT
          )

          @system_arguments = deny_tag_argument(**system_arguments)
          @system_arguments[:tag] = :th
          @system_arguments[:scope] = resolved_scope
          @system_arguments[:role] = resolved_scope == :row ? :rowheader : :columnheader
          @system_arguments[:data] = merge_data(
            @system_arguments, data: { cell_align: resolved_align }
          )
        end

        def call
          render(Primer::BaseComponent.new(**@system_arguments)) { content }
        end
      end
    end
  end
end
