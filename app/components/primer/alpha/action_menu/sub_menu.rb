# typed: false
# frozen_string_literal: true

module Primer
  module Alpha
    class ActionMenu
      class SubMenu < Menu
        def initialize(menu_id:, overlay_arguments: {}, **system_arguments)
          overlay_arguments[:anchor] = "#{menu_id}-button"
          overlay_arguments[:anchor_side] = :outside_right
          super
        end
      end
    end
  end
end
