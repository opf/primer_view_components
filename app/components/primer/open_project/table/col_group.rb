# frozen_string_literal: true

module Primer
  module OpenProject
    module Table
      class ColGroup < Primer::Component
        status :open_project
        renders_many :cols, ::Primer::OpenProject::Table::ColGroup::Col

        def initialize(**system_arguments) # rubocop:disable Lint/MissingSuper
          @system_arguments = deny_tag_argument(**system_arguments)
          @system_arguments[:tag] = :colgroup
        end

        def render?
          cols.any?
        end
      end
    end
  end
end
