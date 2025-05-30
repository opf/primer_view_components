# frozen_string_literal: true

module Primer
  module OpenProject
    class FilterableTreeView
      # A `FilterableTreeView` sub-tree node.
      #
      # This component is part of the <%= link_to_component(Primer::OpenProject::FilterableTreeView) %> component and
      # should not be used directly.
      class SubTree < Primer::OpenProject::TreeView::SubTree
        def with_sub_tree(**system_arguments, &block)
          super(
            sub_tree_component_klass: self.class,
            **system_arguments,
            select_variant: :multiple,
            select_strategy: :self,
            &block
          )
        end

        def with_leaf(**system_arguments, &block)
          super(
            **system_arguments,
            select_variant: :multiple,
            &block
          )
        end
      end
    end
  end
end
