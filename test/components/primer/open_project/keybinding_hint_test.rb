# frozen_string_literal: true

require "components/test_helper"

class PrimerOpenProjectKeybindingHintTest < Minitest::Test
  include Primer::ComponentTestHelpers

  def test_renders_element_with_data_attributes
    render_inline(Primer::OpenProject::KeybindingHint.new(keys: "Mod+Shift+p"))

    assert_selector(
      "keybinding-hint.KeybindingHint" \
      "[data-keys='Mod+Shift+p'][data-format='condensed'][data-scheme='default'][data-size='medium']"
    )
  end

  def test_renders_fallback_text_inside_chord
    render_inline(Primer::OpenProject::KeybindingHint.new(keys: "Mod+Shift+p"))

    assert_selector("keybinding-hint kbd.KeybindingHint-kbd .KeybindingHint-chord[data-kbd-chord]", text: "Ctrl+Shift+P", count: 1)
  end

  def test_renders_one_chord_span_per_sequence_step
    render_inline(Primer::OpenProject::KeybindingHint.new(keys: "g i"))

    assert_selector(".KeybindingHint-chord", count: 2)
    assert_selector(".KeybindingHint-chord", text: "G")
    assert_selector(".KeybindingHint-chord", text: "I")
    refute_text("then")
  end

  def test_fallback_keeps_literal_plus_and_space_keys
    render_inline(Primer::OpenProject::KeybindingHint.new(keys: "Mod+Plus a Space b"))

    assert_selector(".KeybindingHint-chord", text: "Ctrl+Plus")
    assert_selector(".KeybindingHint-chord", text: "A")
    assert_selector(".KeybindingHint-chord", text: "Space")
    assert_selector(".KeybindingHint-chord", text: "B")
  end

  def test_fallback_keeps_internal_capitals_of_named_keys
    render_inline(Primer::OpenProject::KeybindingHint.new(keys: "ArrowUp"))

    assert_selector(".KeybindingHint-chord", exact_text: "ArrowUp")
  end

  def test_scheme_and_size_render_modifier_classes_and_data
    render_inline(Primer::OpenProject::KeybindingHint.new(keys: "Mod+s", scheme: :emphasis, size: :small))

    assert_selector("keybinding-hint[data-scheme='emphasis'][data-size='small']")
    assert_selector(".KeybindingHint-chord.KeybindingHint-chord--emphasis.KeybindingHint-chord--small")
  end

  def test_full_format_is_passed_through
    render_inline(Primer::OpenProject::KeybindingHint.new(keys: "Mod+s", format: :full))

    assert_selector("keybinding-hint[data-format='full']")
  end

  def test_invalid_options_fall_back_to_defaults
    without_fetch_or_fallback_raises do
      render_inline(Primer::OpenProject::KeybindingHint.new(keys: "Mod+s", format: :bogus, scheme: :bogus, size: :bogus))
    end

    assert_selector("keybinding-hint[data-format='condensed'][data-scheme='default'][data-size='medium']")
    refute_selector(".KeybindingHint-chord--emphasis")
    refute_selector(".KeybindingHint-chord--small")
  end

  def test_renders_nothing_with_blank_keys
    render_inline(Primer::OpenProject::KeybindingHint.new(keys: "  "))

    refute_component_rendered
  end

  def test_escapes_fallback_text
    # No literal spaces/plus in the payload: those are chord/sequence
    # separators (see test_renders_one_chord_span_per_sequence_step and
    # test_fallback_keeps_literal_plus_and_space_keys), so this stays one
    # chord and its text round-trips unchanged through fallback_key_name's
    # `capitalize` (non-letter first char, already-lowercase remainder).
    render_inline(Primer::OpenProject::KeybindingHint.new(keys: "<script>alert(1)</script>"))

    refute_selector("script")
    assert_selector(".KeybindingHint-chord", text: "<script>alert(1)</script>")
  end

  def test_passes_system_arguments
    render_inline(Primer::OpenProject::KeybindingHint.new(keys: "Mod+s", classes: "custom", data: { foo: "bar" }, id: "hint"))

    assert_selector("keybinding-hint#hint.KeybindingHint.custom[data-foo='bar'][data-keys='Mod+s']")
  end

  def test_denies_tag_argument
    # deny_tag_argument raises outside production (should_raise_error?)
    assert_raises(ArgumentError) do
      render_inline(Primer::OpenProject::KeybindingHint.new(keys: "Mod+s", tag: :div))
    end
  end
end
