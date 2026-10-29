# frozen_string_literal: true

require "system/test_case"

class IntegrationOpenProjectColorSwatchTest < System::TestCase
  def test_renders_component
    visit_preview(:default)

    assert_selector(".ColorSwatch")
    assert_selector(".ColorSwatch--indicator")
  end

  def test_renders_with_value
    visit_preview(:with_value)

    assert_selector(".ColorSwatch")
    assert_text("#CC0000")
  end
end
