# frozen_string_literal: true

module Primer
  module OpenProject
    # @label ColorField
    class ColorFieldPreview < ViewComponent::Preview
      # @label Playground
      #
      # @param label text
      # @param value text
      # @param placeholder text
      # @param caption text
      # @param size [Symbol] select [small, medium, large]
      # @param input_width [Symbol] select [auto, xsmall, small, medium, large, xlarge, xxlarge]
      # @param full_width toggle
      # @param visually_hide_label toggle
      # @param required toggle
      # @param disabled toggle
      # @param readonly toggle
      # @param validation_message text
      def playground(
        label: "Primary color",
        value: "#1A67A3",
        placeholder: "#1A67A3",
        caption: nil,
        size: :medium,
        input_width: :medium,
        full_width: true,
        visually_hide_label: false,
        required: false,
        disabled: false,
        readonly: false,
        validation_message: nil
      )
        render(
          Primer::OpenProject::ColorField.new(
            name: "color",
            id: "color",
            label: label,
            value: value,
            placeholder: placeholder,
            caption: caption.presence,
            size: size.to_sym,
            input_width: input_width.to_sym,
            full_width: full_width,
            visually_hide_label: visually_hide_label,
            required: required,
            disabled: disabled,
            readonly: readonly,
            validation_message: validation_message.presence
          )
        )
      end

      # @label Default
      # @snapshot
      def default
        render(Primer::OpenProject::ColorField.new(name: "color", id: "color", label: "Primary color", value: "#1A67A3"))
      end

      # @!group States
      #
      # @label Blank with placeholder
      # @snapshot
      def blank_with_placeholder
        render(Primer::OpenProject::ColorField.new(name: "color", id: "color", label: "Primary color", placeholder: "#1A67A3"))
      end

      # @label Blank without placeholder
      # @snapshot
      def blank_without_placeholder
        render(Primer::OpenProject::ColorField.new(name: "color", id: "color", label: "Primary color"))
      end

      # @label Disabled
      # @snapshot
      def disabled
        render(Primer::OpenProject::ColorField.new(name: "color", id: "color", label: "Primary color", value: "#1A67A3", disabled: true))
      end

      # @label Read-only
      # @snapshot
      def readonly
        render(Primer::OpenProject::ColorField.new(name: "color", id: "color", label: "Primary color", value: "#1A67A3", readonly: true))
      end

      # @label Invalid
      # @snapshot
      def invalid
        render(Primer::OpenProject::ColorField.new(name: "color", id: "color", label: "Primary color", value: "zzz", validation_message: "Hex code is invalid"))
      end
      #
      # @!endgroup

      # @label In a form
      def in_form; end

      # @label Multiple fields
      def multiple; end

      # @label In a multi input
      def in_multi; end
    end
  end
end
