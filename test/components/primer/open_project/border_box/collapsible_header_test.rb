# frozen_string_literal: true

require "components/test_helper"

class Primer::OpenProject::BorderBox::CollapsibleHeaderTest < Minitest::Test
  include Primer::ComponentTestHelpers

  def test_renders_default
    render_preview(:default)

    assert_selector(".CollapsibleHeader", text: "Default title")
    assert_selector("svg.up-icon")
    assert_selector("svg.down-icon.d-none")
  end

  def does_not_render_without_title_and_box
    render_inline(Primer::OpenProject::BorderBox::CollapsibleHeader.new())

    refute_component_rendered
  end

  def does_not_render_without_valid_box
    render_inline(Primer::OpenProject::BorderBox::CollapsibleHeader.new(title: "Test title", box: "Some component"))

    refute_component_rendered
  end


end
