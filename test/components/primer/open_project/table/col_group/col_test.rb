# frozen_string_literal: true

require "components/test_helper"

class PrimerOpenProjectTableColGroupColTest < Minitest::Test
  include Primer::ComponentTestHelpers

  def render_component(**kwargs, &block)
    render_inline(Primer::OpenProject::Table::ColGroup::Col.new(**kwargs), &block)

    # bypass Nokogiri::HTML5.fragment https://github.com/sparklemotion/nokogiri/issues/3536
    @rendered_content
  end

  def test_renders_col
    render_component
    assert_selector("col")
  end

  def test_renders_numeric_width_as_pixel_style
    render_component(width: 120)

    assert_selector("col[style='width: 120px;']")
  end

  def test_renders_string_width_with_existing_style
    render_component(width: "25%", style: "background-color: red")

    assert_selector("col[style='background-color: red;width: 25%;']")
  end
end
