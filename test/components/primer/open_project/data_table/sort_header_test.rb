# frozen_string_literal: true

require "components/test_helper"

class PrimerOpenProjectDataTableSortHeaderTest < Minitest::Test
  include Primer::ComponentTestHelpers

  def render_component(direction: Primer::OpenProject::DataTable::SortHeader::DEFAULT_DIRECTION, **args, &block)
    render_inline(
      Primer::OpenProject::DataTable::SortHeader.new(direction: direction, **args),
      &block
    )
  end

  def test_renders_header_cell
    render_component { "Name" }

    assert_selector("th.TableHeader")
    assert_text("Name")
  end

  def test_sets_aria_sort_for_ascending
    render_component(direction: :ASC) { "Name" }

    assert_selector("th[aria-sort='ascending']")
  end

  def test_sets_aria_sort_for_descending
    render_component(direction: :DESC) { "Name" }

    assert_selector("th[aria-sort='descending']")
  end

  def test_does_not_set_aria_sort_for_none
    render_component(direction: :NONE) { "Name" }

    assert_no_selector("th[aria-sort]")
  end

  def test_renders_sort_button
    render_component { "Name" }

    assert_selector("button.TableSortButton")
  end

  def test_renders_both_sort_icons
    render_component { "Name" }

    assert_selector(".TableSortIcon--ascending")
    assert_selector(".TableSortIcon--descending")
  end

  def test_shows_ascending_icon_for_ascending
    render_component(direction: :ASC) { "Name" }

    assert_selector(".TableSortIcon--ascending:not(.d-none)")
    assert_selector(".TableSortIcon--descending.d-none")
  end

  def test_shows_descending_icon_for_descending
    render_component(direction: :DESC) { "Name" }

    assert_selector(".TableSortIcon--descending:not(.d-none)")
    assert_selector(".TableSortIcon--ascending.d-none")
  end

  def test_shows_ascending_icon_for_none
    render_component(direction: :NONE) { "Name" }

    assert_selector(".TableSortIcon--ascending:not(.d-none)")
    assert_selector(".TableSortIcon--descending.d-none")
  end

  def test_passes_through_system_arguments
    render_component(classes: "foo", style: "width: 100%;") { "Name" }

    assert_selector("th.foo")
    assert_selector("th[style='width: 100%;']", visible: :all)
  end
end
