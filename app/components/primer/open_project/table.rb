# frozen_string_literal: true

module Primer
  module OpenProject
    class Table < Primer::Component
      status :open_project
      renders_one :caption, ::Primer::OpenProject::Table::Caption

      renders_many :cols, ::Primer::OpenProject::Table::ColGroup::Col
      renders_many :colgroups, ::Primer::OpenProject::Table::ColGroup

      renders_one :head, Head
      renders_many :bodies, Body
      renders_one :foot, Foot

      def initialize(**system_arguments) # rubocop:disable Lint/MissingSuper
        @system_arguments = deny_tag_argument(**system_arguments)
        @system_arguments[:tag] = :table
        @system_arguments[:role] = :table
      end
    end
  end
end
