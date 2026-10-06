# frozen_string_literal: true

require "system/test_case"

class IntegrationOpenProjectColorFieldTest < System::TestCase
  include Primer::JsTestHelpers

  SWATCH_METRICS = <<~JS
    (() => {
      const text = document.querySelector('primer-color-input input[type=text]')
      const input = text.getBoundingClientRect()
      const picker = document.querySelector('primer-color-input input[type=color]').getBoundingClientRect()

      return {
        width: picker.width,
        height: picker.height,
        insideInline: picker.left >= input.left && picker.right <= input.right,
        insideBlock: picker.top >= input.top && picker.bottom <= input.bottom,
        textPadding: getComputedStyle(text).paddingInlineStart
      }
    })()
  JS

  def test_swatch_sits_inside_the_text_input_at_every_size
    %i[small medium large].each do |size|
      visit_preview(:playground, size: size)

      metrics = page.evaluate_script(SWATCH_METRICS)

      assert_equal 24, metrics["width"], "swatch width at #{size}"
      assert_equal 24, metrics["height"], "swatch height at #{size}"
      assert metrics["insideInline"], "swatch outside the text input horizontally at #{size}"
      assert metrics["insideBlock"], "swatch outside the text input vertically at #{size}"
      assert_equal "36px", metrics["textPadding"], "text padding at #{size}"
    end
  end

  # Spacing between fields must come from their container. A margin passed
  # to the field lands on the text input and pulls it away from the swatch.
  def test_swatches_stay_centred_on_their_inputs_when_fields_are_stacked
    visit_preview(:multiple)

    fields = page.evaluate_script(<<~JS)
      [...document.querySelectorAll('primer-color-input')].map(element => {
        const input = element.querySelector('input[type=text]').getBoundingClientRect()
        const picker = element.querySelector('input[type=color]').getBoundingClientRect()

        return {
          inputTop: input.top,
          inputBottom: input.bottom,
          inputCentre: input.top + input.height / 2,
          pickerCentre: picker.top + picker.height / 2
        }
      })
    JS

    assert_equal 2, fields.size
    fields.each_with_index do |field, index|
      assert_in_delta field["inputCentre"], field["pickerCentre"], 0.5, "swatch off centre in field #{index + 1}"
    end
    assert_operator fields[1]["inputTop"], :>, fields[0]["inputBottom"], "fields overlap"
  end

  # Catalyst sets data-catalyst once the controller has initialised.
  def visit_color_field(scenario, **params)
    visit_preview(scenario, **params)
    assert_selector "primer-color-input[data-catalyst]"
  end

  def text_input(scope = "primer-color-input")
    find("#{scope} input[type=text]")
  end

  def picker_value(scope = "primer-color-input")
    page.evaluate_script("document.querySelector(#{"#{scope} input[type=color]".to_json}).value")
  end

  # Replaces the whole text the way a paste over a selection would: one
  # value change followed by one input event.
  def replace_text(text, scope = "primer-color-input")
    evaluate_multiline_script(<<~JS)
      const input = document.querySelector(#{"#{scope} input[type=text]".to_json})
      input.value = #{text.to_json}
      input.dispatchEvent(new Event('input', {bubbles: true}))
    JS
  end

  # Dispatches the event a real paste starts with. A scripted event has no
  # default insertion, so only text the controller inserts itself shows up.
  def paste(text, scope = "primer-color-input")
    evaluate_multiline_script(<<~JS)
      const clipboardData = new DataTransfer()
      clipboardData.setData('text/plain', #{text.to_json})

      document.querySelector(#{"#{scope} input[type=text]".to_json}).dispatchEvent(
        new ClipboardEvent('paste', {clipboardData, bubbles: true, cancelable: true})
      )
    JS
  end

  def test_typing_valid_hex_updates_picker_without_rewriting_text
    visit_color_field(:blank_without_placeholder)

    text_input.click
    text_input.send_keys("#1a67a3")

    assert_equal "#1a67a3", picker_value
    assert_equal "#1a67a3", text_input.value
    assert_selector "primer-color-input:not([data-blank]):not([data-empty])"
  end

  def test_blur_normalizes_valid_text
    visit_color_field(:blank_without_placeholder)

    text_input.click
    text_input.send_keys("1a6", :tab)

    assert_equal "#11AA66", text_input.value
    assert_equal "#11aa66", picker_value
  end

  def test_pasted_value_with_whitespace
    visit_color_field(:blank_without_placeholder)

    text_input.click
    text_input.send_keys(" 1A67A3 ")

    assert_equal "#1a67a3", picker_value

    text_input.send_keys(:tab)

    assert_equal "#1A67A3", text_input.value
  end

  # The browser cuts a paste to `maxlength` before any script sees the text,
  # so padding has to go while the paste is still an event.
  def test_pasting_padded_hex_is_trimmed
    visit_color_field(:blank_without_placeholder)

    text_input.click
    paste(" #1a67a3 ")

    assert_equal "#1a67a3", text_input.value
    assert_equal "#1a67a3", picker_value

    text_input.send_keys(:tab)

    assert_equal "#1A67A3", text_input.value
  end

  def test_pasting_padded_text_stops_at_seven_characters
    visit_color_field(:blank_without_placeholder)

    text_input.click
    paste(" #1a67a3ff ")

    assert_equal "#1a67a3", text_input.value
  end

  def test_pasting_replaces_the_selection
    visit_color_field(:default)

    text_input.click
    evaluate_multiline_script("document.querySelector('primer-color-input input[type=text]').select()")
    paste("\t#00ff00\n")

    assert_equal "#00ff00", text_input.value
    assert_equal "#00ff00", picker_value
  end

  def test_pasting_into_readonly_field_changes_nothing
    visit_color_field(:readonly)

    text_input.click
    paste(" #00ff00 ")

    assert_equal "#1A67A3", text_input.value
  end

  def test_typing_stops_at_seven_characters
    visit_color_field(:blank_without_placeholder)

    text_input.click
    text_input.send_keys("#1a67a3ff")

    assert_equal "#1a67a3", text_input.value
    assert_equal "#1a67a3", picker_value
  end

  def test_invalid_text_keeps_last_color_and_is_left_alone
    visit_color_field(:blank_without_placeholder)

    text_input.click
    text_input.send_keys("#00ff00")
    assert_equal "#00ff00", picker_value

    # Typed for real, so that leaving the field fires a genuine change event.
    text_input.send_keys(:backspace, "z")

    assert_equal "#00ff00", picker_value
    assert_selector "primer-color-input:not([data-blank]):not([data-empty])"

    text_input.send_keys(:tab)

    assert_equal "#00ff0z", text_input.value
  end

  # A listener further up, such as one that autosaves the form, must hear of
  # a pick once, from the text input, and not a second time from the picker.
  def test_picker_writes_text_and_fires_bubbling_events
    visit_color_field(:blank_without_placeholder)

    evaluate_multiline_script(<<~JS)
      window.colorFieldEvents = []

      for (const type of ['input', 'change']) {
        document.addEventListener(type, event => {
          window.colorFieldEvents.push(`${type} from ${event.target.type}`)
        })
      }

      const picker = document.querySelector('input[type=color]')
      picker.value = '#00ff00'
      picker.dispatchEvent(new Event('input', {bubbles: true}))
      picker.dispatchEvent(new Event('change', {bubbles: true}))
    JS

    assert_equal "#00FF00", text_input.value
    assert_equal ["input from text", "change from text"], page.evaluate_script("window.colorFieldEvents")
    assert_selector "primer-color-input:not([data-blank]):not([data-empty])"
  end

  def test_blank_with_placeholder_on_first_paint
    visit_color_field(:blank_with_placeholder)

    assert_selector "primer-color-input[data-blank]:not([data-empty])"
    assert_equal "", text_input.value
    assert_equal "#1a67a3", picker_value
  end

  def test_blank_without_placeholder_on_first_paint
    visit_color_field(:blank_without_placeholder)

    assert_selector "primer-color-input[data-blank][data-empty]"
    assert_equal "", text_input.value
  end

  def test_clearing_text_restores_blank_state
    visit_color_field(:default)
    assert_selector "primer-color-input:not([data-blank])"

    replace_text("")

    assert_selector "primer-color-input[data-blank][data-empty]"
    assert_equal "", text_input.value

    replace_text("#35C53F")

    assert_selector "primer-color-input:not([data-blank]):not([data-empty])"
    assert_equal "#35c53f", picker_value
  end

  def test_invalid_server_value_keeps_neutral_swatch
    visit_color_field(:invalid)

    assert_selector "primer-color-input[data-empty]:not([data-blank])"
    assert_equal "zzz", text_input.value
  end

  def test_form_reset_resyncs_picker
    visit_color_field(:in_form)

    replace_text("#00FF00")
    assert_equal "#00ff00", picker_value

    click_button "Reset"

    assert_field "Primary color", with: "#1A67A3"
    assert_equal "#1a67a3", picker_value
  end

  # Invalid text keeps the last color, but a reset leaves no last color to
  # keep: the swatch must go back to how the server rendered it.
  def test_form_reset_restores_neutral_swatch_for_invalid_initial_value
    visit_color_field(:in_form, value: "zzz")
    assert_selector "primer-color-input[data-empty]:not([data-blank])"

    replace_text("#00FF00")
    assert_selector "primer-color-input:not([data-empty])"

    click_button "Reset"

    assert_field "Primary color", with: "zzz"
    assert_selector "primer-color-input[data-empty]:not([data-blank])"
  end

  def test_cancelled_form_reset_keeps_last_color
    visit_color_field(:in_form)

    replace_text("#00FF00")
    replace_text("zzz")
    evaluate_multiline_script(<<~JS)
      const form = document.querySelector('primer-color-input input[type=text]').form
      form.addEventListener('reset', (event) => event.preventDefault())
    JS

    click_button "Reset"
    # The controller reacts a tick after the event; let that tick pass.
    page.evaluate_async_script("setTimeout(arguments[0])")

    assert_field "Primary color", with: "zzz"
    assert_selector "primer-color-input:not([data-empty])"
    assert_equal "#00ff00", picker_value
  end

  def test_picker_is_enabled_after_upgrade_and_follows_the_text_input_in_tab_order
    visit_color_field(:default)

    assert_selector "input[type=color]:enabled"

    text_input.click
    text_input.send_keys(:tab)

    assert_equal "color", page.evaluate_script("document.activeElement.type")
  end

  def test_picker_stays_disabled_for_disabled_field
    visit_color_field(:disabled)

    assert_selector "input[type=color]:disabled"
  end

  def test_picker_stays_disabled_for_readonly_field
    visit_color_field(:readonly)

    assert_selector "input[type=color]:disabled"
  end

  # A Turbo morph syncs the server-rendered `disabled` back onto the live
  # picker (idiomorph's syncInputValue) without reconnecting the element.
  def test_picker_is_reenabled_after_its_disabled_attribute_is_rewritten
    visit_color_field(:default)
    assert_selector "input[type=color]:enabled"

    evaluate_multiline_script(<<~JS)
      document.querySelector('input[type=color]').disabled = true
    JS

    assert_selector "input[type=color]:enabled"
  end

  def test_picker_follows_later_changes_to_the_text_input
    visit_color_field(:default)

    evaluate_multiline_script(<<~JS)
      document.querySelector('primer-color-input input[type=text]').disabled = true
    JS
    assert_selector "input[type=color]:disabled"

    evaluate_multiline_script(<<~JS)
      const input = document.querySelector('primer-color-input input[type=text]')
      input.disabled = false
      input.readOnly = true
    JS
    assert_selector "input[type=color]:disabled"

    evaluate_multiline_script(<<~JS)
      document.querySelector('primer-color-input input[type=text]').readOnly = false
    JS
    assert_selector "input[type=color]:enabled"
  end

  # Inside `multi` the input renders without its FormControl wrapper, and
  # the multi controller disables and hides whichever field is inactive.
  def test_works_inside_multi
    visit_color_field(:in_multi)

    assert_selector "input[type=color]:enabled"

    replace_text("#00FF00")
    assert_equal "#00ff00", picker_value

    evaluate_multiline_script(<<~JS)
      document.querySelector('primer-multi-input').activateField('token')
    JS
    assert_selector "input[type=color]:disabled", visible: :all

    evaluate_multiline_script(<<~JS)
      document.querySelector('primer-multi-input').activateField('hex')
    JS
    assert_selector "input[type=color]:enabled"
  end

  def test_fields_do_not_cross_talk
    visit_color_field(:multiple)

    replace_text("#00FF00", "primer-color-input:has(#primary)")

    assert_equal "#00ff00", picker_value("primer-color-input:has(#primary)")
    assert_equal "#35c53f", picker_value("primer-color-input:has(#accent)")
    assert_equal "#35C53F", text_input("primer-color-input:has(#accent)").value
    assert_selector "input[type=color][aria-label='Pick color for Primary color']"
    assert_selector "input[type=color][aria-label='Pick color for Accent color']"
  end
end
