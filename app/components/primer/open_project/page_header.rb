# frozen_string_literal: true

module Primer
  module OpenProject
    # A ViewComponent PageHeader inspired by the primer react variant
    class PageHeader < Primer::Component
      HEADING_TAG_OPTIONS = [:h1, :h2, :h3, :h4, :h5, :h6].freeze
      HEADING_TAG_FALLBACK = :h2

      DEFAULT_HEADER_VARIANT = :medium
      HEADER_VARIANT_OPTIONS = [
        :large,
        DEFAULT_HEADER_VARIANT
      ].freeze

      status :open_project

      # The title of the page header
      #
      # @param tag [Symbol] <%= one_of(Primer::Beta::Heading::TAG_OPTIONS) %>
      # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
      renders_one :title, lambda { |tag: HEADING_TAG_FALLBACK, variant: DEFAULT_HEADER_VARIANT, **system_arguments|
        system_arguments[:tag] = fetch_or_fallback(HEADING_TAG_OPTIONS, tag, HEADING_TAG_FALLBACK)
        system_arguments[:classes] = class_names(
          system_arguments[:classes],
          "PageHeader-title",
          "PageHeader-title--#{variant}"
        )

        Primer::BaseComponent.new(**system_arguments)
      }

      # Optional description below the title row
      renders_one :description, lambda { |**system_arguments|
        deny_tag_argument(**system_arguments)
        system_arguments[:tag] = :div
        system_arguments[:classes] = class_names(system_arguments[:classes], "PageHeader-description")

        Primer::BaseComponent.new(**system_arguments)
      }

      # Actions
      #
      # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
      renders_one :actions, lambda { |**system_arguments|
        deny_tag_argument(**system_arguments)
        system_arguments[:tag] = :div
        system_arguments[:classes] = class_names(system_arguments[:classes], "PageHeader-actions")

        Primer::BaseComponent.new(**system_arguments)
      }

      def initialize(**system_arguments)
        @system_arguments = deny_tag_argument(**system_arguments)

        @system_arguments[:tag] = :header
        @system_arguments[:classes] =
          class_names(
            @system_arguments[:classes],
            "PageHeader"
          )
      end

      def render?
        title?
      end
    end
  end
end