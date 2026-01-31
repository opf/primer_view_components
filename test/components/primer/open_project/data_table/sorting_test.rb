# frozen_string_literal: true

require "components/test_helper"

class PrimerOpenProjectDataTableSortingTest < Minitest::Test
  Sorting = Primer::OpenProject::DataTable::Sorting
  UncomparableValue = Data.define(:label) do
    def to_s
      label
    end
  end

  def test_normalize_direction_rejects_unknown_direction
    error = assert_raises(ArgumentError) do
      Sorting.normalize_direction(:sideways)
    end

    assert_includes(error.message, "initial_sort_direction")
  end

  def test_basic_falls_back_to_string_comparison_for_uncomparable_values
    assert_equal(-1, Sorting.basic(UncomparableValue.new("a"), UncomparableValue.new("b")))
  end

  def test_compare_values_uses_datetime_strategy
    assert_equal(-1, Sorting.compare_values(Date.new(2026, 1, 1), Date.new(2026, 1, 2), :datetime))
  end

  def test_datetime_compares_time_like_and_plain_values
    assert_equal(-1, Sorting.datetime(DateTime.new(2026, 1, 1), DateTime.new(2026, 1, 2)))
    assert_equal(1, Sorting.datetime(Date.new(2026, 1, 2), Date.new(2026, 1, 1)))
    assert_equal(0, Sorting.datetime(5, 5))
  end

  def test_alphanumeric_compares_string_and_mixed_groups
    assert_equal(-1, Sorting.alphanumeric("Alpha", "Beta"))
    assert_equal(-1, Sorting.alphanumeric("1", "Alpha"))
    assert_equal(1, Sorting.alphanumeric("Alpha", "1"))
  end

  def test_alphanumeric_compares_equal_and_prefixed_values
    assert_equal(0, Sorting.alphanumeric("Project 7", "Project 7"))
    assert_equal(-1, Sorting.alphanumeric("Project 7", "Project 7a"))
  end
end
