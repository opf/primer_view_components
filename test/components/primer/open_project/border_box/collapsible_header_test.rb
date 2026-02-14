# frozen_string_literal: true

require "components/test_helper"

class Primer::OpenProject::BorderBox::CollapsibleHeaderTest < Minitest::Test
  include Primer::ComponentTestHelpers

  def test_renders_default
    render_preview(:default)

    assert_selector(".CollapsibleHeader", text: "Backlog")
    assert_selector("svg.octicon.octicon-chevron-up", visible: true)
    assert_selector("svg.octicon.octicon-chevron-down", visible: false)
  end

  def test_does_not_render_with_empty_title
    err = assert_raises ArgumentError do
      render_inline(Primer::OpenProject::BorderBox::CollapsibleHeader.new)
    end

    assert_equal "Title must be present", err.message
  end

  def test_collapsible_id_sets_aria_controls
    render_inline(Primer::OpenProject::BorderBox::CollapsibleHeader.new(
      collapsible_id: "body-id list-id",
      toggle_label: "Toggle backlog"
    )) do |header|
      header.with_title { "Backlog" }
    end

    assert_selector(".CollapsibleHeader-triggerArea[aria-controls='body-id list-id']")
  end

  def test_nil_collapsible_id_omits_aria_controls
    render_inline(Primer::OpenProject::BorderBox::CollapsibleHeader.new(
      toggle_label: "Toggle backlog"
    )) do |header|
      header.with_title { "Backlog" }
    end

    assert_no_selector(".CollapsibleHeader-triggerArea[aria-controls]")
  end

  def test_toggle_label_sets_aria_label
    render_inline(Primer::OpenProject::BorderBox::CollapsibleHeader.new(
      collapsible_id: "body-id",
      toggle_label: "Toggle backlog"
    )) do |header|
      header.with_title { "Backlog" }
    end

    assert_selector(".CollapsibleHeader-triggerArea[aria-label='Toggle backlog']")
  end

  def test_toggle_label_defaults_to_i18n_string
    render_inline(Primer::OpenProject::BorderBox::CollapsibleHeader.new(
      collapsible_id: "body-id"
    )) do |header|
      header.with_title { "Backlog" }
    end

    assert_selector(".CollapsibleHeader-triggerArea[aria-label='Toggle section']")
  end

  def test_renders_with_description
    render_preview(:with_description)

    assert_selector(".CollapsibleHeader .color-fg-subtle",
                    text: "This backlog is unique to this one-time meeting. You can drag items in and out to add or remove them from the meeting agenda.")
    assert_selector(".CollapsibleHeader .color-fg-subtle", visible: true)
  end

  def test_renders_with_count
    render_preview(:with_count)

    assert_selector(".CollapsibleHeader .Counter", text: "42")
  end

  def test_renders_collapsed
    render_preview(:collapsed)

    assert_selector(".CollapsibleHeader.CollapsibleHeader--collapsed", text: "Backlog")
  end
end
