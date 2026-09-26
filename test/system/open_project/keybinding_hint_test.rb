# frozen_string_literal: true

require "system/test_case"

# Class name matters: System::TestCase derives the preview path
# primer/open_project/keybinding_hint/<scenario> from it.
class IntegrationOpenProjectKeybindingHintTest < System::TestCase
  VISIBLE = "keybinding-hint .KeybindingHint-chord [aria-hidden='true']"
  HIDDEN = "keybinding-hint .KeybindingHint-chord .sr-only"

  def test_upgrades_fallback_into_per_key_spans
    visit_preview(:default)

    assert_selector("keybinding-hint kbd.KeybindingHint-kbd", count: 1)
    assert_selector(VISIBLE, text: "⌃")
    assert_selector(VISIBLE, text: "⇧")
    assert_selector(VISIBLE, text: "P")
    assert_no_text("Ctrl+Shift+P")
  end

  def test_apple_platform_uses_command_glyph_and_name
    visit_preview(:playground, keys: "Mod+Shift+p", platform: "apple")

    assert_selector(VISIBLE, text: "⌘")
    assert_selector(HIDDEN, text: "command", visible: :all)
    assert_selector(HIDDEN, text: "shift", visible: :all)
    assert_selector(HIDDEN, text: "p", visible: :all)
  end

  def test_windows_and_other_platforms_use_control_for_mod
    visit_preview(:playground, keys: "Mod+p", platform: "windows")
    assert_selector(VISIBLE, text: "⌃")
    assert_selector(HIDDEN, text: "control", visible: :all)

    visit_preview(:playground, keys: "Mod+p", platform: "other")
    assert_selector(VISIBLE, text: "⌃")
  end

  def test_meta_differs_from_mod_on_windows_and_other
    visit_preview(:playground, keys: "Meta+p", platform: "windows")
    assert_selector(VISIBLE, text: "Win")

    visit_preview(:playground, keys: "Meta+p", platform: "other")
    assert_selector(VISIBLE, text: "Meta")
  end

  def test_keys_are_lowercased_and_modifiers_sorted
    visit_preview(:playground, keys: "P+Shift+Mod", platform: "apple")

    glyphs = all(VISIBLE).map(&:text)
    assert_equal ["⌘", "⇧", "P"], glyphs
  end

  def test_mod_sorts_as_its_platform_modifier
    # React sorts `mod` last (no priority). We resolve it first: control(1) < shift(5) on non-apple.
    visit_preview(:playground, keys: "Shift+Mod+p", platform: "other")

    assert_equal ["⌃", "⇧", "P"], all(VISIBLE).map(&:text)
  end

  def test_full_format_spells_keys_and_shows_plus
    visit_preview(:playground, keys: "Mod+Shift+p", format: "full", platform: "apple")

    assert_selector(VISIBLE, text: "Command")
    assert_selector(VISIBLE, text: "Shift")
    assert_selector(VISIBLE, text: "+", count: 2)
    assert_selector(HIDDEN, text: "command", visible: :all)
  end

  def test_condensed_format_has_no_visible_plus
    visit_preview(:playground, keys: "Mod+Shift+p", platform: "apple")

    refute_selector(VISIBLE, text: "+")
  end

  def test_sequence_renders_hidden_then_between_chords
    visit_preview(:sequence)

    assert_selector("keybinding-hint .KeybindingHint-chord", count: 2)
    hidden = all("keybinding-hint .sr-only", visible: :all).map { |node| node.text(:all) }
    assert_equal %w[g then i], hidden
    assert_equal "g then i", flat_hidden_text("keybinding-hint")
  end

  def test_sequence_shows_one_visible_space_between_chords
    visit_preview(:sequence)

    gap, space = page.evaluate_script(<<~JS)
      (() => {
        const kbd = document.querySelector('keybinding-hint kbd')
        const [first, second] = kbd.querySelectorAll('[data-kbd-chord]')
        const context = document.createElement('canvas').getContext('2d')
        context.font = getComputedStyle(kbd).font
        return [second.getBoundingClientRect().left - first.getBoundingClientRect().right, context.measureText(' ').width]
      })()
    JS
    assert_operator space, :>, 0
    assert_in_delta space, gap, 1, "chords must be separated by exactly one visible space"
  end

  def test_literal_plus_and_space_keys
    visit_preview(:playground, keys: "Mod+Plus a Space b", platform: "other")

    assert_selector(VISIBLE, text: "+")
    assert_selector(VISIBLE, text: "␣")
    assert_selector(HIDDEN, text: "plus", visible: :all)
    assert_selector(HIDDEN, text: "space", visible: :all)
  end

  def test_drops_empty_tokens
    visit_preview(:playground, keys: "Mod++p  g", platform: "apple")

    assert_selector("keybinding-hint .KeybindingHint-chord", count: 2)
    assert_equal ["⌘", "P", "G"], all(VISIBLE).map(&:text)
  end

  def test_named_keys_use_condensed_glyphs
    visit_preview(:platforms)

    within(all("keybinding-hint")[0]) { assert_selector("[aria-hidden='true']", text: "⌥") } # apple alt
    within(all("keybinding-hint")[1]) { assert_selector("[aria-hidden='true']", text: "Alt") } # windows alt
    assert_selector(VISIBLE, text: "↑", count: 3)
    assert_selector(HIDDEN, text: "up arrow", visible: :all, count: 3)
  end

  def test_scheme_and_size_modifiers_survive_upgrade
    visit_preview(:playground, keys: "Mod+s", scheme: "emphasis", size: "small", platform: "other")

    assert_selector("keybinding-hint .KeybindingHint-chord.KeybindingHint-chord--emphasis.KeybindingHint-chord--small")
  end

  def test_attribute_change_rerenders
    visit_preview(:playground, keys: "Mod+s", platform: "apple")
    assert_selector(VISIBLE, text: "S")

    page.execute_script("document.querySelector('keybinding-hint').setAttribute('data-keys', 'Mod+k')")
    assert_selector(VISIBLE, text: "K")
    refute_selector(VISIBLE, text: "S")

    page.execute_script("document.querySelector('keybinding-hint').setAttribute('data-platform', 'other')")
    assert_selector(VISIBLE, text: "⌃")
    refute_selector(VISIBLE, text: "⌘")
  end

  def test_blank_keys_renders_nothing
    visit_preview(:playground, keys: "Mod+s", platform: "apple")
    page.execute_script("document.querySelector('keybinding-hint').setAttribute('data-keys', '  ')")

    refute_selector("keybinding-hint .KeybindingHint-chord")
    refute_selector("keybinding-hint kbd")
  end

  def test_invalid_runtime_attributes_fall_back
    visit_preview(:playground, keys: "Mod+s", platform: "apple")
    page.execute_script(<<~JS)
      const el = document.querySelector('keybinding-hint')
      el.setAttribute('data-scheme', 'bogus')
      el.setAttribute('data-size', 'bogus')
      el.setAttribute('data-format', 'bogus')
      el.setAttribute('data-platform', 'bogus')
    JS

    assert_selector("keybinding-hint .KeybindingHint-chord:not(.KeybindingHint-chord--emphasis):not(.KeybindingHint-chord--small)")
    # data-platform="bogus" means "detect": ⌘ on a macOS dev machine, ⌃ on Linux CI.
    assert(all(VISIBLE).map(&:text).intersect?(["⌘", "⌃"]), "mod resolved for the detected platform")
    assert_equal "bogus", find("keybinding-hint")["data-scheme"], "element must not write normalized values back"
  end

  def test_rerenders_after_subtree_replacement
    visit_preview(:playground, keys: "Mod+s", platform: "apple")
    page.execute_script(<<~JS)
      const el = document.querySelector('keybinding-hint')
      el.innerHTML = '<kbd class="KeybindingHint-kbd"><span class="KeybindingHint-chord" data-kbd-chord>Ctrl+S</span></kbd>'
      el.setAttribute('data-keys', 'Mod+k')
    JS

    assert_selector("keybinding-hint kbd", count: 1)
    assert_selector(VISIBLE, text: "K")
    assert_no_text("Ctrl+S")
  end

  def test_rerenders_when_children_are_morphed_without_attribute_change
    visit_preview(:playground, keys: "Mod+s", platform: "apple")
    assert_selector(VISIBLE, text: "⌘")

    page.execute_script(<<~JS)
      const el = document.querySelector('keybinding-hint')
      el.replaceChildren()
      const kbd = document.createElement('kbd')
      kbd.className = 'KeybindingHint-kbd'
      kbd.innerHTML = '<span class="KeybindingHint-chord" data-kbd-chord>Ctrl+S</span>'
      el.appendChild(kbd)
    JS

    assert_selector(VISIBLE, text: "⌘")
    assert_no_text("Ctrl+S")
    assert_selector("keybinding-hint kbd", count: 1)
  end

  def test_rerenders_after_in_place_kbd_morph_and_attribute_change
    visit_preview(:playground, keys: "Mod+s", platform: "apple")
    assert_selector(VISIBLE, text: "S")

    page.execute_script(<<~JS)
      const kbd = document.querySelector('keybinding-hint kbd')
      kbd.innerHTML = '<span class="KeybindingHint-chord" data-kbd-chord>Ctrl+S</span>'
      document.querySelector('keybinding-hint').setAttribute('data-keys', 'Mod+k')
    JS

    assert_selector("keybinding-hint kbd", count: 1)
    assert_selector(VISIBLE, text: "K")
    assert_no_text("Ctrl+S")
  end

  def test_rerenders_after_partial_chord_rewrite
    visit_preview(:playground, keys: "Mod+s", platform: "apple")
    assert_selector(VISIBLE, text: "S")

    page.execute_script(<<~JS)
      const chord = document.querySelector('keybinding-hint [data-kbd-chord]')
      chord.innerHTML = 'Ctrl+K'
    JS
    # external mutation alone must already trigger recovery
    assert_selector(VISIBLE, text: "S")
    assert_no_text("Ctrl+K")

    page.execute_script("document.querySelector('keybinding-hint').setAttribute('data-keys', 'Mod+x')")
    assert_selector(VISIBLE, text: "X")
    refute_selector(VISIBLE, text: "S")
    assert_no_text("Ctrl+K")
    assert_selector("keybinding-hint kbd", count: 1)
  end

  def test_dynamically_inserted_element_renders
    visit_preview(:default)
    page.execute_script(<<~JS)
      const el = document.createElement('keybinding-hint')
      el.setAttribute('data-keys', 'Mod+b')
      el.setAttribute('data-platform', 'apple')
      el.id = 'dynamic'
      document.body.appendChild(el)
    JS

    within("#dynamic") { assert_selector("[aria-hidden='true']", text: "⌘") }
  end

  def test_renders_hostile_keys_without_separators_as_text
    # No spaces or "+", so the whole payload reaches the renderer as one key.
    visit_preview(:playground, keys: "<img/src=x/onerror=window.__pwned2=1>", platform: "other")

    refute_selector("keybinding-hint img")
    assert_nil page.evaluate_script("window.__pwned2")
  end

  def test_renders_hostile_keys_as_text
    visit_preview(:playground, keys: "<img src=x onerror=window.__pwned=1>", platform: "other")

    refute_selector("keybinding-hint img")
    assert_nil page.evaluate_script("window.__pwned")
  end

  private

  # Accessible text of the hint as a screen reader would concatenate it:
  # textContent with the aria-hidden glyphs removed and whitespace collapsed.
  def flat_hidden_text(selector)
    page.evaluate_script(<<~JS)
      (() => {
        const clone = document.querySelector(#{selector.to_json}).cloneNode(true)
        clone.querySelectorAll('[aria-hidden="true"]').forEach((node) => node.remove())
        return clone.textContent.replace(/\\s+/g, ' ').trim()
      })()
    JS
  end
end
