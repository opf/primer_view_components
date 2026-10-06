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
end
