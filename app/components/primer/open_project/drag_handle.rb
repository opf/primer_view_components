# frozen_string_literal: true

module Primer
  module OpenProject
    # Add a general description of component here
    # Add additional usage considerations or best practices that may aid the user to use the component correctly.
    # @accessibility Add any accessibility considerations
    class DragHandle < Primer::Component
      status :open_project

      DEFAULT_SIZE = Primer::Beta::Octicon::SIZE_DEFAULT
      SIZE_OPTIONS = Primer::Beta::Octicon::SIZE_OPTIONS

      # @param size [Symbol] <%= one_of(Primer::OpenProject::DragHandle::SIZE_OPTIONS) %>
      # @param label [String] String that can be read by assistive technology. A label should be short and concise. See the accessibility section for more information.
      # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
      def initialize(size: Primer::OpenProject::DragHandle::DEFAULT_SIZE, label: I18n.t("drag_handle.button_drag"), **system_arguments)
        @system_arguments = deny_tag_argument(**system_arguments)

        deny_aria_key(
          :label,
          "instead of `aria-label`, include `label` on the component initializer.",
          **@system_arguments
        )
        @system_arguments[:tag] = "div"
        @system_arguments[:role] = "button"
        @system_arguments[:tabindex] = 0
        @system_arguments[:classes] = class_names(
          @system_arguments[:classes],
          "DragHandle"
        )

        @system_arguments[:aria] = merge_aria(
          @system_arguments,
          aria: {
            label: label,
            pressed: false
          }
        )

        @size = fetch_or_fallback(Primer::OpenProject::DragHandle::SIZE_OPTIONS, size, Primer::OpenProject::DragHandle::DEFAULT_SIZE)
      end
    end
  end
end
