# frozen_string_literal: true

module Primer
  module OpenProject
    class Table
      # The `Table`'s caption.
      #
      # This component is should not be used directly, except for advanced user
      # cases.
      class Caption < Primer::Component
        status :open_project

        attr_reader :text

        def initialize(text: nil, **system_arguments)
          @text = text
          @system_arguments = deny_tag_argument(**system_arguments)
          @system_arguments[:tag] = :caption
        end

        def call
          render(Primer::BaseComponent.new(**@system_arguments)) { caption_content }
        end

        def render?
          caption_content.present?
        end

        private

        def caption_content
          @caption_content ||= content || text
        end
      end
    end
  end
end
