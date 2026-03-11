# frozen_string_literal: true

module Primer
  module OpenProject
    class Table
      class ColGroup
        # A `Table` column.
        #
        # This component is should not be used directly, except for advanced
        # user cases.
        class Col < Primer::Component
          status :open_project


          def initialize(span: 1, **system_arguments)
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
