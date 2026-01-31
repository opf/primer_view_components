# frozen_string_literal: true

require "components/test_helper"

class PrimerOpenProjectTableCellTest < Minitest::Test
  include Primer::ComponentTestHelpers

  def render_component(**kwargs, &block)
    render_inline(Primer::OpenProject::Table::Cell.new(**kwargs), &block)

    # bypass Nokogiri::HTML5.fragment https://github.com/sparklemotion/nokogiri/issues/3536
    @rendered_content
  end

  def test_renders_cell_with_content
    render_component { "Cell content" }

    assert_selector("td[role='cell']", text: "Cell content")
  end

  def test_renders_cell_with_text
    render_component(text: "Cell text")

    assert_selector("td[role='cell']", text: "Cell text")
  end

  def test_renders_empty_cell_without_content_or_text
    render_component

    assert_selector("td[role='cell']", text: "")
  end
end
