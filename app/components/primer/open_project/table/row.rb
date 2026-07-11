# frozen_string_literal: true

module Primer
  module OpenProject
    class Table
      # A `Table` row.
      #
      # This component should not be used directly, except for advanced use
      # cases.
      class Row < Primer::Component
        status :open_project

        renders_many :cells, types: {
          column_header: {
            renders: ->(component_klass: Header, **system_arguments) {
              component_klass.new(explicit_roles: @explicit_roles, **system_arguments, scope: :col)
            },
            as: :column_header
          },
          row_header: {
            renders: ->(component_klass: Header, **system_arguments) {
              component_klass.new(explicit_roles: @explicit_roles, **system_arguments, scope: :row)
            },
            as: :row_header
          },
          cell: {
            renders: ->(**system_arguments) {
              Cell.new(explicit_roles: @explicit_roles, **system_arguments)
            },
            as: :cell
          }
        }

        # @param explicit_roles [Boolean] Whether the row and its cells render
        #   their implicit ARIA roles as explicit `role` attributes
        # @param system_arguments [Hash]
        #   System arguments passed to the root element
        def initialize(explicit_roles: false, **system_arguments)
          @explicit_roles = explicit_roles

          @system_arguments = deny_tag_argument(**system_arguments)
          @system_arguments[:tag] = :tr
          @system_arguments[:role] = :row if explicit_roles
        end
      end
    end
  end
end
