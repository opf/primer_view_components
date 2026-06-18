# frozen_string_literal: true

require "components/test_helper"

class PrimerOpenProjectDataTablePaginationFooterTest < Minitest::Test
  include Primer::ComponentTestHelpers

  def render_footer(**kwargs)
    render_inline(Primer::OpenProject::DataTable::PaginationFooter.new(**kwargs))
  end

  def test_renders_single_pagination_nav
    render_footer(current_page: 2, page_count: 5, href_builder: ->(page) { "#page-#{page}" })

    # A single <nav> landmark, not a nav nested inside a wrapper
    assert_selector("nav.TablePagination", count: 1)
    assert_no_selector("nav.PaginationContainer")
    assert_selector("nav.TablePagination .PaginationContainer .Page[aria-current='page']", text: "2")
  end

  def test_range_renders_inside_the_nav
    render_footer(
      current_page: 1,
      page_count: 10,
      page_size: 10,
      total_count: 95,
      href_builder: ->(page) { "#page-#{page}" }
    )

    range = page.find("nav.TablePagination .TablePaginationRange")
    assert_includes(range.text, "1")
    assert_includes(range.text, "10")
    assert_includes(range.text, "95")
  end

  def test_range_clamps_end_to_total_count_on_last_page
    render_footer(
      current_page: 10,
      page_count: 10,
      page_size: 10,
      total_count: 95,
      href_builder: ->(page) { "#page-#{page}" }
    )

    range = page.find(".TablePaginationRange")
    # items 91 through 95 of 95
    assert_includes(range.text, "91")
    assert_includes(range.text, "95")
  end

  def test_omits_range_without_total_count
    render_footer(current_page: 2, page_count: 5, href_builder: ->(page) { "#page-#{page}" })

    assert_no_selector(".TablePaginationRange")
  end

  def test_range_has_screen_reader_through_text
    render_footer(
      current_page: 1,
      page_count: 10,
      page_size: 10,
      total_count: 95,
      href_builder: ->(page) { "#page-#{page}" }
    )

    assert_selector(".TablePaginationRange .sr-only", text: "through")
  end
end
