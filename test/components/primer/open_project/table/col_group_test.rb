# frozen_string_literal: true

require "components/test_helper"

class PrimerOpenProjectTableColGroupTest < Minitest::Test
  include Primer::ComponentTestHelpers

  def render_component(**kwargs, &block)
    render_inline(Primer::OpenProject::Table::ColGroup.new(**kwargs), &block)

    # bypass Nokogiri::HTML5.fragment
    # https://github.com/sparklemotion/nokogiri/issues/3536
    @rendered_content
  end

  def test_renders_colgroup_with_cols
    render_component do |colgroup|
      colgroup.with_col
      colgroup.with_col
    end

    assert_selector("colgroup")
    assert_selector("col", count: 2)
  end

  def test_renders_nothing_without_cols
    rendered = render_component

    assert rendered.to_s.blank?
  end
end
