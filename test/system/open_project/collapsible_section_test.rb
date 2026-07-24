# frozen_string_literal: true

require "system/test_case"

class IntegrationOpenProjectCollapsibleSectionTest < System::TestCase
  def test_renders_component
    visit_preview(:default)

    assert_selector(".CollapsibleSection")
  end

  def test_renders_collapsed
    visit_preview(:collapsed)

    assert_selector(".octicon.octicon-chevron-up", visible: false)
    assert_selector(".octicon.octicon-chevron-down", visible: true)
    assert_no_text("How did you hear about us?")
  end

  def test_click_behaviour
    visit_preview(:default)

    trigger = find('.CollapsibleSection--triggerArea')
    toggle_button = find('.CollapsibleSection--triggerArea [data-collapsible-toggle]')

    # Check aria-expanded is true when expanded
    assert_equal "true", toggle_button[:'aria-expanded']

    # Check aria-controls is present and not empty
    assert toggle_button[:'aria-controls'].present?, "Expected aria-controls attribute to be present"

    controlled_id = toggle_button[:'aria-controls']
    assert_selector("##{controlled_id}", visible: true)

    # First, make sure it is not collapsed
    assert_no_selector(".CollapsibleSection--collapsed")
    assert_selector(".octicon.octicon-chevron-down", visible: false)
    assert_selector(".octicon.octicon-chevron-up", visible: true)
    assert_text("How did you hear about us?")

    # Collapse it
    trigger.click

    assert_selector(".CollapsibleSection--collapsed")
    assert_selector(".octicon.octicon-chevron-up", visible: false)
    assert_selector(".octicon.octicon-chevron-down", visible: true)
    assert_no_text("How did you hear about us?")

    # aria-expanded should now be false
    assert_equal "false", toggle_button[:'aria-expanded']

    # Controlled element should now be hidden
    assert_selector("##{controlled_id}", visible: false)

    # Expand it again
    trigger.click

    assert_no_selector(".CollapsibleSection--collapsed")
    assert_selector(".octicon.octicon-chevron-down", visible: false)
    assert_selector(".octicon.octicon-chevron-up", visible: true)
    assert_text("How did you hear about us?")

    # aria-expanded should be true again
    toggle_button = find('.CollapsibleSection--triggerArea [data-collapsible-toggle]')
    assert_equal "true", toggle_button[:'aria-expanded']
    assert_selector("##{controlled_id}", visible: true)
  end

  def test_link_in_title_does_not_collapse
    visit_preview(:with_link_in_title)

    assert_no_selector(".CollapsibleSection--collapsed")

    # Clicking the trigger area (not the link) should still collapse
    trigger = find(".CollapsibleSection--triggerArea")
    trigger.click
    assert_selector(".CollapsibleSection--collapsed")

    # Expand again
    trigger.click
    assert_no_selector(".CollapsibleSection--collapsed")

    # Clicking the link should NOT collapse the section
    find(".CollapsibleSection--triggerArea a").click
    assert_no_selector(".CollapsibleSection--collapsed")
  end
end
