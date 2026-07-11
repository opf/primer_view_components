# frozen_string_literal: true

module Primer
  module OpenProject
    class Table
      # A `Table`'s row group
      #
      # This component should not be used directly, except for advanced use
      # cases.
      class RowGroup < Primer::Component
        status :open_project

        # @param explicit_roles [Boolean] Whether the row group and its rows render
        #   their implicit ARIA roles as explicit `role` attributes
        # @param system_arguments [Hash]
        #   System arguments passed to the root element
        def initialize(explicit_roles: false, **system_arguments)
          @explicit_roles = explicit_roles

          @system_arguments = system_arguments
          @system_arguments[:role] = :rowgroup if explicit_roles
        end

        def rows
          []
        end

        def render?
          rows.any? || content?
        end
      end
    end
  end
end
