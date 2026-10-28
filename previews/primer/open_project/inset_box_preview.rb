# frozen_string_literal: true

module Primer
  module OpenProject
    # @label InsetBox
    class InsetBoxPreview < ViewComponent::Preview
      # @label Playground
      # @param border [Boolean] toggle
      # @param scheme [Symbol] select [default, info, warning, danger, success]
      # @param show_title [Boolean] toggle
      # @param show_icon [Boolean] toggle
      # @param show_actions [Boolean] toggle
      # @param show_clipboard_copy_button [Boolean] toggle
      def playground(border: true, scheme: :default, show_title: true, show_icon: false, show_actions: false, show_clipboard_copy_button: false)
        render(Primer::OpenProject::InsetBox.new(border: border, scheme: scheme)) do |component|
          component.with_title_icon(icon: :info) if show_icon
          component.with_title { "Title" } if show_title
          component.with_clipboard_copy_button(value: "Copyable value", "aria-label": "Copy value") if show_clipboard_copy_button

          component.with_action_button(scheme: :default) { "Action" } if show_actions

          "This is the content of the inset box."
        end
      end

      # @label Default
      # @snapshot
      def default
        render(Primer::OpenProject::InsetBox.new) do |component|
          component.with_title { "Title" }
          "This is the content of the inset box."
        end
      end

      # @label With scheme
      # @snapshot
      def with_scheme
        render(Primer::OpenProject::InsetBox.new(scheme: :warning)) do |component|
          component.with_title { "Watch out" }
          "This is a warning message."
        end
      end

      # @label With icon
      # @snapshot
      def with_icon
        render(Primer::OpenProject::InsetBox.new) do |component|
          component.with_title_icon(icon: :info)
          component.with_title { "Title" }
          "This is the content of the inset box."
        end
      end

      # @label With clipboard copy button
      # @snapshot
      def with_clipboard_copy_button
        render(Primer::OpenProject::InsetBox.new) do |component|
          component.with_title { "Title" }
          component.with_clipboard_copy_button(value: "Copyable value", "aria-label": "Copy value")
          "This is the content of the inset box."
        end
      end

      # @label With actions
      # @snapshot
      def with_actions
        render(Primer::OpenProject::InsetBox.new) do |component|
          component.with_title { "Title" }
          component.with_action_button { "Action" }
          "This is the content of the inset box."
        end
      end

      # @label Without border
      # @snapshot
      def without_border
        render(Primer::OpenProject::InsetBox.new(border: false)) do |component|
          component.with_title { "Title" }
          "This is the content of the inset box."
        end
      end
    end
  end
end
