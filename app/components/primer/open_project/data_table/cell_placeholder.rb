# frozen_string_literal: true

module Primer
  module OpenProject
    class DataTable
      # Renders muted placeholder text inside a table cell, standing in for
      # an empty value. Ported from Primer React's `Table.CellPlaceholder`.
      #
      # This component is part of `Primer::OpenProject::DataTable` and should
      # not be used as a standalone component. Use it inside a custom cell
      # renderer, or set `placeholder:` on a column to substitute blank
      # values automatically.
      class CellPlaceholder < Primer::Component
        status :open_project

        # @param system_arguments [Hash]
        #   System arguments passed to the root element
        def initialize(**system_arguments)
          @system_arguments = system_arguments
          @system_arguments[:tag] = :span
          @system_arguments[:classes] = class_names(
            @system_arguments[:classes],
            "TableCellPlaceholder"
          )
        end

        def call
          render(Primer::BaseComponent.new(**@system_arguments)) { content }
        end
      end
    end
  end
end
