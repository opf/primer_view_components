# frozen_string_literal: true

require "components/test_helper"

class PrimerOpenProjectInlineMessageTest < Minitest::Test
  include Primer::ComponentTestHelpers

  def test_renders_with_content
    render_inline(Primer::OpenProject::InlineMessage.new(scheme: :warning)) do
      "Important Message"
    end

    assert_selector(".InlineMessage")
    assert_selector(".InlineMessageIcon")
    assert_text("Important Message")
  end

  def test_renders_nothing_with_blank_content
    render_inline(Primer::OpenProject::InlineMessage.new(scheme: :warning)) do
      " "
    end

    refute_component_rendered
  end

  def test_default_size_warning_scheme
    render_inline(Primer::OpenProject::InlineMessage.new(scheme: :warning)) do
      "Important Message"
    end

    assert_selector(".InlineMessage[data-size='medium'][data-variant='warning']")
    assert_selector("svg.octicon-alert")
  end

  def test_default_size_critical_scheme
    render_inline(Primer::OpenProject::InlineMessage.new(scheme: :critical)) do
      "Important Message"
    end

    assert_selector(".InlineMessage[data-size='medium'][data-variant='critical']")
    assert_selector("svg.octicon-alert")
  end

  def test_default_size_success_scheme
    render_inline(Primer::OpenProject::InlineMessage.new(scheme: :success)) do
      "Important Message"
    end

    assert_selector(".InlineMessage[data-size='medium'][data-variant='success']")
    assert_selector("svg.octicon-check-circle")
  end

  def test_default_size_unavailable_scheme
    render_inline(Primer::OpenProject::InlineMessage.new(scheme: :unavailable)) do
      "Important Message"
    end

    assert_selector(".InlineMessage[data-size='medium'][data-variant='unavailable']")
    assert_selector("svg.octicon-alert")
  end

  def test_small_size_warning_scheme
    render_inline(Primer::OpenProject::InlineMessage.new(scheme: :warning, size: :small)) do
      "Important Message"
    end

    assert_selector(".InlineMessage[data-size='small'][data-variant='warning']")
    assert_selector("svg.octicon-alert-fill")
  end

  def test_small_size_critical_scheme
    render_inline(Primer::OpenProject::InlineMessage.new(scheme: :critical, size: :small)) do
      "Important Message"
    end

    assert_selector(".InlineMessage[data-size='small'][data-variant='critical']")
    assert_selector("svg.octicon-alert-fill")
  end

  def test_small_size_success_scheme
    render_inline(Primer::OpenProject::InlineMessage.new(scheme: :success, size: :small)) do
      "Important Message"
    end

    assert_selector(".InlineMessage[data-size='small'][data-variant='success']")
    assert_selector("svg.octicon-check-circle-fill")
  end

  def test_small_size_unavailable_scheme
    render_inline(Primer::OpenProject::InlineMessage.new(scheme: :unavailable, size: :small)) do
      "Important Message"
    end

    assert_selector(".InlineMessage[data-size='small'][data-variant='unavailable']")
    assert_selector("svg.octicon-alert-fill")
  end
end
