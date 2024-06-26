# frozen_string_literal: true

module Primer
  module Beta
    # `ClipboardCopyButton` uses the `ClipboardCopy` component to copy text to the clipboard,
    # styled as a Primer button. It can be used wherever a button is desired, and works well
    # with components like `ButtonGroup`.
    # @accessibility
    #   This component has a built-in `aria-live` region that announces "Copied!" when the copy button is pressed.
    class ClipboardCopyButton < Primer::Beta::Button
      # @param system_arguments [Hash] The arguments accepted by <%= link_to_component(Primer::Beta::Button) %> and <%= link_to_component(Primer::Beta::ClipboardCopy) %>.
      def initialize(**system_arguments)
        super(**system_arguments, base_button_class: ClipboardCopyBaseButton)
      end
    end

    # Internal
    #
    # :nodoc:
    class ClipboardCopyBaseButton < Primer::Beta::BaseButton
      def call
        arguments = @system_arguments.except(:tag)
        render(Primer::Beta::ClipboardCopy.new(**arguments))
      end
    end
  end
end
