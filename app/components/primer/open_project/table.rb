# frozen_string_literal: true

module Primer
  module OpenProject
    # A low-level component for constructing HTML tables with proper structure
    # and semantics.
    #
    # This component is not designed to be used directly, but rather serves as a
    # primitive for authors of other components, such as <%= link_to_component(Primer::OpenProject::DataTable) %>.
    class Table < Primer::Component
      status :open_project

      renders_one :caption, ::Primer::OpenProject::Table::Caption

      renders_many :cols, ::Primer::OpenProject::Table::ColGroup::Col
      renders_many :colgroups, ::Primer::OpenProject::Table::ColGroup

      renders_one :head, Head
      renders_many :bodies, Body
      renders_one :foot, Foot

      def initialize(**system_arguments)
        @system_arguments = deny_tag_argument(**system_arguments)
        @system_arguments[:tag] = :table
        @system_arguments[:role] = :table
      end
    end
  end
end
