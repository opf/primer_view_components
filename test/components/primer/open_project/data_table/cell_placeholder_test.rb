# frozen_string_literal: true

require "components/test_helper"

class PrimerOpenProjectDataTableCellPlaceholderTest < Minitest::Test
  include Primer::ComponentTestHelpers

  def test_renders_muted_span
    render_inline(Primer::OpenProject::DataTable::CellPlaceholder.new) { "Not configured" }

    assert_selector("span.TableCellPlaceholder", text: "Not configured")
  end

  def test_passes_through_system_arguments
    render_inline(Primer::OpenProject::DataTable::CellPlaceholder.new(classes: "custom")) { "None" }

    assert_selector("span.TableCellPlaceholder.custom", text: "None")
  end
end
