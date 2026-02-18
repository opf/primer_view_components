# frozen_string_literal: true

require "components/test_helper"

class PrimerOpenProjectTableHeaderRowTest < Minitest::Test
  include Primer::ComponentTestHelpers

  def render_component(**kwargs, &block)
    render_inline(Primer::OpenProject::Table::HeaderRow.new(**kwargs), &block)

    # bypass Nokogiri::HTML5.fragment
    # https://github.com/sparklemotion/nokogiri/issues/3536
    @rendered_content
  end

  def test_renders_row
    render_component do |tr|
      tr.with_header { "Column header #1" }
      tr.with_column_header { "Column header #2" }
      tr.with_cell { "Cell" }
    end

    assert_selector("tr[role='row']")
  end

  def test_renders_column_headers
    render_component do |tr|
      tr.with_header { "Column header #1" }
      tr.with_column_header { "Column header #2" }
      tr.with_cell { "Cell" }
    end

    assert_selector("th[scope='col']", count: 2)
    assert_text("Column header #1")
    assert_text("Column header #2")
  end

  def test_renders_cell
    render_component do |tr|
      tr.with_header { "Column header #1" }
      tr.with_column_header { "Column header #2" }
      tr.with_cell { "Cell" }
    end

    assert_selector("td", text: "Cell")
  end
end
