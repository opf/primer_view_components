# frozen_string_literal: true

module Primer
  module OpenProject
    class Table
      # The `Table`'s body.
      #
      # This component is should not be used directly, except for advanced user
      # cases.
      class Body < ::Primer::OpenProject::Table::RowGroup
        status :open_project

        renders_many :rows, ::Primer::OpenProject::Table::Row

        def initialize(**system_arguments)
          system_arguments = deny_tag_argument(**system_arguments)
          system_arguments[:tag] = :tbody

          super
        end
      end
    end
  end
end
