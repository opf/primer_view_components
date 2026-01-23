# frozen_string_literal: true

module Primer
  module Forms
    # :nodoc:
    class FieldsetGroup < BaseComponent
      ##
      # @param title [String] The title displayed as the heading for the fieldset
      # @param inputs [Array<Primer::Forms::Dsl::Input>] Array of form inputs to be grouped
      # @param builder [ActionView::Helpers::FormBuilder] The form builder instance
      # @param form [Primer::Forms::BaseForm] The form object
      # @param layout [Symbol] Layout style for the input group (default: :default_layout)
      # @param heading_arguments [Hash] Arguments passed to the heading component
      # @option heading_arguments [String] :id The ID for the heading element
      # @option heading_arguments [Symbol] :tag The HTML tag for the heading (default: :h3)
      # @option heading_arguments [Symbol] :size The size of the heading (default: :medium)
      # @param group_arguments [Hash] Arguments passed to the input group component
      # @param system_arguments [Hash] Additional system arguments passed to the section wrapper
      def initialize( # rubocop:disable Metrics/AbcSize
        title:,
        inputs:,
        builder:,
        form:,
        layout: Primer::Forms::Group::DEFAULT_LAYOUT,
        heading_arguments: {},
        group_arguments: {},
        **system_arguments
      )
        super()

        @title = title

        @heading_arguments = heading_arguments
        @heading_arguments[:id] ||= "subhead-#{SecureRandom.uuid}"
        @heading_arguments[:tag] ||= :h3
        @heading_arguments[:size] ||= :medium

        @fieldset_arguments = {
          legend_text: @title,
          visually_hide_legend: true,
          aria: { labelledby: @heading_arguments[:id] }
        }
        @group_arguments = group_arguments.merge(inputs:, builder:, form:, layout:)

        @system_arguments = system_arguments
        @system_arguments[:tag] = :section
        @system_arguments[:mb] ||= 4
        @system_arguments[:aria] ||= {}
        @system_arguments[:aria][:labelledby] = @heading_arguments[:id]
        @system_arguments[:hidden] = :none if inputs.all?(&:hidden?)
      end
    end
  end
end
