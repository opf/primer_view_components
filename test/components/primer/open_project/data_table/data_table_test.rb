# frozen_string_literal: true

require "components/test_helper"

class PrimerOpenProjectDataTableTest < Minitest::Test
  include Primer::ComponentTestHelpers

  def setup
    row_klass = Data.define(:id, :subject)

    @data = [
      row_klass.new(id: 1, subject: "First"),
      row_klass.new(id: 2, subject: "Second"),
      row_klass.new(id: 3, subject: "Third")
    ]
  end

  def render_component(**kwargs, &block)
    render_inline(Primer::OpenProject::DataTable.new(**kwargs), &block)
  end

  #
  # Shared assertions (translated from shared_examples)
  #

  def assert_renders_container(rendered)
    assert_selector("scrollable-region")
    assert_selector(".TableContainer .TableOverflowWrapper .Table")
  end

  def assert_renders_head
    assert_selector("thead[role='rowgroup']")
    assert_selector(".Table .TableHead .TableRow", count: 1)
    assert_selector(".TableHeader", count: 1)
  end

  def assert_renders_body
    assert_selector("tbody[role='rowgroup']")
    assert_selector(".Table .TableBody .TableRow", count: 3)
    assert_selector(".TableCell", count: 3)
  end

  #
  # Tests
  #

  def test_renders_with_minimal_slots
    rendered = render_component(data: @data) do |data_table|
      data_table.with_column(field: :subject, header: "Subject")
    end

    assert_selector("table[role='table']")
    assert_renders_container(rendered)
    assert_renders_head
    assert_renders_body
  end

  def test_renders_nothing_without_slots
    rendered = render_component(data: @data)

    assert rendered.to_s.blank?
  end

  def test_renders_with_title_slot
    rendered = render_component(data: @data) do |data_table|
      data_table.with_title { "Arbeitspakete" }
      data_table.with_column(field: :subject, header: "Subject")
    end

    assert_selector("h2", text: "Arbeitspakete")
    assert_renders_container(rendered)
    assert_renders_head
    assert_renders_body

    # scrollable-region labelled-by
    scrollable_region = page.find("scrollable-region")
    title = page.find("h2", text: "Arbeitspakete")

    refute_nil title[:id]
    assert_equal title[:id], scrollable_region[:"data-labelled-by"]

    # table accessible name
    assert_selector("table[role='table'][aria-labelledby='#{title[:id]}']")
  end

  def test_renders_with_subtitle_slot
    rendered = render_component(data: @data) do |data_table|
      data_table.with_subtitle { "Workin' night and day" }
      data_table.with_column(field: :subject, header: "Subject")
    end

    assert_selector("div", text: "Workin' night and day")
    assert_renders_container(rendered)
    assert_renders_head
    assert_renders_body

    # table accessible description
    assert_selector("div.TableSubtitle", text: "Workin' night and day")
    subtitle = page.find("div.TableSubtitle", text: "Workin' night and day")
    assert_selector("table[aria-describedby='#{subtitle[:id]}']")
  end

  def test_renders_without_title_or_subtitle
    render_component(data: @data) do |data_table|
      data_table.with_column(field: :subject, header: "Subject")
    end

    assert_selector("table[role='table']")
    assert_no_selector("h2")
    assert_no_selector(".TableSubtitle")
  end

  def test_initial_sort_column_sets_sort_header
    render_component(
      data: @data,
      initial_sort_column: :subject,
      initial_sort_direction: :ASC
    ) do |data_table|
      data_table.with_column(
        field: :subject,
        header: "Subject",
        sort_by: :ASC
      )
    end

    assert_selector("th[aria-sort='ascending']")
  end

  def test_initial_sort_direction_without_column_uses_first_sortable_column
    render_component(
      data: @data,
      initial_sort_direction: :DESC
    ) do |data_table|
      data_table.with_column(
        field: :subject,
        header: "Subject",
        sort_by: :ASC
      )
    end

    assert_selector("th[aria-sort='descending']")
  end

  def test_raises_for_invalid_initial_sort_column
    assert_raises(ArgumentError) do
      render_component(
        data: @data,
        initial_sort_column: :does_not_exist
      ) do |data_table|
        data_table.with_column(field: :subject, header: "Subject")
      end
    end
  end

  def test_raises_when_sort_column_is_not_sortable
    assert_raises(ArgumentError) do
      render_component(
        data: @data,
        initial_sort_column: :subject
      ) do |data_table|
        data_table.with_column(
          field: :subject,
          header: "Subject",
          sort_by: nil
        )
      end
    end
  end

  def test_sets_grid_template_columns_style
    render_component(data: @data) do |data_table|
      data_table.with_column(field: :subject, header: "Subject", width: :grow)
    end

    assert_selector("table[style*='--grid-template-columns']")
  end

  def test_grid_template_uses_auto_width
    render_component(data: @data) do |data_table|
      data_table.with_column(field: :subject, header: "Subject", width: :auto)
    end

    style = page.find("table.Table")[:style]
    assert_includes(style, "--grid-template-columns:")
    assert_includes(style, "auto")
  end

  def test_grid_template_uses_grow_collapse_width
    render_component(data: @data) do |data_table|
      data_table.with_column(field: :subject, header: "Subject", width: :grow_collapse)
    end

    style = page.find("table.Table")[:style]
    assert_includes(style, "minmax(0, 1fr)")
  end

  def test_grid_template_respects_min_and_max_width_numeric
    render_component(data: @data) do |data_table|
      data_table.with_column(
        field: :subject,
        header: "Subject",
        min_width: 120,
        max_width: 240
      )
    end

    style = page.find("table.Table")[:style]
    assert_includes(style, "minmax(120px, 240px)")
  end

  def test_grid_template_accepts_explicit_numeric_width
    render_component(data: @data) do |data_table|
      data_table.with_column(field: :subject, header: "Subject", width: 180)
    end

    style = page.find("table.Table")[:style]
    assert_includes(style, "180px")
  end

  def test_grid_template_accepts_explicit_string_width
    render_component(data: @data) do |data_table|
      data_table.with_column(field: :subject, header: "Subject", width: "20rem")
    end

    style = page.find("table.Table")[:style]
    assert_includes(style, "20rem")
  end
end
