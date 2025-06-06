# frozen_string_literal: true

require_relative "../url_helpers"

module Primer
  module Alpha
    # @label Toggle Switch
    class ToggleSwitchPreview < ViewComponent::Preview
      include ActionView::Helpers::FormTagHelper

      def playground
        render(Primer::Alpha::ToggleSwitch.new(src: UrlHelpers.primer_view_components.toggle_switch_index_path))
      end

      # @snapshot
      def default
        render(Primer::Alpha::ToggleSwitch.new(src: UrlHelpers.primer_view_components.toggle_switch_index_path))
      end

      # @snapshot
      def checked
        render(Primer::Alpha::ToggleSwitch.new(src: UrlHelpers.primer_view_components.toggle_switch_index_path, checked: true))
      end

      # @snapshot
      def disabled
        render(Primer::Alpha::ToggleSwitch.new(src: UrlHelpers.primer_view_components.toggle_switch_index_path, enabled: false))
      end

      # @snapshot
      def checked_disabled
        render(Primer::Alpha::ToggleSwitch.new(src: UrlHelpers.primer_view_components.toggle_switch_index_path, checked: true, enabled: false))
      end

      # @snapshot
      def small
        render(Primer::Alpha::ToggleSwitch.new(src: UrlHelpers.primer_view_components.toggle_switch_index_path, size: :small))
      end

      # @snapshot
      def with_status_label_position_end
        render(Primer::Alpha::ToggleSwitch.new(src: UrlHelpers.primer_view_components.toggle_switch_index_path, status_label_position: :end))
      end

      # @snapshot
      def with_a_bad_src
        render(Primer::Alpha::ToggleSwitch.new(src: "/foo"))
      end

      def with_no_src
        render(Primer::Alpha::ToggleSwitch.new)
      end

      def with_csrf_token
        render(Primer::Alpha::ToggleSwitch.new(src: UrlHelpers.primer_view_components.toggle_switch_index_path))
      end

      def with_bad_csrf_token
        render(Primer::Alpha::ToggleSwitch.new(src: UrlHelpers.primer_view_components.toggle_switch_index_path, csrf_token: "i_am_a_criminal"))
      end

      def with_turbo
        render(Primer::Alpha::ToggleSwitch.new(src: UrlHelpers.primer_view_components.toggle_switch_index_path, turbo: true))
      end

      def with_autofocus
        render(Primer::Alpha::ToggleSwitch.new(src: UrlHelpers.primer_view_components.toggle_switch_index_path, autofocus: true))
      end
    end
  end
end
