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

    assert_selector("table")
    assert_selector("thead")
    assert_selector("tbody")
  end

  def test_renders_no_explicit_roles_by_default
    render_component do |table|
      table.with_head do |thead|
        thead.with_row { |tr| tr.with_header { "Header" } }
      end
      table.with_body do |tbody|
        tbody.with_row { |tr| tr.with_cell { "Cell" } }
      end
    end

    assert_no_selector("[role]")
  end

  def test_explicit_roles_cascade_to_all_descendants
    render_component(explicit_roles: true) do |table|
      table.with_head do |thead|
        thead.with_row { |tr| tr.with_header { "Header" } }
      end
      table.with_body do |tbody|
        tbody.with_row do |tr|
          tr.with_row_header { "Row header" }
          tr.with_cell { "Cell" }
        end
      end
      table.with_foot do |tfoot|
        tfoot.with_row { |tr| tr.with_cell { "Foot cell" } }
      end
    end

    assert_selector("table[role='table']")
    assert_selector("thead[role='rowgroup']")
    assert_selector("tbody[role='rowgroup']")
    assert_selector("tfoot[role='rowgroup']")
    assert_selector("tr[role='row']", count: 3)
    assert_selector("th[role='columnheader']", text: "Header")
    assert_selector("th[role='rowheader']", text: "Row header")
    assert_selector("td[role='cell']", count: 2)
  end

  def test_wraps_top_level_columns_in_colgroup
    render_component do |table|
      table.with_col
      table.with_col
    end

    assert_selector("table > colgroup > col", count: 2)
    assert_no_selector("table > col")
  end
end
