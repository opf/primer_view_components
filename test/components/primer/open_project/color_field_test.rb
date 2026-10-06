# frozen_string_literal: true

require "components/test_helper"

class PrimerOpenProjectColorFieldTest < Minitest::Test
  include Primer::ComponentTestHelpers

  def test_renders
    render_inline(Primer::OpenProject::ColorField.new(name: :hexcode, label: "Primary", value: "#1A67A3"))

    assert_selector("div.FormControl") do
      assert_selector("label", text: "Primary")
      assert_selector("primer-color-input.ColorField input[type=text][name=hexcode][value='#1A67A3']")
      assert_selector("primer-color-input.ColorField input[type=color][disabled][value='#1A67A3']:not([name])")
    end
  end

  def test_renders_blank_with_placeholder
    render_inline(Primer::OpenProject::ColorField.new(name: :hexcode, label: "Primary", placeholder: "#1A67A3"))

    assert_selector("primer-color-input[data-blank]:not([data-empty])")
    assert_selector("input[type=text][placeholder='#1A67A3']:not([value])")
  end
end
