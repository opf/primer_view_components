# typed: false
# frozen_string_literal: true

module Primer
  module Alpha
    class ActionMenu
      class PrimaryMenu < Menu
        DEFAULT_ANCHOR_ALIGN = :start
        DEFAULT_ANCHOR_SIDE = :outside_bottom

        attr_reader :dynamic_label, :dynamic_label_prefix

        # @param dynamic_label [Boolean] Whether or not to display the text of the currently selected item in the show button.
        # @param dynamic_label_prefix [String] If provided, the prefix is prepended to the dynamic label and displayed in the show button.
        # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>.
        def initialize(
          anchor_align: DEFAULT_ANCHOR_ALIGN,
          anchor_side: DEFAULT_ANCHOR_SIDE,
          dynamic_label: false,
          dynamic_label_prefix: nil,
          **system_arguments
        )
          @dynamic_label = dynamic_label
          @dynamic_label_prefix = dynamic_label_prefix

          system_arguments[:list_arguments] ||= {}

          system_arguments[:list_arguments][:data] = merge_data(
            system_arguments[:list_arguments],
            { data: { target: "action-menu.list" } }
          )

          super(
            anchor_align: anchor_align,
            anchor_side: anchor_side,
            **system_arguments
          )
        end

        # @!parse
        #   # Button to activate the menu.
        #   #
        #   # @param system_arguments [Hash] The arguments accepted by <%= link_to_component(Primer::Alpha::Overlay) %>'s `show_button` slot.
        #   renders_one(:show_button)

        # Button to activate the menu.
        #
        # @param system_arguments [Hash] The arguments accepted by <%= link_to_component(Primer::Alpha::Overlay) %>'s `show_button` slot.
        def with_show_button(**system_arguments, &block)
          @overlay.with_show_button(**system_arguments, id: "#{@menu_id}-button", controls: "#{@menu_id}-list") do |button|
            evaluate_block(button, &block)
          end
        end

        def with_sub_menu_item(**system_arguments, &block)
          if select_variant == :single
            raise ArgumentError, "Sub-menus are not supported in single-select mode"
          end

          super
        end
      end
    end
  end
end
