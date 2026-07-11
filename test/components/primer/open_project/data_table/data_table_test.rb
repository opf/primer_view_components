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

  def test_renders_actions_in_title_area
    render_component(@data) do |data_table|
      data_table.with_column(field: :subject, header: "Subject")
      data_table.with_title { "Projects" }
      data_table.with_action_button { "Export" }
      data_table.with_action_icon_button(icon: :pencil, "aria-label": "Edit")
    end

    assert_selector(".TableContainer .TableActions button", text: "Export")
    assert_selector(".TableActions button .octicon-pencil")
    assert_selector(".TableActions tool-tip", text: "Edit", visible: :all)
  end

  def test_renders_no_actions_container_without_actions
    render_component(@data) do |data_table|
      data_table.with_column(field: :subject, header: "Subject")
    end

    assert_no_selector(".TableActions")
  end

  def test_renders_divider_when_enabled
    render_component(@data, divider: true) do |data_table|
      data_table.with_column(field: :subject, header: "Subject")
      data_table.with_title { "Projects" }
    end

    assert_selector(".TableContainer .TableDivider[role='presentation']")
  end

  def test_renders_no_divider_by_default
    render_component(@data) do |data_table|
      data_table.with_column(field: :subject, header: "Subject")
    end

    assert_no_selector(".TableDivider")
  end

  def test_external_sorting_renders_sort_links_with_next_direction
    render_component(
      @data,
      sorting: :external,
      sort_href_builder: ->(column_id, direction) { "?sort=#{column_id}&direction=#{direction}" },
      initial_sort_column: :subject,
      initial_sort_direction: :ASC
    ) do |data_table|
      data_table.with_column(field: :subject, header: "Subject", sort_by: true)
      data_table.with_column(field: :id, header: "Id", sort_by: true)
    end

    # sorted ASC -> link requests DESC; unsorted -> link requests ASC
    assert_selector("th[aria-sort='ascending'] a.TableSortLink[href='?sort=subject&direction=DESC']")
    assert_selector("th a.TableSortLink[href='?sort=id&direction=ASC']")
    assert_no_selector("th button.TableSortButton")
  end

  def test_external_sorting_descending_links_back_to_ascending
    render_component(
      @data,
      sorting: :external,
      sort_href_builder: ->(column_id, direction) { "?sort=#{column_id}&direction=#{direction}" },
      initial_sort_column: :subject,
      initial_sort_direction: :DESC
    ) do |data_table|
      data_table.with_column(field: :subject, header: "Subject", sort_by: true)
    end

    assert_selector("th[aria-sort='descending'] a.TableSortLink[href='?sort=subject&direction=ASC']")
  end

  def test_external_sorting_emits_no_client_sort_metadata
    render_component(
      @data,
      sorting: :external,
      sort_href_builder: ->(column_id, direction) { "?sort=#{column_id}&direction=#{direction}" }
    ) do |data_table|
      data_table.with_column(field: :subject, header: "Subject", sort_by: true)
    end

    assert_selector("data-table[data-external-sorting]")
    assert_no_selector("th[data-sort-strategy]")
    assert_no_selector("td[data-sort-value]")
    assert_no_selector("[data-action*='toggleSort']")
  end

  def test_external_sorting_does_not_reorder_rows
    row_klass = Data.define(:subject)
    data = [row_klass.new(subject: "b"), row_klass.new(subject: "a"), row_klass.new(subject: "c")]

    Primer::OpenProject::DataTable::Sorting.stub(:sort_rows, ->(*) { raise "sort_rows must not be called" }) do
      render_component(
        data,
        sorting: :external,
        sort_href_builder: ->(column_id, direction) { "?sort=#{column_id}&direction=#{direction}" },
        initial_sort_column: :subject,
        initial_sort_direction: :ASC
      ) do |data_table|
        data_table.with_column(field: :subject, header: "Subject", sort_by: true)
      end
    end

    assert_equal(%w[b a c], body_first_column_texts)
  end

  def test_external_sorting_requires_href_builder_for_sortable_columns
    assert_raises(ArgumentError) do
      render_component(@data, sorting: :external) do |data_table|
        data_table.with_column(field: :subject, header: "Subject", sort_by: true)
      end
    end
  end

  def test_external_sorting_without_sortable_columns_needs_no_builder
    render_component(@data, sorting: :external) do |data_table|
      data_table.with_column(field: :subject, header: "Subject")
    end

    assert_selector("table")
  end

  def test_emits_data_row_id_with_row_id_proc
    render_component(@data, row_id: ->(row) { row.id }) do |data_table|
      data_table.with_column(field: :subject, header: "Subject")
    end

    assert_selector("tbody tr[data-row-id='1']")
    assert_selector("tbody tr[data-row-id='3']")
    assert_no_selector("tbody tr[id]")
  end

  def test_emits_namespaced_dom_id_with_row_dom_id
    render_component(@data, id: "my-table", row_id: ->(row) { row.id }, row_dom_id: true) do |data_table|
      data_table.with_column(field: :subject, header: "Subject")
    end

    assert_selector("tbody tr#my-table-row-1[data-row-id='1']")
  end

  def test_emits_no_row_attributes_without_row_id_proc
    render_component(@data) do |data_table|
      data_table.with_column(field: :subject, header: "Subject")
    end

    assert_no_selector("tbody tr[data-row-id]")
  end

  def test_skips_row_attributes_for_blank_row_id
    row_klass = Data.define(:id, :subject)
    data = [row_klass.new(id: nil, subject: "First"), row_klass.new(id: 2, subject: "Second")]

    render_component(data, row_id: ->(row) { row.id }) do |data_table|
      data_table.with_column(field: :subject, header: "Subject")
    end

    assert_selector("tbody tr[data-row-id='2']")
    assert_selector("tbody tr[data-row-id]", count: 1)
  end

  def test_raises_for_row_dom_id_without_row_id
    assert_raises(ArgumentError) do
      Primer::OpenProject::DataTable.new(@data, row_dom_id: true)
    end
  end

  def test_renders_default_empty_state_without_rows
    render_component([]) do |data_table|
      data_table.with_column(field: :subject, header: "Subject")
      data_table.with_title { "Projects" }
    end

    assert_selector(".TableContainer .TableEmptyState .blankslate h4", text: "No data available")
    assert_no_selector("table")
    assert_no_selector("[aria-labelledby]")
  end

  def test_renders_custom_empty_state_without_rows
    render_component([]) do |data_table|
      data_table.with_column(field: :subject, header: "Subject")
      data_table.with_empty_state(
        title: "Nothing here",
        description: "Create a project to get started.",
        icon: :book
      )
    end

    assert_selector(".TableEmptyState h4", text: "Nothing here")
    assert_selector(".TableEmptyState p", text: "Create a project to get started.")
    assert_selector(".TableEmptyState .octicon-book")
  end

  def test_interactive_empty_state_announces_politely
    render_component([]) do |data_table|
      data_table.with_column(field: :subject, header: "Subject")
      data_table.with_empty_state(title: "Nothing here", interactive: true)
    end

    assert_selector(".TableEmptyState [role='status'][aria-live='polite']")
  end

  def test_ignores_empty_state_when_rows_present
    render_component(@data) do |data_table|
      data_table.with_column(field: :subject, header: "Subject")
      data_table.with_empty_state(title: "Nothing here")
    end

    assert_selector("table")
    assert_no_selector(".TableEmptyState")
  end

  def test_renders_placeholder_for_blank_cell_values
    row_klass = Data.define(:subject, :assignee)
    data = [row_klass.new(subject: "First", assignee: nil)]

    render_component(data) do |data_table|
      data_table.with_column(field: :subject, header: "Subject")
      data_table.with_column(field: :assignee, header: "Assignee", placeholder: "Unassigned")
    end

    assert_selector("td span.TableCellPlaceholder", text: "Unassigned")
    assert_no_selector("td span.TableCellPlaceholder", text: "First")
  end

  def test_does_not_render_placeholder_for_present_values
    row_klass = Data.define(:assignee)
    data = [row_klass.new(assignee: "Ada")]

    render_component(data) do |data_table|
      data_table.with_column(field: :assignee, header: "Assignee", placeholder: "Unassigned")
    end

    assert_selector("td", text: "Ada")
    assert_no_selector(".TableCellPlaceholder")
  end

  def test_renders_placeholder_when_custom_cell_block_is_blank
    row_klass = Data.define(:assignee)
    data = [row_klass.new(assignee: nil)]

    render_component(data) do |data_table|
      data_table.with_column(id: "assignee", header: "Assignee", placeholder: "Unassigned") do |column|
        column.with_cell { |row| row.assignee }
      end
    end

    assert_selector("td span.TableCellPlaceholder", text: "Unassigned")
  end

  def test_renders_pagination_slot_below_table
    render_component(@data) do |data_table|
      data_table.with_column(field: :subject, header: "Subject")
      data_table.with_pagination(
        current_page: 1,
        page_count: 3,
        page_size: 1,
        total_count: 3,
        href_builder: ->(page) { "#page-#{page}" }
      )
    end

    assert_selector(".TableContainer nav.TablePagination")
    assert_selector("nav.TablePagination .TablePaginationRange")
    assert_selector("nav.TablePagination .PaginationContainer .Page[aria-current='page']", text: "1")
  end

  def test_renders_without_pagination_slot
    render_component(@data) do |data_table|
      data_table.with_column(field: :subject, header: "Subject")
    end

    assert_no_selector(".TablePagination")
  end

  private

  def body_first_column_texts
    page.all("tbody .TableRow", visible: :all).map do |row|
      row.all("th, td", visible: :all).first.text.strip
    end
  end
end
