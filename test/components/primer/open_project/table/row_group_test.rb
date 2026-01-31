# frozen_string_literal: true

require "components/test_helper"

class PrimerOpenProjectTableRowGroupTest < Minitest::Test
  def test_rows_defaults_to_empty
    assert_equal([], Primer::OpenProject::Table::RowGroup.new.rows)
  end
end
