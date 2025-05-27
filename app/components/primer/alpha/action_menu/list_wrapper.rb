# frozen_string_literal: true

module Primer
  module Alpha
    class ActionMenu
      # This component is part of <%= link_to_component(Primer::Alpha::ActionMenu) %> and should not be
      # used as a standalone component.
      class ListWrapper < Primer::Alpha::ActionList
        # @!parse
        #   # Adds an item to the menu.
        #   #
        #   # @param system_arguments [Hash] The arguments accepted by <%= link_to_component(Primer::Alpha::ActionList) %>'s `item` slot.
        #   def with_item(**system_arguments)
        #   end
        #
        #   # Adds an avatar item to the menu.
        #   #
        #   # @param system_arguments [Hash] The arguments accepted by <%= link_to_component(Primer::Alpha::ActionList) %>'s `item` slot.
        #   def with_avatar_item(**system_arguments)
        #   end
        #
        #   # Adds a divider to the list. Dividers visually separate items.
        #   #
        #   # @param system_arguments [Hash] The arguments accepted by <%= link_to_component(Primer::Alpha::ActionList::Divider) %>.
        #   def with_divider(**system_arguments)
        #   end
        #
        #   # Adds a group to the menu. Groups are a logical set of items with a header.
        #   #
        #   # @param system_arguments [Hash] The arguments accepted by <%= link_to_component(Primer::Alpha::ActionMenu::Group) %>.
        #   def with_group(**system_arguments)
        #   end
        #
        #   # Gets the list of configured menu items, which includes regular items, avatar items, groups, and dividers.
        #   #
        #   # @return [Array<ViewComponent::Slot>]
        #   def items
        #   end

        add_polymorphic_slot_type(
          slot_name: :items,
          type: :group,
          callable: lambda { |**system_arguments|
            Primer::Alpha::ActionMenu::Group.new(
              **system_arguments,
              role: :group,
              select_variant: @select_variant
            )
          }
        )

        # @param menu_id [String] ID of the parent menu.
        # @param system_arguments [Hash] The arguments accepted by <%= link_to_component(Primer::Alpha::ActionList) %>
        def initialize(menu_id:, **system_arguments)
          @menu_id = menu_id

          system_arguments[:aria] = merge_aria(
            system_arguments,
            { aria: { labelledby: "#{@menu_id}-button" } }
          )

          system_arguments[:role] = :menu
          system_arguments[:scheme] = :inset
          system_arguments[:id] = "#{@menu_id}-list"

          super(**system_arguments)
        end
      end
    end
  end
end
