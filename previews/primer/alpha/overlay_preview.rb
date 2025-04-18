# frozen_string_literal: true

module Primer
  module Alpha
    # @label Overlay
    class OverlayPreview < ViewComponent::Preview
      # @label Playground
      #
      # @param title [String] text
      # @param subtitle [String] text
      # @param role [Symbol] select [dialog, menu]
      # @param size [Symbol] select [auto, small, medium, medium_portrait, large, xlarge]
      # @param padding [Symbol] select [normal, condensed, none]
      # @param anchor_align [Symbol] select [start, center, end]
      # @param anchor_offset [Symbol] select [normal, spacious]
      # @param anchor_side [Symbol] select [inside_top, inside_bottom, inside_left, inside_right, inside_center, outside_top, outside_bottom, outside_left, outside_right]
      # @param allow_out_of_bounds [Boolean] toggle
      # @param visually_hide_title [Boolean] toggle
      #
      # @param header_size [Symbol] select [medium, large]
      # @param button_text [String] text
      # @param body_text [String] text
      # @param icon [Symbol] octicon
      def playground(title: "Test Overlay", subtitle: nil, role: :dialog, size: :auto, padding: :normal, anchor_align: :center, anchor_offset: :normal, anchor_side: :outside_bottom, allow_out_of_bounds: false, visually_hide_title: false, header_size: :medium, button_text: "Show Overlay", body_text: "", icon: :none)
        render(Primer::Alpha::Overlay.new(
                 title: title,
                 subtitle: subtitle,
                 role: role,
                 size: size,
                 padding: padding,
                 anchor_align: anchor_align,
                 anchor_offset: anchor_offset,
                 anchor_side: anchor_side,
                 allow_out_of_bounds: allow_out_of_bounds,
                 visually_hide_title: visually_hide_title
               )) do |d|
          d.with_header(title: title, size: header_size)
          if icon.present? && (icon != :none)
            d.with_show_button(icon: icon, "aria-label": icon.to_s)
          else
            d.with_show_button { button_text }
          end
          d.with_body { body_text }
        end
      end

      # @label Default
      #
      # @param title [String] text
      # @param subtitle [String] text
      # @param role [Symbol] select [dialog, menu]
      # @param size [Symbol] select [auto, small, medium, medium_portrait, large, xlarge]
      # @param padding [Symbol] select [normal, condensed, none]
      # @param anchor_align [Symbol] select [start, center, end]
      # @param anchor_side [Symbol] select [inside_top, inside_bottom, inside_left, inside_right, inside_center, outside_top, outside_bottom, outside_left, outside_right]
      # @param allow_out_of_bounds [Boolean] toggle
      # @param visually_hide_title [Boolean] toggle
      #
      # @param header_size [Symbol] select [medium, large]
      # @param button_text [String] text
      # @param body_text [String] text
      def default(title: "Test Overlay", subtitle: nil, role: :dialog, size: :auto, padding: :normal, anchor_align: :center, anchor_side: :outside_bottom, allow_out_of_bounds: false, visually_hide_title: false, header_size: :medium, button_text: "Show Overlay", body_text: "")
        render(Primer::Alpha::Overlay.new(
                 title: title,
                 subtitle: subtitle,
                 role: role,
                 size: size,
                 padding: padding,
                 anchor_align: anchor_align,
                 anchor_side: anchor_side,
                 allow_out_of_bounds: allow_out_of_bounds,
                 visually_hide_title: visually_hide_title
               )) do |d|
          d.with_header(title: title, size: header_size)
          d.with_show_button { button_text }
          d.with_body { body_text }
        end
      end

      # @label Menu No Header
      #
      # @param size [Symbol] select [auto, small, medium, medium_portrait, large, xlarge]
      # @param padding [Symbol] select [normal, condensed, none]
      # @param anchor_align [Symbol] select [start, center, end]
      # @param anchor_side [Symbol] select [inside_top, inside_bottom, inside_left, inside_right, inside_center, outside_top, outside_bottom, outside_left, outside_right]
      # @param allow_out_of_bounds [Boolean] toggle
      #
      # @param button_text [String] text
      # @param body_text [String] text
      def menu_no_header(size: :auto, padding: :normal, anchor_align: :center, anchor_side: :outside_bottom, allow_out_of_bounds: false, button_text: "Show Overlay Menu", body_text: "This is a menu")
        render(Primer::Alpha::Overlay.new(
                 title: "Menu",
                 role: :menu,
                 size: size,
                 padding: padding,
                 anchor_align: anchor_align,
                 anchor_side: anchor_side,
                 allow_out_of_bounds: allow_out_of_bounds
               )) do |d|
          d.with_show_button { button_text }
          d.with_body { body_text }
        end
      end

      # @label Middle Of Page
      #
      # @param title [String] text
      # @param subtitle [String] text
      # @param role [Symbol] select [dialog, menu]
      # @param size [Symbol] select [auto, small, medium, medium_portrait, large, xlarge]
      # @param anchor_align [Symbol] select [start, center, end]
      # @param anchor_side [Symbol] select [inside_top, inside_bottom, inside_left, inside_right, inside_center, outside_top, outside_bottom, outside_left, outside_right]
      # @param allow_out_of_bounds [Boolean] toggle
      # @param visually_hide_title [Boolean] toggle
      #
      # @param header_size [Symbol] select [medium, large]
      # @param button_text [String] text
      # @param body_text [String] text
      def middle_of_page(title: "Test Overlay", subtitle: nil, role: :dialog, size: :auto, placement: :anchored, anchor_align: :center, anchor_side: :outside_bottom, allow_out_of_bounds: false, visually_hide_title: false, header_size: :medium, button_text: "Show Overlay", body_text: "")
        render_with_template(locals: {
                               title: title,
                               subtitle: subtitle,
                               role: role,
                               size: size,
                               placement: placement,
                               anchor_align: anchor_align,
                               anchor_side: anchor_side,
                               allow_out_of_bounds: allow_out_of_bounds,
                               visually_hide_title: visually_hide_title,
                               header_size: header_size,
                               button_text: button_text,
                               body_text: body_text
                             })
      end

      # @label Middle Of Page with relative container
      #
      # @param title [String] text
      # @param subtitle [String] text
      # @param role [Symbol] select [dialog, menu]
      # @param size [Symbol] select [auto, small, medium, medium_portrait, large, xlarge]
      # @param anchor_align [Symbol] select [start, center, end]
      # @param anchor_side [Symbol] select [inside_top, inside_bottom, inside_left, inside_right, inside_center, outside_top, outside_bottom, outside_left, outside_right]
      # @param allow_out_of_bounds [Boolean] toggle
      # @param visually_hide_title [Boolean] toggle
      #
      # @param header_size [Symbol] select [medium, large]
      # @param button_text [String] text
      # @param body_text [String] text
      def middle_of_page_with_relative_container(title: "Test Overlay", subtitle: nil, role: :dialog, size: :auto, placement: :anchored, anchor_align: :center, anchor_side: :outside_bottom, allow_out_of_bounds: false, visually_hide_title: false, header_size: :medium, button_text: "Show Overlay", body_text: "")
        render_with_template(locals: {
                               title: title,
                               subtitle: subtitle,
                               role: role,
                               size: size,
                               placement: placement,
                               anchor_align: anchor_align,
                               anchor_side: anchor_side,
                               allow_out_of_bounds: allow_out_of_bounds,
                               visually_hide_title: visually_hide_title,
                               header_size: header_size,
                               button_text: button_text,
                               body_text: body_text
                             })
      end

      def in_a_sticky_container
        render_with_template(locals: {})
      end
    end
  end
end
