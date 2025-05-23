# frozen_string_literal: true

# Setup Playground to use all available component props
# Setup Features to use individual component props and combinations

module Primer
  module OpenProject
    # @label FeedbackDialog
    class FeedbackDialogPreview < ViewComponent::Preview
      # @label Default
      # @snapshot interactive
      def default
        render(Primer::OpenProject::FeedbackDialog.new(title: "Success dialog")) do |dialog|
          dialog.with_show_button { "Click me" }
          dialog.with_feedback_message do |message|
            message.with_heading(tag: :h2) { "Success" }
            message.with_description { "Great! Everything worked well." }
          end
        end
      end

      # @label Playground
      # @param icon [Symbol] octicon
      # @param icon_color [Symbol] select [default, muted, subtle, accent, success, attention, severe, danger, open, closed, done, sponsors, on_emphasis, inherit]
      # @param loading_state [Boolean] toggle
      # @param show_description toggle
      # @param show_additional_details toggle
      # @param custom_footer toggle
      def playground(icon: :"check-circle", icon_color: :success, loading_state: false, show_description: true, show_additional_details: false, custom_footer: false)
        render_with_template(locals: { icon: icon,
                                       icon_color: icon_color,
                                       loading_state: loading_state,
                                       show_description: show_description,
                                       show_additional_details: show_additional_details,
                                       custom_footer: custom_footer })
      end

      # @label With additional details
      def with_additional_details
        render_with_template(locals: {})
      end

      # @label With custom icon
      def custom_icon
        render(Primer::OpenProject::FeedbackDialog.new(title: "Error message")) do |dialog|
          dialog.with_show_button { "Click me" }
          dialog.with_feedback_message(icon_arguments: { icon: :"x-circle", color: :danger }) do |message|
            message.with_heading(tag: :h2) { "Ups, something went wrong" }
            message.with_description { "Please try again or contact your administrator if the issue persists." }
          end
        end
      end

      # @label With custom footer
      def with_custom_footer
        render_with_template(locals: {})
      end

      # @label With loading spinner
      def loading_spinner
        render(Primer::OpenProject::FeedbackDialog.new(title: "Waiting...")) do |dialog|
          dialog.with_show_button { "Click me" }
          dialog.with_feedback_message(loading: true) do |message|
            message.with_heading(tag: :h2) { "Please wait, your request is being processed." }
          end
        end
      end
    end
  end
end
