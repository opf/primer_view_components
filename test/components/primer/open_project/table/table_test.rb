# frozen_string_literal: true

require "components/test_helper"

class PrimerOpenProjectTableTest < Minitest::Test
  include Primer::ComponentTestHelpers

  def render_component(**kwargs, &block)
    render_inline(Primer::OpenProject::Table.new(**kwargs), &block)
  end

  def test_renders_table_with_head_and_body
    render_component do |table|
      table.with_caption { "Table" }

      table.with_head do |thead|
        thead.with_row do |tr|
          tr.with_header { "Header" }
        end
      end

      table.with_body do |tbody|
        tbody.with_row do |tr|
          tr.with_cell { "Cell" }
        end
      end
    end

    assert_selector("table[role='table']")
    assert_selector("thead[role='rowgroup']")
    assert_selector("tbody[role='rowgroup']")
  end
end
