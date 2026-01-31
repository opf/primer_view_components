# frozen_string_literal: true

require "components/test_helper"

class PrimerOpenProjectTableHeaderTest < Minitest::Test
  include Primer::ComponentTestHelpers

  def render_component(**kwargs, &block)
    render_inline(Primer::OpenProject::Table::Header.new(**kwargs), &block)

    # bypass Nokogiri::HTML5.fragment
    # https://github.com/sparklemotion/nokogiri/issues/3536
    @rendered_content
  end

  #
  # default scope (column)
  #

  def test_renders_column_header_by_default
    render_component { "Column Header" }

    assert_selector("th[role='columnheader']", text: "Column Header")
  end

  #
  # row scope
  #

  def test_renders_row_header_when_scope_is_row
    render_component(scope: :row) { "Row Header" }

    assert_selector("th[role='rowheader']", text: "Row Header")
  end

  #
  # invalid scope
  #

  def test_raises_for_invalid_scope
    err = assert_raises(Primer::FetchOrFallbackHelper::InvalidValueError) do
      render_component(scope: :foo) { "Header in the Third Dimension" }
    end

    assert_match(/foo/, err.message)
  end
end
