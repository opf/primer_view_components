# frozen_string_literal: true

require "lib/test_helper"
require_relative "models/deep_thought"

class Primer::Forms::ColorFieldInputTest < Minitest::Test
  include Primer::ComponentTestHelpers

  def render_color_field(**arguments)
    render_in_view_context do
      primer_form_with(url: "/foo") do |f|
        render_inline_form(f) do |form|
          form.color_field(name: :hexcode, label: "Primary", **arguments)
        end
      end
    end
  end

  def test_parse_hex
    parse = Primer::Forms::Dsl::ColorFieldInput.method(:parse_hex)

    assert_equal "#1A67A3", parse.call("#1a67a3")
    assert_equal "#1A67A3", parse.call("1A67A3")
    assert_equal "#1A67A3", parse.call("  1a67a3\n")
    assert_equal "#11AA66", parse.call("#1a6")
    assert_equal "#11AA66", parse.call("1A6")

    assert_nil parse.call(nil)
    assert_nil parse.call("")
    assert_nil parse.call("zzz")
    assert_nil parse.call("#12")
    assert_nil parse.call("#12345")
    assert_nil parse.call("#1a67a3ff")
    assert_nil parse.call("rgb(1, 2, 3)")
    assert_nil parse.call("red")
  end

  def test_only_the_text_input_is_submitted
    render_color_field(value: "#1A67A3")

    assert_selector "input[type=text][name=hexcode][value='#1A67A3']"
    assert_selector "input[type=color]:not([name])"
  end

  def test_wrapper_element_and_classes
    render_color_field

    assert_selector "div.FormControl > primer-color-input.ColorField"
    assert_selector "primer-color-input > div.FormControl-input-wrap.ColorField-wrap"
    assert_selector "input[type=text].FormControl-input.FormControl-monospace.FormControl-medium"
    assert_selector "span.ColorField-swatch > input[type=color].ColorField-picker"
  end

  def test_text_input_precedes_picker_in_dom
    render_color_field

    assert_selector "input[type=text] + span.ColorField-swatch"
  end

  def test_size_and_input_width
    render_color_field(size: :small, input_width: :medium)

    assert_selector "div.FormControl-input-wrap--small.FormControl-input-width--medium"
    assert_selector "input[type=text].FormControl-small"
  end

  def test_picker_value_from_value
    render_color_field(value: "#1a67a3", placeholder: "#000000")

    assert_selector "input[type=color][value='#1A67A3']"
  end

  def test_picker_value_expands_short_and_unprefixed_hex
    render_color_field(value: "1a6")

    assert_selector "input[type=color][value='#11AA66']"
  end

  def test_picker_value_from_placeholder_when_blank
    render_color_field(placeholder: "#1a67a3")

    assert_selector "input[type=color][value='#1A67A3']"
  end

  def test_picker_value_omitted_without_any_color
    render_color_field

    assert_selector "input[type=color]:not([value])"
  end

  def test_state_with_value
    render_color_field(value: "#1A67A3")

    assert_selector "primer-color-input:not([data-blank]):not([data-empty])"
  end

  def test_state_blank_with_placeholder
    render_color_field(placeholder: "#1A67A3")

    assert_selector "primer-color-input[data-blank]:not([data-empty])"
  end

  def test_state_blank_without_placeholder
    render_color_field

    assert_selector "primer-color-input[data-blank][data-empty]"
  end

  def test_whitespace_only_value_is_blank
    render_color_field(value: "  ")

    assert_selector "primer-color-input[data-blank][data-empty]"
  end

  def test_invalid_value_has_no_swatch_color
    render_color_field(value: "zzz", placeholder: "#1A67A3")

    assert_selector "primer-color-input[data-empty]:not([data-blank])"
    assert_selector "input[type=text][value='zzz']"
    assert_selector "input[type=color]:not([value])"
  end

  def test_value_from_model_object
    model = DeepThought.new("#abc")

    render_in_view_context do
      primer_form_with(model: model, url: "/foo") do |f|
        render_inline_form(f) do |form|
          form.color_field(name: :ultimate_answer, label: "Primary")
        end
      end
    end

    assert_selector "input[type=text][value='#abc']"
    assert_selector "input[type=color][value='#AABBCC']"
    assert_selector "primer-color-input:not([data-blank]):not([data-empty])"
  end

  def test_picker_is_always_rendered_disabled
    [{}, { value: "#1A67A3" }, { placeholder: "#1A67A3" }, { disabled: true }, { readonly: true }].each do |arguments|
      render_color_field(**arguments)

      assert_selector "input[type=color][disabled]", message: "picker not disabled for #{arguments.inspect}"
    end
  end

  def test_disabled_disables_the_text_input
    render_color_field(disabled: true)

    assert_selector "input[type=text][disabled]"
  end

  def test_readonly_leaves_the_text_input_enabled
    render_color_field(readonly: true)

    assert_selector "input[type=text][readonly]:not([disabled])"
  end

  def test_default_picker_label_interpolates_the_field_label
    render_color_field

    assert_selector "input[type=color][aria-label='Pick color for Primary']"
  end

  def test_picker_label_override
    render_color_field(picker_label: "Choose primary")

    assert_selector "input[type=color][aria-label='Choose primary']"
    refute_selector "input[type=text][picker_label]"
  end

  def test_label_caption_and_validation_point_at_the_text_input
    render_color_field(caption: "Six hex digits", validation_message: "Hex code is invalid")

    assert_selector "label[for=hexcode]", text: "Primary"
    assert_selector "input[type=text]#hexcode[aria-describedby][aria-invalid=true]"
    assert_selector ".FormControl-caption", text: "Six hex digits"
    assert_selector ".FormControl-inlineValidation", text: "Hex code is invalid"
  end

  def test_catalyst_bindings
    render_color_field

    assert_selector "input[type=text][data-target~='primer-color-input.inputElement']"
    assert_selector "input[type=text][data-action~='input:primer-color-input#syncPicker'][data-action~='change:primer-color-input#normalize']"
    assert_selector "input[type=text][data-action~='paste:primer-color-input#trimPaste']"
    assert_selector "input[type=color][data-target='primer-color-input.pickerElement']"
    assert_selector "input[type=color][data-action~='input:primer-color-input#syncInput'][data-action~='change:primer-color-input#commit']"
  end

  def test_preserves_caller_data_attributes
    render_color_field(data: { target: "my-form.color", action: "input:my-form#preview", variable_name: "primary" })

    assert_selector "input[type=text][data-target~='primer-color-input.inputElement'][data-target~='my-form.color']"
    assert_selector "input[type=text][data-action~='input:primer-color-input#syncPicker'][data-action~='input:my-form#preview']"
    assert_selector "input[type=text][data-variable-name=primary]"
  end

  def test_autocomplete_defaults_to_off
    render_color_field

    assert_selector "input[type=text][autocomplete=off]"
  end

  def test_autocomplete_can_be_overridden
    render_color_field(autocomplete: "on")

    assert_selector "input[type=text][autocomplete=on]"
  end

  def test_maxlength_defaults_to_seven
    render_color_field

    assert_selector "input[type=text][maxlength='7']"
  end

  def test_maxlength_can_be_overridden
    render_color_field(maxlength: 9)

    assert_selector "input[type=text][maxlength='9']"
  end

  def test_hidden
    render_color_field(hidden: true)

    assert_selector "div.FormControl[hidden]", visible: :hidden
    assert_selector "primer-color-input > div.ColorField-wrap[hidden]", visible: :hidden
  end

  # `form_control: false` drops the label and validation wrapper. The custom
  # element must survive it, or nothing ever enables the picker.
  def test_element_is_rendered_without_form_control
    render_color_field(form_control: false)

    refute_selector ".FormControl"
    refute_selector "label"
    assert_selector "primer-color-input.ColorField[data-blank] input[type=text][name=hexcode]"
    assert_selector "primer-color-input.ColorField input[type=color][disabled]"
  end

  # `multi` renders its inputs without form control and without a label, and
  # its controller toggles `hidden` on the field's parent element.
  def test_inside_multi
    render_in_view_context do
      primer_form_with(url: "/foo") do |f|
        render_inline_form(f) do |form|
          form.multi(name: :color, label: "Color") do |multi|
            multi.color_field(name: :hex, value: "#1A67A3")
            multi.text_field(name: :token, hidden: true)
          end
        end
      end
    end

    assert_selector "primer-multi-input primer-color-input.ColorField"
    assert_selector "primer-color-input > .ColorField-wrap > input[type=text][data-name=hex][data-targets~='primer-multi-input.fields']"
    assert_selector "input[type=color][disabled][value='#1A67A3'][aria-label='Pick color']"
  end
end
