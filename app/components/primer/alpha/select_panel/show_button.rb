# frozen_string_literal: true

module Primer
  module Alpha
    class SelectPanel
      # This component is part of <%= link_to_component(Primer::Alpha::SelectPanel) %> and should not be
      # used as a standalone component.
      class ShowButton < Primer::Component
        def initialize(dynamic_label_prefix: nil, **button_args)
          @dynamic_label_prefix = dynamic_label_prefix
          @button_args = button_args
        end

        def call
          leading_visual = @button_args.delete(:leading_visual)
          trailing_visual = @button_args.delete(:trailing_visual)
          button = Primer::Beta::Button.new(**@button_args)
          button.with_leading_visual_icon(**leading_visual) if leading_visual&.key?(:icon)
          button.with_trailing_visual_icon(**trailing_visual) if trailing_visual&.key?(:icon)

          prefix_span = @dynamic_label_prefix.present? ? content_tag(:span, "#{@dynamic_label_prefix} ", class: "color-fg-muted", data: { target: "select-panel.labelPrefix" }) : nil
          counter = render(Primer::Beta::Counter.new(
            count: 0,
            hidden: true,
            data: { target: "select-panel.counterLabel" }
          ))
          render(button) do
            safe_join([prefix_span, counter].compact)
          end
        end
      end
    end
  end
end
