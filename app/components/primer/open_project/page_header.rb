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

      DEFAULT_BACK_BUTTON_SIZE = :medium
      DEFAULT_BACK_BUTTON_ICON = "arrow-left"

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

      # Optional back button prepend the title
      renders_one :back_button, lambda { |
        size: DEFAULT_BACK_BUTTON_SIZE,
        icon: DEFAULT_BACK_BUTTON_ICON,
        **system_arguments
      |
        deny_tag_argument(**system_arguments)
        system_arguments[:tag] = :a
        system_arguments[:scheme] = :invisible
        system_arguments[:classes] = class_names(system_arguments[:classes], "PageHeader-backButton")

        Primer::Beta::IconButton.new(size: size, icon: icon, **system_arguments)
      }

      # Optional breadcrumbs above the title row
      # Items can be an array of string, hash {href, text} or an anchor tag string
      renders_one :breadcrumbs, lambda { |items, show_breadcrumb: true|
        return unless show_breadcrumb

        render(Primer::Beta::Breadcrumbs.new(classes: ["PageHeader-breadcrumbs"])) do |breadcrumbs|
          items.each do |item|
            # transform anchor tag strings to {href, text} objects
            # e.g "\u003ca href=\"/admin\"\u003eAdministration\u003c/a\u003e"
            item = anchor_string_to_object(item) if item.is_a?(String) && item.start_with?("\u003c")

            if item.is_a?(String)
              breadcrumbs.with_item(href: "#") { item }
            else
              breadcrumbs.with_item(href: item[:href]) { item[:text] }
            end
          end
        end
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

      private

      def anchor_string_to_object(html_string)
        # Parse the HTML
        doc = Nokogiri::HTML.fragment(html_string)
        # Extract href and text
        anchor = doc.at("a")
        { href: anchor["href"], text: anchor.text }
      end
    end
  end
end
