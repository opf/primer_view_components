# frozen_string_literal: true

module Primer
  module OpenProject
    # A simple component to render warning text.
    #
    # The warning text is rendered in the "attention" Primer color and
    # uses a leading alert Octicon for additional emphasis. This component
    # is designed to be used "inline", e.g. table cells, and in places
    # where a Banner component might be overkill.
    class InlineMessage < Primer::Component
      SCHEME_ICON_MAPPINGS = {
        warning: :alert,
        critical: :alert,
        success: :"check-circle",
        unavailable: :alert
      }.freeze
      private_constant :SCHEME_ICON_MAPPINGS
      SCHEME_OPTIONS = SCHEME_ICON_MAPPINGS.keys.freeze

      SCHEME_SMALL_ICON_MAPPINGS = {
        warning: :"alert-fill",
        critical: :"alert-fill",
        success: :"check-circle-fill",
        unavailable: :"alert-fill"
      }.freeze
      private_constant :SCHEME_SMALL_ICON_MAPPINGS
      DEFAULT_SIZE = :medium
      SIZE_OPTIONS = [:small, DEFAULT_SIZE].freeze

      # @param scheme [Symbol] <%= one_of(Primer::OpenProject::InlineMessage::SCHEME_OPTIONS) %>
      # @param size [Symbol] <%= one_of(Primer::OpenProject::InlineMessage::SIZE_OPTIONS) %>
      # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
      def initialize(scheme:, size: DEFAULT_SIZE, **system_arguments) # rubocop:disable Lint/MissingSuper
        resolved_scheme = fetch_or_fallback(SCHEME_OPTIONS, scheme)
        resolved_size   = fetch_or_fallback(SIZE_OPTIONS, size, DEFAULT_SIZE)

        @system_arguments = system_arguments
        @system_arguments[:tag] ||= :div
        @system_arguments[:classes] = class_names(
          @system_arguments[:classes],
          "InlineMessage"
        )
        @system_arguments[:data] = merge_data(
          @system_arguments,
          { data: { size: resolved_size, variant: resolved_scheme } }
        )

        @icon_arguments = { classes: "InlineMessageIcon" }
        if resolved_size == :small
          @icon_arguments[:icon] = SCHEME_SMALL_ICON_MAPPINGS[resolved_scheme]
          @icon_arguments[:size] = :xsmall
        else
          @icon_arguments[:icon] = SCHEME_ICON_MAPPINGS[resolved_scheme]
        end
      end

      def render?
        content.present?
      end
    end
  end
end
