# frozen_string_literal: true

module Primer
  module OpenProject
    class Table
      # The `Table`'s footer.
      #
      # This component should not be used directly, except for advanced use
      # cases.
      class Foot < ::Primer::OpenProject::Table::RowGroup
        status :open_project

        renders_many :rows, ->(**system_arguments) {
          ::Primer::OpenProject::Table::Row.new(explicit_roles: @explicit_roles, **system_arguments)
        }

        def initialize(**system_arguments)
          system_arguments = deny_tag_argument(**system_arguments)
          system_arguments[:tag] = :tfoot

          super
        end
      end
    end
  end
end
