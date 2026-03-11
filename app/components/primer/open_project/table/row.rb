# frozen_string_literal: true

module Primer
  module OpenProject
    class Table
      # A `Table` row.
      #
      # This component is should not be used directly, except for advanced user
      # cases.
      class Row < Primer::Component
        status :open_project

        renders_many :cells, types: {
          column_header: {
            renders: ->(component_klass: Header, **system_arguments) {
              component_klass.new(**system_arguments, scope: :col)
            },
            as: :column_header
          },
          row_header: {
            renders: ->(component_klass: Header, **system_arguments) {
              component_klass.new(**system_arguments, scope: :row)
            },
            as: :row_header
          },
          cell: {
            renders: Cell,
            as: :cell
          }
        }

        def initialize(**system_arguments)
          @system_arguments = deny_tag_argument(**system_arguments)
          @system_arguments[:tag] = :tr
          @system_arguments[:role] = :row
        end
      end
    end
  end
end
