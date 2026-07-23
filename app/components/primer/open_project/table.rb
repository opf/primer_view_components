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

      renders_one :head, ->(**system_arguments) {
        Head.new(explicit_roles: @explicit_roles, **system_arguments)
      }
      renders_many :bodies, ->(**system_arguments) {
        Body.new(explicit_roles: @explicit_roles, **system_arguments)
      }
      renders_one :foot, ->(**system_arguments) {
        Foot.new(explicit_roles: @explicit_roles, **system_arguments)
      }

      # @param explicit_roles [Boolean] Whether the table and its descendants
      #   render their implicit ARIA roles as explicit `role` attributes.
      #   Needed when CSS strips the native table semantics, as
      #   <%= link_to_component(Primer::OpenProject::DataTable) %>'s grid layout does.
      # @param system_arguments [Hash]
      #   System arguments passed to the root element
      def initialize(explicit_roles: false, **system_arguments)
        @explicit_roles = explicit_roles

        @system_arguments = deny_tag_argument(**system_arguments)
        @system_arguments[:tag] = :table
        @system_arguments[:role] = :table if explicit_roles
      end
    end
  end
end
