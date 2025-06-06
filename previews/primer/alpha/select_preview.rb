# frozen_string_literal: true

module Primer
  module Alpha
    # @label Select
    class SelectPreview < ViewComponent::Preview
      # @label Playground
      #
      # @param name text
      # @param id text
      # @param label text
      # @param caption text
      # @param required toggle
      # @param multiple toggle
      # @param visually_hide_label toggle
      # @param size [Symbol] select [small, medium, large]
      # @param full_width toggle
      # @param disabled toggle
      # @param invalid toggle
      # @param validation_message text
      # @param input_width [Symbol] select [auto, xsmall, small, medium, large, xlarge, xxlarge]
      def playground(
        name: "my-select-list",
        id: "my-select-list",
        label: "Favorite place to visit",
        caption: "They're all good",
        required: false,
        multiple: false,
        visually_hide_label: false,
        size: Primer::Forms::Dsl::Input::DEFAULT_SIZE.to_s,
        full_width: true,
        disabled: false,
        invalid: false,
        validation_message: nil,
        input_width: nil
      )
        system_arguments = {
          name: name,
          id: id,
          label: label,
          caption: caption,
          required: required,
          multiple: multiple,
          visually_hide_label: visually_hide_label,
          size: size,
          full_width: full_width,
          disabled: disabled,
          invalid: invalid,
          validation_message: validation_message,
          input_width: input_width
        }

        render(Primer::Alpha::Select.new(**system_arguments)) do |component|
          component.option(label: "Lopez Island", value: "lopez")
          component.option(label: "Shaw Island", value: "shaw")
          component.option(label: "Orcas Island", value: "orcas")
          component.option(label: "San Juan Island", value: "san_juan")
        end
      end

      # @label Default
      def default
        render(Primer::Alpha::Select.new(name: "my-select-list", label: "Favorite place to visit")) do |component|
          component.option(label: "Lopez Island", value: "lopez")
          component.option(label: "Shaw Island", value: "shaw")
          component.option(label: "Orcas Island", value: "orcas")
          component.option(label: "San Juan Island", value: "san_juan")
        end
      end

      # @!group Options
      #
      # @label With caption
      # @snapshot
      def with_caption
        render(Primer::Alpha::Select.new(caption: "With a caption", name: "my-select-list-1", label: "Favorite place to visit")) do |component|
          component.option(label: "Lopez Island", value: "lopez")
          component.option(label: "Shaw Island", value: "shaw")
          component.option(label: "Orcas Island", value: "orcas")
          component.option(label: "San Juan Island", value: "san_juan")
        end
      end

      # @label Visually hidden label
      # @snapshot
      def visually_hide_label
        render(Primer::Alpha::Select.new(visually_hide_label: true, name: "my-select-list-2", label: "Favorite place to visit")) do |component|
          component.option(label: "Lopez Island", value: "lopez")
          component.option(label: "Shaw Island", value: "shaw")
          component.option(label: "Orcas Island", value: "orcas")
          component.option(label: "San Juan Island", value: "san_juan")
        end
      end

      # @label Full width
      # @snapshot
      def full_width
        render(Primer::Alpha::Select.new(full_width: true, name: "my-select-list-3", label: "Favorite place to visit")) do |component|
          component.option(label: "Lopez Island", value: "lopez")
          component.option(label: "Shaw Island", value: "shaw")
          component.option(label: "Orcas Island", value: "orcas")
          component.option(label: "San Juan Island", value: "san_juan")
        end
      end

      # @label Not full width
      # @snapshot
      def not_full_width
        render(Primer::Alpha::Select.new(full_width: false, name: "my-select-list-4", label: "Favorite place to visit")) do |component|
          component.option(label: "Lopez Island", value: "lopez")
          component.option(label: "Shaw Island", value: "shaw")
          component.option(label: "Orcas Island", value: "orcas")
          component.option(label: "San Juan Island", value: "san_juan")
        end
      end

      # @label Disabled
      # @snapshot
      def disabled
        render(Primer::Alpha::Select.new(disabled: true, name: "my-select-list-5", label: "Favorite place to visit")) do |component|
          component.option(label: "Lopez Island", value: "lopez")
          component.option(label: "Shaw Island", value: "shaw")
          component.option(label: "Orcas Island", value: "orcas")
          component.option(label: "San Juan Island", value: "san_juan")
        end
      end

      # @label Invalid
      # @snapshot
      def invalid
        render(Primer::Alpha::Select.new(invalid: true, name: "my-select-list-6", label: "Favorite place to visit")) do |component|
          component.option(label: "Lopez Island", value: "lopez")
          component.option(label: "Shaw Island", value: "shaw")
          component.option(label: "Orcas Island", value: "orcas")
          component.option(label: "San Juan Island", value: "san_juan")
        end
      end

      # @label With validation message
      # @snapshot
      def with_validation_message
        render(Primer::Alpha::Select.new(validation_message: "An error occurred!", name: "my-select-list", label: "Favorite place to visit")) do |component|
          component.option(label: "Lopez Island", value: "lopez")
          component.option(label: "Shaw Island", value: "shaw")
          component.option(label: "Orcas Island", value: "orcas")
          component.option(label: "San Juan Island", value: "san_juan")
        end
      end
      #
      # @!endgroup
    end
  end
end
