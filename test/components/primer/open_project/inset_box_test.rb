# frozen_string_literal: true

require "components/test_helper"

class PrimerOpenProjectInsetBoxTest < Minitest::Test
  include Primer::ComponentTestHelpers

  def test_renders
    render_inline(Primer::OpenProject::InsetBox.new) do |component|
      component.with_title { "Title" }
      "Content"
    end

    assert_selector(".InsetBox")
    assert_text("Title")
    assert_text("Content")
  end

  def test_renders_without_title_or_icon
    render_inline(Primer::OpenProject::InsetBox.new) { "Content" }

    assert_no_selector(".InsetBox--title-container")
    assert_text("Content")
  end

  def test_renders_with_title_icon
    render_inline(Primer::OpenProject::InsetBox.new) do |component|
      component.with_title_icon(icon: :info)
      component.with_title { "Title" }
      "Content"
    end

    assert_selector(".InsetBox--title-container")
    assert_selector(".octicon-info")
  end

  def test_renders_with_clipboard_copy_button
    render_inline(Primer::OpenProject::InsetBox.new) do |component|
      component.with_clipboard_copy_button(value: "Copyable value", "aria-label": "Copy value")
      "Content"
    end

    assert_selector("clipboard-copy")
  end

  def test_renders_with_actions
    render_inline(Primer::OpenProject::InsetBox.new) do |component|
      component.with_action_button { "Action" }
      "Content"
    end

    assert_selector(".InsetBox--body--actions button", text: "Action")
  end

  def test_renders_actions_with_spacing
    render_inline(Primer::OpenProject::InsetBox.new) do |component|
      component.with_action_button { "Edit" }
      component.with_action_button { "Delete" }
      "Content"
    end

    assert_selector(".InsetBox--body--actions .InsetBox--actions button", count: 2)
  end

  def test_renders_with_action_menu
    render_inline(Primer::OpenProject::InsetBox.new) do |component|
      component.with_action_menu do |menu|
        menu.with_show_button { "Menu" }
        menu.with_item(label: "Item")
      end
      "Content"
    end

    assert_selector(".InsetBox--body--actions action-menu")
  end

  def test_renders_without_border
    render_inline(Primer::OpenProject::InsetBox.new(border: false)) { "Content" }

    assert_no_selector(".border")
  end

  def test_renders_with_scheme
    render_inline(Primer::OpenProject::InsetBox.new(scheme: :warning)) { "Content" }

    assert_selector(".InsetBox.color-bg-attention.color-border-attention")
  end
end
