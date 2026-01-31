# frozen_string_literal: true

module Primer
  module OpenProject
    module Table
      class Head < RowGroup
        status :open_project
        renders_many :rows, HeaderRow

        def initialize(**system_arguments)
          system_arguments = deny_tag_argument(**system_arguments)
          system_arguments[:tag] = :thead

          super
        end
      end
    end
  end
end
