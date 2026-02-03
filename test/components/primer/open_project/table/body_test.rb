# frozen_string_literal: true

require "components/test_helper"

class PrimerOpenProjectTableBodyTest < Minitest::Test
  include Primer::ComponentTestHelpers
  include ActionView::Helpers::TagHelper

  def render_component(**kwargs, &block)
    render_inline(Primer::OpenProject::Table::Body.new(**kwargs), &block)

    # bypass Nokogiri::HTML5.fragment https://github.com/sparklemotion/nokogiri/issues/3536
    @rendered_content
  end

  #
  # with slots
  #

  def test_renders_tbody_and_row_with_slots
    render_component do |tbody|
      tbody.with_row do |tr|
        tr.with_cell { "Cell" }
      end
    end

    assert_selector("tbody[role='rowgroup']")
    assert_selector("tr[role='row']")
  end

  #
  # with content
  #

  def test_renders_tbody_and_row_with_content
    render_component do
      tag.tr
    end

    assert_selector("tbody[role='rowgroup']")
    assert_selector("tr")
  end

  #
  # without slots or content
  #

  def test_renders_nothing_without_slots_or_content
    rendered = render_component

    assert rendered.to_s.blank?
  end
end
