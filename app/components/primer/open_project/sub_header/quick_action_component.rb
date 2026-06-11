# frozen_string_literal: true

module Primer
  module OpenProject
    # Thin wrapper for quick filter slots that defers BaseComponent construction to render time,
    # allowing system arguments (e.g. display) to be mutated in before_render.
    # Do not use standalone
    class SubHeader::QuickActionComponent < Primer::Component
      status :open_project

      def initialize(**system_arguments)
        @system_arguments = system_arguments
        system_arguments[:tag] = :div
        system_arguments[:mr] ||= 2
        system_arguments[:classes] = class_names(
          "SubHeader-hiddenOnExpand",
          system_arguments[:classes]
        )
      end

      def merge_system_arguments!(**other_arguments)
        @system_arguments[:aria] = merge_aria(@system_arguments, other_arguments)
        @system_arguments[:data] = merge_data(@system_arguments, other_arguments)
        @system_arguments.merge!(**other_arguments)
      end

      def call
        render(Primer::BaseComponent.new(**@system_arguments)) { content }
      end
    end
  end
end
