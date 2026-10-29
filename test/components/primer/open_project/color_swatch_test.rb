# frozen_string_literal: true

require "components/test_helper"

class PrimerOpenProjectColorSwatchTest < Minitest::Test
  include Primer::ComponentTestHelpers

  def test_renders
    render_inline(Primer::OpenProject::ColorSwatch.new(hexcode: "#CC0000"))

    assert_selector(".ColorSwatch")
    assert_selector(".ColorSwatch--indicator[style='background-color: #CC0000']")
    refute_text("#CC0000")
  end

  def test_renders_with_value
    render_inline(Primer::OpenProject::ColorSwatch.new(hexcode: "#CC0000", show_value: true))

    assert_selector(".ColorSwatch")
    assert_text("#CC0000")
  end
end
