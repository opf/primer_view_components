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

        def initialize(**system_arguments)
          @system_arguments = system_arguments
          @system_arguments[:role] = :rowgroup
        end

        def render?
          rows.any? || content?
        end
      end
    end
  end
end
