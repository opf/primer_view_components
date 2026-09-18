# frozen_string_literal: true

module Primer
  module Beta
    # @label BorderBox
    class BorderBoxPreview < ViewComponent::Preview
      # @label Playground
      #
      # @param list_id text
      # @param padding [Symbol] select [default, condensed, spacious]
      # @param scheme [Symbol] select [default, neutral, info, warning]
      def playground(padding: :default, scheme: :default, list_id: "my-list")
        render(Primer::Beta::BorderBox.new(padding: padding, list_arguments: { id: list_id })) do |component|
          component.with_header { "Header" }
          component.with_body { "Body" }
          component.with_row(scheme: scheme) { "#{scheme.to_s.capitalize} row one" }
          component.with_row(scheme: scheme) { "#{scheme.to_s.capitalize} row two" }
          component.with_row(scheme: scheme) { "#{scheme.to_s.capitalize} row three" }
          component.with_footer { "Footer" }
        end
      end

      # @label Default
      # @snapshot
      def default
        render(Primer::Beta::BorderBox.new) do |component|
          component.with_header { "Header" }
          component.with_body { "Body" }
          component.with_row { "Row one" }
          component.with_row { "Row two" }
          component.with_row { "Row three" }
          component.with_footer { "Footer" }
        end
      end

      # @label Header with title
      def header_with_title
        render(Primer::Beta::BorderBox.new) do |component|
          component.with_header do |header|
            header.with_title(tag: :h2) do
              "Header with title"
            end
          end
          component.with_body { "Body" }
          component.with_footer { "Footer" }
        end
      end

      # @label Row colors
      # @snapshot
      def row_colors
        render(Primer::Beta::BorderBox.new) do |component|
          component.with_row(scheme: :default) { "Default" }
          component.with_row(scheme: :neutral) { "Neutral" }
          component.with_row(scheme: :info) { "Info" }
          component.with_row(scheme: :warning) { "Warning" }
        end
      end

      # Only the first and last element may round the corners of the box.
      # Toggle the slots to check that the rounding follows.
      #
      # @label Roundedness playground
      # @param header [Boolean] toggle
      # @param body [Boolean] toggle
      # @param rows [Boolean] toggle
      # @param footer [Boolean] toggle
      def roundedness_playground(header: true, body: false, rows: true, footer: false)
        render(Primer::Beta::BorderBox.new) do |component|
          component.with_header { "Header" } if coerce_bool(header)
          component.with_body { "Body" } if coerce_bool(body)
          if coerce_bool(rows)
            component.with_row { "Row one" }
            component.with_row { "Row two" }
            component.with_row { "Row three" }
          end
          component.with_footer { "Footer" } if coerce_bool(footer)
        end
      end

      # @!group Padding
      #
      # @label Default
      def padding_default
        render(Primer::Beta::BorderBox.new) do |component|
          component.with_header { "Header" }
          component.with_body { "Body" }
          component.with_row { "Row one" }
          component.with_row { "Row two" }
          component.with_row { "Row three" }
          component.with_footer { "Footer" }
        end
      end

      # @label Condensed
      # @snapshot
      def padding_condensed
        render(Primer::Beta::BorderBox.new(padding: :condensed)) do |component|
          component.with_header { "Header" }
          component.with_body { "Body" }
          component.with_row { "Row one" }
          component.with_row { "Row two" }
          component.with_row { "Row three" }
          component.with_footer { "Footer" }
        end
      end

      # @label Spacious
      # @snapshot
      def padding_spacious
        render(Primer::Beta::BorderBox.new(padding: :spacious)) do |component|
          component.with_header { "Header" }
          component.with_body { "Body" }
          component.with_row { "Row one" }
          component.with_row { "Row two" }
          component.with_row { "Row three" }
          component.with_footer { "Footer" }
        end
      end
      #
      # @!endgroup

      private

      # URL params are always strings; coerce to actual booleans before passing to the component.
      def coerce_bool(value)
        case value
        when true, false then value
        when "true" then true
        when "false" then false
        else false
        end
      end
    end
  end
end
