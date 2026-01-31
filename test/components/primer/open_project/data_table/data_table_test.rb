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

  def render_component(data, **kwargs, &block)
    render_inline(Primer::OpenProject::DataTable.new(data, **kwargs), &block)
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
    rendered = render_component(@data) do |data_table|
      data_table.with_column(field: :subject, header: "Subject")
    end

    assert_selector("table[role='table']")
    assert_renders_container(rendered)
    assert_renders_head
    assert_renders_body
  end

  def test_renders_nothing_without_slots
    rendered = render_component(@data)

    assert rendered.to_s.blank?
  end

  def test_title_defaults_to_h2
    render_component(@data) do |table|
      table.with_column(field: :subject, header: "Subject")
      table.with_title { "My table" }
    end

    assert_selector("h2.TableTitle", text: "My table")
  end

  def test_title_allows_heading_override
    render_component(@data) do |table|
      table.with_column(field: :subject, header: "Subject")
      table.with_title(tag: :h3) { "My table" }
    end

    assert_selector("h3.TableTitle", text: "My table")
  end

  def test_renders_with_title_slot
    rendered = render_component(@data) do |data_table|
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
    rendered = render_component(@data) do |data_table|
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

  def test_subtitle_defaults_to_div
    render_component(@data) do |table|
      table.with_column(field: :subject, header: "Subject")
      table.with_subtitle { "My subtitle" }
    end

    assert_selector("div.TableSubtitle", text: "My subtitle")
  end

  def test_subtitle_allows_tag_override
    render_component(@data) do |table|
      table.with_column(field: :subject, header: "Subject")
      table.with_subtitle(tag: :p) { "My subtitle" }
    end

    assert_selector("p.TableSubtitle", text: "My subtitle")
  end

  def test_renders_without_title_or_subtitle
    render_component(@data) do |data_table|
      data_table.with_column(field: :subject, header: "Subject")
    end

    assert_selector("table[role='table']")
    assert_no_selector("h2")
    assert_no_selector(".TableSubtitle")
  end

  def test_passes_classes_to_table_element
    render_component(@data, classes: "custom-table") do |data_table|
      data_table.with_column(field: :subject, header: "Subject")
    end

    assert_selector("table.Table.custom-table")
  end

  def test_preserves_table_style_with_grid_template_style
    render_component(@data, style: "width: 50%;") do |data_table|
      data_table.with_column(field: :subject, header: "Subject")
    end

    table = page.find("table.Table")
    assert_includes(table[:style], "width: 50%;")
    assert_includes(table[:style], "--grid-template-columns:")
  end

  def test_renders_rows_without_id
    row_klass = Data.define(:subject)

    render_component([row_klass.new(subject: "No ID")]) do |data_table|
      data_table.with_column(field: :subject, header: "Subject")
    end

    assert_selector(".TableCell", text: "No ID")
  end

  def test_renders_body_cells_with_column_alignment
    render_component(@data) do |data_table|
      data_table.with_column(field: :subject, header: "Subject", align: :end)
    end

    assert_selector("th[data-cell-align='end']", text: "Subject")
    assert_selector("td[data-cell-align='end']", text: "First")
  end

  def test_renders_cell_content_without_template_whitespace
    render_component(@data.first(1)) do |data_table|
      data_table.with_column(field: :subject, header: "Subject", row_header: true)
      data_table.with_column(field: :subject, header: "Custom") do |column|
        column.with_cell do |row|
          vc_test_controller.view_context.tag.span(row.subject, class: "subject")
        end
      end
    end

    assert_equal("First", page.find("tbody th").native.inner_html)
    assert_equal('<span class="subject">First</span>', page.find("tbody td").native.inner_html)
  end

  def test_renders_nothing_without_slots_even_with_invalid_initial_sort_column
    rendered = render_component(@data, initial_sort_column: :does_not_exist)

    assert rendered.to_s.blank?
  end

  def test_initial_sort_column_sets_sort_header
    render_component(
      @data,
      initial_sort_column: :subject,
      initial_sort_direction: :ASC
    ) do |data_table|
      data_table.with_column(
        field: :subject,
        header: "Subject",
        sort_by: true
      )
    end

    assert_selector("th[aria-sort='ascending']")
  end

  def test_initial_sort_column_sorts_rows_with_named_strategy
    row_klass = Data.define(:id, :subject)
    data = [
      row_klass.new(id: 1, subject: "Project 10"),
      row_klass.new(id: 2, subject: "Project 2"),
      row_klass.new(id: 3, subject: "Project 1")
    ]

    render_component(
      data,
      initial_sort_column: :subject,
      initial_sort_direction: :ASC
    ) do |data_table|
      data_table.with_column(
        field: :subject,
        header: "Subject",
        sort_by: :alphanumeric
      )
    end

    assert_equal(["Project 1", "Project 2", "Project 10"], body_first_column_texts)
  end

  def test_initial_sort_direction_without_column_uses_first_sortable_column
    render_component(
      @data,
      initial_sort_direction: :DESC
    ) do |data_table|
      data_table.with_column(
        field: :subject,
        header: "Subject",
        sort_by: true
      )
    end

    assert_selector("th[aria-sort='descending']")
  end

  def test_blank_sort_values_sort_last
    row_klass = Data.define(:id, :value)
    data = [
      row_klass.new(id: 1, value: nil),
      row_klass.new(id: 2, value: 2),
      row_klass.new(id: 3, value: ""),
      row_klass.new(id: 4, value: 3),
      row_klass.new(id: 5, value: 0),
      row_klass.new(id: 6, value: 1)
    ]

    render_component(
      data,
      initial_sort_column: :value,
      initial_sort_direction: :DESC
    ) do |data_table|
      data_table.with_column(field: :value, header: "Value", sort_by: true)
    end

    assert_equal(["3", "2", "1", "0", "", ""], body_first_column_texts)
  end

  def test_renders_raw_sort_metadata_for_formatted_cells
    row_klass = Data.define(:id, :created_at)
    data = [row_klass.new(id: 1, created_at: Time.utc(2026, 1, 2, 12, 30))]

    render_component(data) do |data_table|
      data_table.with_column(field: :created_at, header: "Created", sort_by: :datetime) do |column|
        column.with_cell do |row|
          row.created_at.strftime("%b %-d, %Y")
        end
      end
    end

    cell = page.find("td.TableCell")
    header = page.find("thead th", text: "Created")

    assert_equal("Jan 2, 2026", cell.text.strip)
    assert_equal("datetime", header[:"data-sort-strategy"])
    assert_nil(cell[:"data-sort-strategy"])
    assert_equal("number", cell[:"data-sort-type"])
    refute_equal(cell.text, cell[:"data-sort-value"])
  end

  def test_raises_for_invalid_initial_sort_column
    assert_raises(ArgumentError) do
      render_component(
        @data,
        initial_sort_column: :does_not_exist
      ) do |data_table|
        data_table.with_column(field: :subject, header: "Subject")
      end
    end
  end

  def test_raises_when_sort_column_is_not_sortable
    assert_raises(ArgumentError) do
      render_component(
        @data,
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
    render_component(@data) do |data_table|
      data_table.with_column(field: :subject, header: "Subject", width: :grow)
    end

    assert_selector("table[style*='--grid-template-columns']")
  end

  def test_grid_template_uses_auto_width
    render_component(@data) do |data_table|
      data_table.with_column(field: :subject, header: "Subject", width: :auto)
    end

    style = page.find("table.Table")[:style]
    assert_includes(style, "--grid-template-columns:")
    assert_includes(style, "auto")
  end

  def test_grid_template_uses_grow_collapse_width
    render_component(@data) do |data_table|
      data_table.with_column(field: :subject, header: "Subject", width: :grow_collapse)
    end

    style = page.find("table.Table")[:style]
    assert_includes(style, "minmax(0, 1fr)")
  end

  def test_grid_template_respects_min_and_max_width_numeric
    render_component(@data) do |data_table|
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
    render_component(@data) do |data_table|
      data_table.with_column(field: :subject, header: "Subject", width: 180)
    end

    style = page.find("table.Table")[:style]
    assert_includes(style, "180px")
  end

  def test_grid_template_accepts_explicit_string_width
    render_component(@data) do |data_table|
      data_table.with_column(field: :subject, header: "Subject", width: "20rem")
    end

    style = page.find("table.Table")[:style]
    assert_includes(style, "20rem")
  end

  def test_renders_custom_header_for_fieldless_column
    render_component(@data) do |data_table|
      data_table.with_column(field: :subject, header: "Subject")

      data_table.with_column(id: "actions") do |column|
        column.with_header do
          '<span class="sr-only">Actions</span>'.html_safe
        end

        column.with_cell do
          "Open actions"
        end
      end
    end

    assert_selector("th .sr-only", text: "Actions")
    assert_selector(".TableCell", text: "Open actions", count: 3)
  end

  def test_forwards_html_data_as_data_attributes
    render_component(@data, html_data: { test_selector: "my-table" }) do |table|
      table.with_column(field: :subject, header: "Subject")
    end

    assert_selector("table.Table[data-test-selector='my-table']")
  end

  def test_does_not_mutate_caller_html_data
    html_data = { test_selector: "my-table" }
    render_component(@data, html_data: html_data) do |table|
      table.with_column(field: :subject, header: "Subject")
    end

    assert_equal({ test_selector: "my-table" }, html_data)
  end

  private

  def body_first_column_texts
    page.all("tbody .TableRow", visible: :all).map do |row|
      row.all("th, td", visible: :all).first.text.strip
    end
  end
end
