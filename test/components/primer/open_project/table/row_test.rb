# frozen_string_literal: true

require "components/test_helper"

class PrimerOpenProjectTableRowTest < Minitest::Test
  include Primer::ComponentTestHelpers

  def render_component(**kwargs, &block)
    render_inline(Primer::OpenProject::Table::Row.new(**kwargs), &block)

    # bypass Nokogiri::HTML5.fragment
    # https://github.com/sparklemotion/nokogiri/issues/3536
    @rendered_content
  end

  def test_renders_row
    render_component do |tr|
      tr.with_row_header { "Row header" }
      tr.with_cell { "Cell" }
    end

    assert_selector("tr[role='row']")
  end

  def test_renders_row_header
    render_component do |tr|
      tr.with_row_header { "Row header" }
      tr.with_cell { "Cell" }
    end

    assert_selector("th[scope='row']", text: "Row header")
  end

  def test_renders_cell
    render_component do |tr|
      tr.with_row_header { "Row header" }
      tr.with_cell { "Cell" }
    end

    assert_selector("td", text: "Cell")
  end
end
