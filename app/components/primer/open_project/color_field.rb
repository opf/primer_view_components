# frozen_string_literal: true

module Primer
  module OpenProject
    ColorField = Primer::FormComponents.from_input(Primer::Forms::Dsl::ColorFieldInput)

    # Color fields are single-line text inputs for hex color codes, paired with a native color
    # picker that doubles as a swatch. They render an `<input type="text">`, which is submitted,
    # and an unnamed `<input type="color">`, which is not. The field can therefore be left blank.
    #
    # Typed text is previewed in the swatch as soon as it is a valid three- or six-digit hex code
    # and is rewritten to uppercase `#RRGGBB` when the field loses focus. Invalid text is left
    # alone; validate it on the server.
    #
    # Space color fields through their container, such as a form group or a stack. As with text
    # fields, system arguments are applied to the text input itself, so a margin passed to the
    # field moves the input away from its swatch.
    #
    # @form_usage
    #   class ExampleForm < ApplicationForm
    #     form do |example_form|
    #       example_form.color_field(attributes)
    #     end
    #   end
    class ColorField < Primer::Component
      status :open_project

      # @!method initialize
      #
      # @macro form_size_arguments
      # @macro form_full_width_arguments
      # @macro form_input_arguments
      # @macro form_input_width_arguments
      #
      # @param maxlength [Integer] Maximum number of characters the text input accepts. Defaults to 7, the length of `#RRGGBB`.
      # @param placeholder [String] Placeholder text. It is not previewed in the swatch, which stays empty while the field is blank.
      # @param picker_label [String] Accessible name of the native color picker. Defaults to `I18n.t("color_field.picker_label", label: label)`, or to `I18n.t("color_field.picker_label_generic")` when there is no label.
    end
  end
end
