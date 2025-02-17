# frozen_string_literal: true

module Primer
  module OpenProject
    class DangerDialog
      # This component is part of `Primer::OpenProject::DangerDialog`
      # and should not be used as a standalone component.
      class ConfirmationCheckBox < Primer::Component
        status :open_project

        # @param confirm_button_id [String] The id of the confirm button.
        # @param check_box_id [String] The id of the check_box input.
        # @param check_box_name [String] The name of the check_box input.
        # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
        def initialize(confirm_button_id:, check_box_id: self.class.generate_id, check_box_name:, **system_arguments)
          @system_arguments = deny_tag_argument(**system_arguments)
          @system_arguments[:tag] = :div
          @system_arguments[:classes] = class_names(
            system_arguments[:classes],
            "DangerDialog-confirmationCheckBox"
          )

          @check_box_arguments = {}
          @check_box_arguments[:id] = check_box_id
          @check_box_arguments[:name] = check_box_name
          @check_box_arguments[:data] = {
            target: "danger-dialog-form-helper.checkbox",
            action: "change:danger-dialog-form-helper#toggle"
          }
          @check_box_arguments[:tabindex] = 0
          @check_box_arguments[:aria] = merge_aria(@check_box_arguments, { aria: { controls: confirm_button_id } })
        end

        def call
          render(Primer::BaseComponent.new(**@system_arguments)) do
            render(Primer::Alpha::CheckBox.new(**@check_box_arguments.merge(label: trimmed_content)))
          end
        end

        def render?
          raise ArgumentError, "ConfirmationCheckBox requires a content block" unless trimmed_content.present?

          true
        end
      end
    end
  end
end
