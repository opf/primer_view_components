# frozen_string_literal: true

module Primer
  module Forms
    # :nodoc:
    class BaseComponent
      include Primer::ClassNameHelper
      extend ActsAsComponent

      def self.inherited(base)
        base.renders_template(
          File.join("%{base_template_path}", "#{base.name.demodulize.underscore}.html.erb"),
          :render_template
        )
      end

      delegate :required?, :disabled?, :hidden?, to: :@input

      def perform_render(&block)
        return "" unless render?

        @__prf_content_block = block
        compile_and_render_template
      end

      def content
        return @__prf_content if defined?(@__prf_content_evaluated) && @__prf_content_evaluated

        @__prf_content_evaluated = true
        @__prf_content = capture do
          @__prf_content_block.call
        end
      end

      # :nocov:
      def type
        :component
      end
      # :nocov:

      def input?
        false
      end

      def to_component
        self
      end

      def render?
        true
      end

      private

      def compile_and_render_template
        self.class.compile! unless self.class.instance_methods(false).include?(:render_template)
        render_template
      end
    end
  end
end
