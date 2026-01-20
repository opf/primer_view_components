# frozen_string_literal: true

module Primer
  module OpenProject
    class InlineMessagePreview < ViewComponent::Preview
      # @label Default
      # @snapshot
      def default
      end

      # @label Playground
      # @param scheme [Symbol] select [warning, success]
      # @param size [Symbol] select [small, medium]
      def playground(
        scheme: :warning,
        size: :medium
      )
        render_with_template(locals: { scheme: scheme, size: size })
      end
    end
  end
end
