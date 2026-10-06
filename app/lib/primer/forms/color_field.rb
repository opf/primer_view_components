# frozen_string_literal: true

module Primer
  module Forms
    # :nodoc:
    class ColorField < BaseComponent
      delegate :builder, :form, to: :@input

      INPUT_WRAP_SIZE = {
        small: "FormControl-input-wrap--small",
        large: "FormControl-input-wrap--large"
      }.freeze

      def initialize(input:)
        @input = input

        @input.add_input_classes(
          "FormControl-input",
          "FormControl-monospace",
          Primer::Forms::Dsl::Input::SIZE_MAPPINGS[@input.size]
        )

        # The custom element is rendered inside FormControl rather than as its
        # tag, so that it survives `form_control: false` (as set by `multi`).
        #
        # Catalyst boolean attributes are true when present, whatever their
        # value, so false must render no attribute at all (nil), not "false".
        @element_arguments = {
          class: "ColorField",
          data: {
            blank: (@input.blank? ? "" : nil),
            empty: (@input.empty? ? "" : nil)
          }
        }

        wrap_classes = [
          "FormControl-input-wrap",
          "ColorField-wrap",
          INPUT_WRAP_SIZE[@input.size]
        ]
        wrap_classes << Primer::Forms::Dsl::Input::INPUT_WIDTH_MAPPINGS[@input.input_width] if @input.input_width

        @field_wrap_arguments = {
          class: class_names(wrap_classes),
          hidden: @input.hidden?
        }
      end

      # The native color input. Always rendered disabled: without the
      # controller nothing copies a picked color into the submitted text
      # input, so the controller is what enables it.
      def picker_tag
        @view_context.tag.input(
          type: :color,
          class: "ColorField-picker",
          value: @input.picker_value,
          disabled: true,
          aria: { label: @input.picker_label },
          data: {
            target: "primer-color-input.pickerElement",
            action: "input:primer-color-input#syncInput change:primer-color-input#commit"
          }
        )
      end
    end
  end
end
