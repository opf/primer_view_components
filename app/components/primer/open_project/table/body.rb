# frozen_string_literal: true

module Primer
  module OpenProject
    module Table
      class Body < ::Primer::OpenProject::Table::RowGroup
        renders_many :rows, ::Primer::OpenProject::Table::Row
        status :open_project

        def initialize(**system_arguments)
          system_arguments = deny_tag_argument(**system_arguments)
          system_arguments[:tag] = :tbody

          super
        end
      end
    end
  end
end
