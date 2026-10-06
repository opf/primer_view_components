# frozen_string_literal: true

module Primer
  module Forms
    module Dsl
      # :nodoc:
      class ColorFieldInput < Input
        HEX_FORMAT = /\A#?(\h{3}|\h{6})\z/

        attr_reader :name, :label, :picker_label

        # Returns the canonical uppercase `#RRGGBB` form of the given text, or
        # `nil` if it is not a three- or six-digit hex color.
        def self.parse_hex(text)
          match = HEX_FORMAT.match(text.to_s.strip)
          return nil unless match

          digits = match[1]
          digits = digits.gsub(/\h/) { |digit| digit * 2 } if digits.length == 3

          "##{digits.upcase}"
        end

        def initialize(name:, label:, **system_arguments)
          @name = name
          @label = label
          @picker_label = system_arguments.delete(:picker_label) || default_picker_label

          caller_target = system_arguments.dig(:data, :target)
          caller_action = system_arguments.dig(:data, :action)

          super(**system_arguments)

          input_arguments[:autocomplete] ||= "off"
          # The longest text that parses, `#RRGGBB`.
          input_arguments[:maxlength] ||= 7

          add_input_data(:target, "primer-color-input.inputElement #{caller_target}".strip)
          add_input_data(
            :action,
            "input:primer-color-input#syncPicker change:primer-color-input#normalize " \
            "paste:primer-color-input#trimPaste #{caller_action}".strip
          )

          yield(self) if block_given?
        end

        # The value Rails will render into the text input: the explicit `value:`
        # argument if given, otherwise the attribute of the form's model object.
        def current_value
          builder.text_field_attributes(
            name, object: builder.object, **input_arguments.slice(:value)
          )["value"]
        end

        def blank?
          current_value.to_s.strip.empty?
        end

        # The color the native picker starts with: the current value, or the
        # placeholder while the field is blank. `nil` if neither is a hex color.
        def picker_value
          return @picker_value if defined?(@picker_value)

          @picker_value = self.class.parse_hex(blank? ? input_arguments[:placeholder] : current_value)
        end

        # Whether there is no color to show in the swatch at all.
        def empty?
          picker_value.nil?
        end

        def to_component
          ColorField.new(input: self)
        end

        def type
          :color_field
        end

        def focusable?
          true
        end

        private

        # Inputs inside `multi` have no label of their own.
        def default_picker_label
          return I18n.t("color_field.picker_label_generic") if label.blank?

          I18n.t("color_field.picker_label", label: label)
        end
      end
    end
  end
end
