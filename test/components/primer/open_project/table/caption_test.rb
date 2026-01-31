# frozen_string_literal: true

require "components/test_helper"

class PrimerOpenProjectTableCaptionTest < Minitest::Test
  include Primer::ComponentTestHelpers

  def render_component(**kwargs, &block)
    render_inline(Primer::OpenProject::Table::Caption.new(**kwargs), &block)

    # bypass Nokogiri::HTML5.fragment https://github.com/sparklemotion/nokogiri/issues/3536
    @rendered_content
  end

  def test_renders_caption_with_content
    render_component { "Caption content" }

    assert_selector("caption", text: "Caption content")
  end

  def test_renders_caption_with_text
    render_component(text: "Caption text")

    assert_selector("caption", text: "Caption text")
  end

  def test_renders_nothing_without_content_or_text
    rendered = render_component

    assert rendered.to_s.blank?
  end
end
