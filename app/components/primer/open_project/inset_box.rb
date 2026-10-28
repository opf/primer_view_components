# frozen_string_literal: true

module Primer
  module OpenProject
    # A box with an inset background, used to call out a piece of content such
    # as a tip, a warning, or a code snippet, optionally with a title, icon and actions.
    class InsetBox < Primer::Component
      status :open_project

      DEFAULT_SCHEME = :default
      SCHEME_MAPPINGS = {
        DEFAULT_SCHEME => { bg: :inset },
        info: { bg: :accent, border_color: :accent },
        warning: { bg: :attention, border_color: :attention },
        danger: { bg: :danger, border_color: :danger },
        success: { bg: :success, border_color: :success }
      }.freeze

      attr_reader :border, :scheme_arguments, :system_arguments

      # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
      renders_one :title_icon, Primer::Beta::Octicon

      # @param tag [Symbol] <%= one_of(Primer::Beta::Heading::TAG_OPTIONS) %>
      # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
      renders_one :title, lambda { |tag: :h3, **system_arguments|
        Primer::Beta::Heading.new(tag: tag, font_size: 5, font_weight: :semibold, **system_arguments)
      }

      # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
      renders_many :actions, types: {
        button: lambda { |**system_arguments|
          Primer::Beta::Button.new(**system_arguments)
        },
        menu: lambda { |**system_arguments|
          Primer::Alpha::ActionMenu.new(**system_arguments)
        }
      }

      # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
      renders_one :clipboard_copy_button, lambda { |**system_arguments|
        system_arguments[:scheme] ||= :invisible
        system_arguments[:size] = :small
        system_arguments[:ml] = 2
        Primer::Beta::ClipboardCopyButton.new(**system_arguments)
      }

      # @param border [Boolean] Whether to render a border around the box.
      # @param scheme [Symbol] <%= one_of(Primer::OpenProject::InsetBox::SCHEME_MAPPINGS.keys) %>
      # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
      def initialize(border: true, scheme: DEFAULT_SCHEME, **system_arguments)
        @border = border
        @scheme_arguments = SCHEME_MAPPINGS[fetch_or_fallback(SCHEME_MAPPINGS.keys, scheme, DEFAULT_SCHEME)]
        @system_arguments = system_arguments

        @system_arguments[:classes] = class_names(
          @system_arguments[:classes],
          "InsetBox"
        )
      end
    end
  end
end
