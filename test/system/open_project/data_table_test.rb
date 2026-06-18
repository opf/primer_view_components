# frozen_string_literal: true

require "system/test_case"

class IntegrationOpenProjectDataTableTest < System::TestCase
  def test_with_row_actions_preview_renders
    visit_preview(:with_row_actions)

    assert_selector("h2", text: "Projects")
    assert_selector(".TableHeader", text: "Name")
    assert_selector(".TableCell", text: /Project/)
  end

  def test_initial_descending_sort_and_click_toggle_icons
    visit_preview(:playground, initial_sort_column: :name, initial_sort_direction: :DESC, rows_count: 10)

    assert_equal(["Project 10", "Project 9", "Project 8"], first_column_texts.first(3))

    header = sort_header("Name")
    assert_equal("descending", header["aria-sort"])
    assert_sort_icon_state(header, :descending)

    header.find("button").click

    header = sort_header("Name")
    assert_equal("ascending", header["aria-sort"])
    assert_equal(["Project 1", "Project 2", "Project 3"], first_column_texts.first(3))
    assert_sort_icon_state(header, :ascending)
  end

  def test_clicking_different_sort_header_resets_to_ascending
    visit_preview(:playground, initial_sort_column: :name, initial_sort_direction: :DESC, rows_count: 10)

    sort_header("Status").find("button").click

    assert_nil(sort_header("Name")["aria-sort"])

    header = sort_header("Status")
    assert_equal("ascending", header["aria-sort"])
    assert_sort_icon_state(header, :ascending)
    assert_equal(["active", "active", "active"], column_texts(1).first(3))
  end

  def test_formatted_date_cells_sort_by_raw_datetime_metadata
    visit_preview(:playground, initial_sort_column: :none, initial_sort_direction: :none, rows_count: 10)

    created_cell = body_rows.first.all("th, td", visible: :all)[2]
    refute_equal(created_cell.text, created_cell[:"data-sort-value"])
    assert_nil(created_cell[:"data-sort-strategy"])
    assert_equal("datetime", sort_header("Created")[:"data-sort-strategy"])

    sort_header("Created").find("button").click

    assert_equal("ascending", sort_header("Created")["aria-sort"])
    assert_equal("Project 10", first_column_texts.first)
  end

  def test_with_pagination_preview_renders
    visit_preview(:with_pagination)

    assert_selector(".TablePagination .TablePaginationRange")
    range = page.find(".TablePaginationRange")
    assert_includes(range.text, "1")
    assert_includes(range.text, "10")
    assert_includes(range.text, "95")

    assert_equal(10, body_rows.size)
    assert_equal("Project 1", first_column_texts.first)
    assert_selector("nav.TablePagination .Page[aria-current='page']", text: "1")
  end

  def test_with_pagination_navigates_to_next_page
    visit_preview(:with_pagination)

    page.find("nav.TablePagination .Page", text: "2", exact_text: true).click

    assert_selector("nav.TablePagination .Page[aria-current='page']", text: "2")
    assert_equal("Project 11", first_column_texts.first)

    range = page.find(".TablePaginationRange")
    assert_includes(range.text, "11")
    assert_includes(range.text, "20")
  end

  def test_with_pagination_using_default_page_index_renders
    visit_preview(:with_pagination_using_default_page_index)

    assert_selector("nav.TablePagination .Page[aria-current='page']", text: "50")
    assert_equal("Project 491", first_column_texts.first)

    range = page.find(".TablePaginationRange")
    assert_includes(range.text, "491")
    assert_includes(range.text, "500")
    assert_includes(range.text, "1000")
  end

  private

  def body_rows
    page.all("tbody .TableRow", visible: :all)
  end

  def first_column_texts
    column_texts(0)
  end

  def column_texts(index)
    body_rows.map do |row|
      row.all("th, td", visible: :all)[index].text
    end
  end

  def sort_header(text)
    page.find("thead th", text: text, visible: :all)
  end

  def assert_sort_icon_state(header, direction)
    within(header) do
      if direction == :ascending
        assert_selector(".TableSortIcon--ascending:not(.d-none)", visible: :all)
        assert_selector(".TableSortIcon--descending.d-none", visible: :all)
      else
        assert_selector(".TableSortIcon--descending:not(.d-none)", visible: :all)
        assert_selector(".TableSortIcon--ascending.d-none", visible: :all)
      end
    end
  end
end
