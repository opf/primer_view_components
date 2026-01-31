# frozen_string_literal: true

require "components/test_helper"

class PrimerOpenProjectDataTableColumnTest < Minitest::Test
  include Primer::ComponentTestHelpers

  def setup
    @component = Primer::OpenProject::DataTable::Column.new(field: :name)
  end

  def test_renders_cell_content_if_provided
    render_inline(@component) do |column|
      column.with_header { "Flavor" }
      column.with_cell do |row|
        "#{row.name} with a wafer and whipped cream"
      end
    end

    assert_equal("Chocolate with a wafer and whipped cream", @component.render_cell(row))
  end

  def test_renders_field_value_otherwise
    render_inline(@component) do |column|
      column.with_header { "Flavor" }
    end

    assert_equal("Chocolate", @component.render_cell(row))
  end

  private

  def ice_cream_klass
    @ice_cream_klass ||= Data.define(:id, :name)
  end

  def row
    @row ||= ice_cream_klass.new(id: 1, name: "Chocolate")
  end
end
