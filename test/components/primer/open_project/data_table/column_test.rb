# frozen_string_literal: true

require "components/test_helper"

class PrimerOpenProjectDataTableColumnTest < Minitest::Test
  include Primer::ComponentTestHelpers

  def setup
    @component = Primer::OpenProject::DataTable::Column.new(field: :name)
  end

  def test_renders_cell_content_if_provided
    @component.with_cell do |row|
      "#{row.name} with a wafer and whipped cream"
    end

    assert_equal("Chocolate with a wafer and whipped cream", @component.render_cell(row))
  end

  def test_renders_field_value_otherwise
    assert_equal("Chocolate", @component.render_cell(row))
  end

  def test_render_cell_returns_nil_when_no_field_and_no_cell_block
    component = Primer::OpenProject::DataTable::Column.new(field: nil)

    assert_nil(component.render_cell(row))
  end

  def test_header_uses_initializer_value
    component = Primer::OpenProject::DataTable::Column.new(field: :name, header: "Flavor")

    assert_equal("Flavor", component.header.to_s)
    assert component.header?
  end

  def test_sort_by_true_uses_basic_strategy
    component = Primer::OpenProject::DataTable::Column.new(field: :name, sort_by: true)

    assert component.sortable?
    assert_equal(:basic, component.sort_strategy)
  end

  def test_accepts_named_sort_strategy
    component = Primer::OpenProject::DataTable::Column.new(field: :name, sort_by: :alphanumeric)

    assert component.sortable?
    assert_equal(:alphanumeric, component.sort_strategy)
  end

  def test_rejects_sort_direction_as_sort_by
    error = assert_raises(ArgumentError) do
      Primer::OpenProject::DataTable::Column.new(field: :name, sort_by: :ASC)
    end

    assert_includes(error.message, "initial_sort_direction")
  end

  def test_rejects_unknown_sort_strategy
    error = assert_raises(ArgumentError) do
      Primer::OpenProject::DataTable::Column.new(field: :name, sort_by: :unknown)
    end

    assert_includes(error.message, "sort_by")
  end

  def test_identifier_prefers_id_over_field
    column = Primer::OpenProject::DataTable::Column.new(id: "custom", field: :subject)
    assert_equal "custom", column.identifier
  end

  def test_identifier_falls_back_to_field
    column = Primer::OpenProject::DataTable::Column.new(field: :subject)
    assert_equal :subject, column.identifier
  end

  def test_identifier_nil_when_neither_present
    column = Primer::OpenProject::DataTable::Column.new
    assert_nil column.identifier
  end

  def test_sort_value_uses_proc_when_given
    row = Data.define(:a, :b).new(a: 2, b: 3)
    column = Primer::OpenProject::DataTable::Column.new(
      id: "sum", sort_by: true, sort_value: ->(r) { r.a + r.b }
    )
    assert_equal 5, column.sort_value(row)
  end

  def test_sort_value_falls_back_to_field
    row = Data.define(:subject).new(subject: "hi")
    column = Primer::OpenProject::DataTable::Column.new(field: :subject)
    assert_equal "hi", column.sort_value(row)
  end

  private

  def ice_cream_klass
    @ice_cream_klass ||= Data.define(:id, :name)
  end

  def row
    @row ||= ice_cream_klass.new(id: 1, name: "Chocolate")
  end
end
