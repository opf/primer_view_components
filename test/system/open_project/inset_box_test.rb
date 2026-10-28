# frozen_string_literal: true

require "system/test_case"

class IntegrationOpenProjectInsetBoxTest < System::TestCase
  def test_renders_component
    visit_preview(:default)

    assert_selector(".InsetBox")
    assert_text("Title")
  end

  def test_renders_with_actions
    visit_preview(:with_actions)

    assert_selector(".InsetBox--body--actions button", text: "Action")
  end

  def test_renders_with_clipboard_copy_button
    visit_preview(:with_clipboard_copy_button)

    assert_selector(".InsetBox--body--clip_board_copy clipboard-copy")
  end
end
