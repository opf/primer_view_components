# frozen_string_literal: true

module Primer
  module OpenProject
    class Table
      # The `Table`'s footer.
      #
      # This component is should not be used directly, except for advanced user
      # cases.
      class Foot < ::Primer::OpenProject::Table::RowGroup
        status :open_project

        renders_many :rows, ::Primer::OpenProject::Table::Row

        def initialize(**system_arguments)
          system_arguments = deny_tag_argument(**system_arguments)
          system_arguments[:tag] = :tfoot

          super
        end
      end
    end
  end
end
