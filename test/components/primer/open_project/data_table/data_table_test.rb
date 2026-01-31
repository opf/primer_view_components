# frozen_string_literal: true

require "components/test_helper"

class PrimerOpenProjectDataTableDataTableTest < Minitest::Test
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
    render_inline(Primer::OpenProject::DataTable::DataTable.new(**kwargs), &block)
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
end
