# typed: false
# frozen_string_literal: true

module Primer
  module Alpha
    class ActionMenu
      class SubMenu < Menu
        DEFAULT_ANCHOR_ALIGN = :start
        DEFAULT_ANCHOR_SIDE = :outside_right

        def initialize(
          menu_id:,
          anchor_align: DEFAULT_ANCHOR_ALIGN,
          anchor_side: DEFAULT_ANCHOR_SIDE,
          overlay_arguments: {},
          **system_arguments
        )
          overlay_arguments[:anchor] = "#{menu_id}-button"
          super
        end

        def with_sub_menu_item(**system_arguments, &block)
          super(
            anchor_align: anchor_align, # carry over to sub-menus
            anchor_side: anchor_side, # carry over to sub-menus
            **system_arguments,
            &block
          )
        end
      end
    end
  end
end
