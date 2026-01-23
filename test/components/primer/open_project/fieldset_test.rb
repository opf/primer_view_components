# frozen_string_literal: true

require "components/test_helper"

class PrimerOpenProjectFieldsetTest < Minitest::Test
  include Primer::ComponentTestHelpers


  def test_renders_fieldset_with_legend_slot_and_text_param
    render_inline(Primer::OpenProject::Fieldset.new) do |component|
      component.with_legend(text: "My legend")
      "Fieldset content"
    end

    assert_selector("fieldset") do
      assert_selector("legend", text: "My legend")
      assert_text("Fieldset content")
    end
  end

  def test_renders_fieldset_with_legend_slot_and_content
    render_inline(Primer::OpenProject::Fieldset.new) do |component|
      component.with_legend { "My legend" }
      "Fieldset content"
    end

    assert_selector("fieldset") do
      assert_selector("legend", text: "My legend")
      assert_text("Fieldset content")
    end
  end

  def test_renders_fieldset_with_legend_text_param
    render_inline(Primer::OpenProject::Fieldset.new(legend_text: "My legend")) do
      "Fieldset content"
    end

    assert_selector("fieldset") do
      assert_selector("legend", text: "My legend")
      assert_text("Fieldset content")
    end
  end

  def test_renders_nothing_without_legend_slot_or_legend_text
    render_inline(Primer::OpenProject::Fieldset.new) do
      "Fieldset content"
    end

    refute_component_rendered
  end

  def test_renders_nothing_without_content
    render_inline(Primer::OpenProject::Fieldset.new(legend_text: "My legend"))

    refute_component_rendered
  end
end
