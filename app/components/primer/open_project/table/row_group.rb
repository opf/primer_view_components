# frozen_string_literal: true

module Primer
  module OpenProject
    module Table
      class RowGroup < Primer::Component
        def initialize(**system_arguments) # rubocop:disable Lint/MissingSuper
          @system_arguments = system_arguments
          @system_arguments[:role] = :rowgroup
        end

        def render?
          rows.any? || content?
        end
      end
    end
  end
end
