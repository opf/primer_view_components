# frozen_string_literal: true

require "components/test_helper"

class PrimerOpenProjectDragHandleTest < Minitest::Test
  include Primer::ComponentTestHelpers

  def test_renders
    render_inline(Primer::OpenProject::DragHandle.new)

    assert_selector(".DragHandle .octicon")
  end

  def test_renders_larger_icon
    render_inline(Primer::OpenProject::DragHandle.new(size: :medium))

    assert_selector(".DragHandle .octicon[width='24']")
  end

  def test_renders_with_role_button
    render_inline(Primer::OpenProject::DragHandle.new)

    assert_selector(".DragHandle[role='button']")
  end

  def test_renders_with_tabindex
    render_inline(Primer::OpenProject::DragHandle.new)

    assert_selector(".DragHandle[tabindex='0']")
  end

  def test_renders_with_default_aria_label
    render_inline(Primer::OpenProject::DragHandle.new)

    assert_selector(".DragHandle[aria-label='Drag to reorder']")
  end

  def test_renders_with_custom_label
    render_inline(Primer::OpenProject::DragHandle.new(label: "Move item"))

    assert_selector(".DragHandle[aria-label='Move item']")
  end

  def test_renders_with_aria_pressed
    render_inline(Primer::OpenProject::DragHandle.new)

    assert_selector(".DragHandle[aria-pressed='false']")
  end

  def test_denies_aria_label_argument
    with_raise_on_invalid_aria(true) do
      assert_raises(ArgumentError) do
        render_inline(Primer::OpenProject::DragHandle.new(aria: { label: "foo" }))
      end
    end
  end
end
