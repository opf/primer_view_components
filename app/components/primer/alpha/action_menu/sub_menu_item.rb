# frozen_string_literal: true

module Primer
  module Alpha
    class ActionMenu
      class SubMenuItem < ::Primer::Alpha::ActionList::Item
        delegate :with_item, :with_sub_menu_item, to: :@sub_menu

        def initialize(content_arguments: {}, **system_arguments)
          @menu_id = self.class.generate_id
          @sub_menu = SubMenu.new(**system_arguments, menu_id: @menu_id)

          system_arguments[:id] = "#{@menu_id}-button"

          content_arguments[:tag] = :button
          content_arguments[:popovertarget] = "#{@sub_menu.menu_id}-overlay"

          content_arguments[:aria] = merge_aria(
            content_arguments, {
              aria: {
                controls: "#{@sub_menu.menu_id}-list",
                haspopup: true
              }
            }
          )

          super
        end
      end
    end
  end
end
