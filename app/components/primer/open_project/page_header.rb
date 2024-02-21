# frozen_string_literal: true

module Primer
  module OpenProject
    # A ViewComponent PageHeader inspired by the primer react variant
    class PageHeader < Primer::Component
      HEADING_TAG_OPTIONS = [:h1, :h2, :h3, :h4, :h5, :h6].freeze
      HEADING_TAG_FALLBACK = :h1

      DEFAULT_HEADER_VARIANT = :medium
      HEADER_VARIANT_OPTIONS = [
        DEFAULT_HEADER_VARIANT,
        :large
      ].freeze

      DEFAULT_BACK_BUTTON_ICON = "arrow-left"
      BACK_BUTTON_ICON_OPTIONS = [
        DEFAULT_BACK_BUTTON_ICON,
        "chevron-left",
        "triangle-left"
      ].freeze

      DEFAULT_LEADING_ACTION_DISPLAY = [:none, :flex].freeze
      DEFAULT_BREADCRUMBS_DISPLAY = [:none, :flex].freeze
      DEFAULT_PARENT_LINK_DISPLAY = [:block, :none].freeze
      DEFAULT_CONTEXT_BAR_ACTIONS_DISPLAY = [:flex, :none].freeze

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
      renders_many :actions, lambda { |**system_arguments|
        deny_tag_argument(**system_arguments)
        system_arguments[:tag] = :div
        system_arguments[:ml] ||= 2

        Primer::BaseComponent.new(**system_arguments)
      }

      # Context Bar Actions
      # By default shown on narrow screens. Can be overridden with system_argument: display
      #
      # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
      renders_many :context_bar_actions, lambda { |**system_arguments|
        deny_tag_argument(**system_arguments)
        system_arguments[:tag] = :div
        system_arguments[:ml] ||= 2

        Primer::BaseComponent.new(**system_arguments)
      }

      # Optional leading action prepend the title
      # By default shown on wider screens. Can be overridden with system_argument: display
      #
      # @param icon [Symbol] The name of an <%= link_to_octicons %> icon to use.
      # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
      renders_one :leading_action, lambda { |
        icon:,
        **system_arguments
      |
        deny_tag_argument(**system_arguments)
        system_arguments[:tag] = :a
        system_arguments[:scheme] = :invisible
        system_arguments[:icon] = icon
        system_arguments[:classes] = class_names(system_arguments[:classes], "PageHeader-leadingAction")
        system_arguments[:display] ||= DEFAULT_LEADING_ACTION_DISPLAY

        Primer::Beta::IconButton.new(icon: icon, **system_arguments)
      }

      # Optional parent link in the context area
      # By default shown on narrow screens. Can be overridden with system_argument: display
      #
      # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
      renders_one :parent_link, lambda { |icon: DEFAULT_BACK_BUTTON_ICON, **system_arguments, &block|
        deny_tag_argument(**system_arguments)
        system_arguments[:icon] = fetch_or_fallback(BACK_BUTTON_ICON_OPTIONS, icon, DEFAULT_BACK_BUTTON_ICON)
        system_arguments[:classes] = class_names(system_arguments[:classes], "PageHeader-parentLink")
        system_arguments[:display] ||= DEFAULT_PARENT_LINK_DISPLAY

        render(Primer::Beta::Link.new(scheme: :primary, muted: true, **system_arguments)) do
          render(Primer::Beta::Octicon.new(icon: "arrow-left", "aria-label": "aria_label", mr: 2)) + content_tag(:span, &block)
        end
      }

      # Optional breadcrumbs above the title row
      # By default shown on wider screens. Can be overridden with system_argument: display
      #
      # @param items [Array<String, Hash>] Items is an array of strings, hash {href, text} or an anchor tag string
      # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
      renders_one :breadcrumbs, lambda { |items, **system_arguments|
        system_arguments[:classes] = class_names(system_arguments[:classes], "PageHeader-breadcrumbs")
        system_arguments[:display] ||= DEFAULT_BREADCRUMBS_DISPLAY

        render(Primer::Beta::Breadcrumbs.new(**system_arguments)) do |breadcrumbs|
          items.each do |item|
            item = anchor_string_to_object(item) if anchor_tag_string?(item)

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

      # transform anchor tag strings to {href, text} objects
      # e.g "\u003ca href=\"/admin\"\u003eAdministration\u003c/a\u003e"
      def anchor_string_to_object(html_string)
        # Parse the HTML
        doc = Nokogiri::HTML.fragment(html_string)
        # Extract href and text
        anchor = doc.at("a")
        { href: anchor["href"], text: anchor.text }
      end

      # Check if the item is an anchor tag string e.g "\u003ca href=\"/admin\"\u003eAdministration\u003c/a\u003e"
      def anchor_tag_string?(item)
        item.is_a?(String) && item.start_with?("\u003c")
      end
    end
  end
end
