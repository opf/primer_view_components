# frozen_string_literal: true

require "components/test_helper"

module Primer
  module OpenProject
    class TreeViewTest < Minitest::Test
      include Primer::ComponentTestHelpers

      def test_dom_structure
        render_preview(:default, params: { expanded: true })

        assert_selector("tree-view") do |tree|
          tree.assert_selector("ul[role=tree]") do |sub_tree|
            sub_tree.assert_selector("li[role=treeitem]") do |node|
              node.assert_selector(".TreeViewItemContainer", text: "src")
              node.assert_selector("ul[role=group]") do |sub_tree|
                sub_tree.assert_selector("li[role=treeitem]", text: "button.rb")
                sub_tree.assert_selector("li[role=treeitem]", text: "icon_button.rb")
              end
            end
          end
        end
      end

      def test_leading_visual_icon_pair_collapsed
        render_preview(:default)

        assert_selector("li[role=treeitem][data-path=\"[\\\"src\\\"]\"]") do |node|
          node.assert_selector(".TreeViewItemVisual tree-view-icon-pair") do |visual|
            visual.assert_selector("svg.octicon-file-directory-fill")
          end
        end
      end

      def test_leading_visual_icon_pair_expanded
        render_preview(:default, params: { expanded: true })

        assert_selector("li[role=treeitem][data-path=\"[\\\"src\\\"]\"]") do |node|
          node.assert_selector(".TreeViewItemVisual tree-view-icon-pair") do |visual|
            visual.assert_selector("svg.octicon-file-directory-open-fill")
          end
        end
      end

      def test_trailing_visual_icon
        render_preview(:default)

        assert_selector("li[role=treeitem][data-path=\"[\\\"src\\\"]\"]") do |node|
          # this should be visually positioned after the node's label
          node.assert_selector(":nth-child(5) svg.octicon-diff-modified")
        end
      end

      def test_node_described_by_leading_visual
        render_inline(Primer::OpenProject::TreeView.new) do |tree|
          tree.with_leaf(label: "src") do |node|
            node.with_leading_visual_icon(icon: :"file-directory-fill", label: "File folder")
          end
        end

        assert_selector "[data-test-selector='tree-view-visual-label']", text: "File folder"

        label_id = page
          .find_css("[data-test-selector='tree-view-visual-label']")
          .attribute("id")
          .value

        assert_selector "li[aria-describedby='#{label_id}']"
      end

      def test_node_labelled_by_content
        render_inline(Primer::OpenProject::TreeView.new) do |tree|
          tree.with_leaf(label: "src")
        end

        assert_selector ".TreeViewItemContent", text: "src"

        content_id = page
          .find_css(".TreeViewItemContent")
          .attribute("id")
          .value

        assert_selector "li[aria-labelledby='#{content_id}']"
      end
    end
  end
end
