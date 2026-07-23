# frozen_string_literal: true

module Primer
  module OpenProject
    class DataTable
      # Empty-state content rendered as a Primer Blankslate when the table
      # has no rows. The API mirrors OpenProject's `BorderBoxListComponent`
      # empty state so both components share one idiom.
      #
      # This component is part of `Primer::OpenProject::DataTable` and should
      # not be used as a standalone component.
      class EmptyState < Primer::Component
        status :open_project

        HEADING_TAG_DEFAULT = :h3

        # @param title [String] Empty-state heading
        # @param heading_tag [Symbol] Heading level of the empty-state title.
        #   Defaults to `:h3` so it nests under the table's `:h2` title without
        #   skipping a level.
        # @param description [String, nil] Optional supporting text
        # @param icon [Symbol, nil] Optional Primer icon
        # @param interactive [Boolean] Whether empty-state updates should be
        #   announced politely to assistive technology
        # @param system_arguments [Hash]
        #   System arguments passed to the underlying `Primer::Beta::Blankslate`
        def initialize(
          title:,
          heading_tag: HEADING_TAG_DEFAULT,
          description: nil,
          icon: nil,
          interactive: false,
          **system_arguments
        )
          @title = title
          @heading_tag = heading_tag
          @description = description
          @icon = icon

          @system_arguments = system_arguments
          @system_arguments[:border] = true unless @system_arguments.key?(:border)

          return unless interactive

          @system_arguments[:role] ||= "status"
          @system_arguments[:aria] = merge_aria(
            { aria: { live: "polite" } },
            @system_arguments
          )
        end

        def call
          render(blankslate)
        end

        private

        def blankslate
          blankslate = Primer::Beta::Blankslate.new(**@system_arguments)
          # `Primer::Beta::Blankslate` validates the tag against its own
          # heading options.
          blankslate.with_heading(tag: @heading_tag).with_content(@title)
          blankslate.with_description_content(@description) if @description
          blankslate.with_visual_icon(icon: @icon) if @icon

          blankslate
        end
      end
    end
  end
end
