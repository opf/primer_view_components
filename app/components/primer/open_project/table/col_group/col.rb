# frozen_string_literal: true

module Primer
  module OpenProject
    class Table
      class ColGroup
        # A `Table` column.
        #
        # This component should not be used directly, except for advanced use
        # cases.
        class Col < Primer::Component
          status :open_project

          def initialize(span: 1, width: nil, **system_arguments)
            @system_arguments = deny_tag_argument(**system_arguments)
            @system_arguments[:tag]  = :col
            @system_arguments[:span] = span.to_s
            @system_arguments[:style] = join_style_arguments(@system_arguments[:style], "width: #{css_width(width)};") if width
          end

          def call
            render(Primer::BaseComponent.new(**@system_arguments))
          end

          private

          def css_width(width)
            width.is_a?(Numeric) ? "#{width}px" : width
          end
        end
      end
    end
  end
end
