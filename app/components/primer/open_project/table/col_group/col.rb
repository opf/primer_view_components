# frozen_string_literal: true

module Primer
  module OpenProject
    class Table
      class ColGroup
        class Col < Primer::Component
          status :open_project

          def initialize(span: 1, **system_arguments) # rubocop:disable Lint/MissingSuper
            @system_arguments = deny_tag_argument(**system_arguments)
            @system_arguments[:tag]  = :col
            @system_arguments[:span] = span.to_s
          end

          def call
            render(Primer::BaseComponent.new(**@system_arguments))
          end
        end
      end
    end
  end
end
