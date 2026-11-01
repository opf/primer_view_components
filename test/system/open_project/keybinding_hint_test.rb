# frozen_string_literal: true

require "system/test_case"

# Class name matters: System::TestCase derives the preview path
# primer/open_project/keybinding_hint/<scenario> from it.
class IntegrationOpenProjectKeybindingHintTest < System::TestCase
  VISIBLE = "keybinding-hint .KeybindingHint-chord [aria-hidden='true']"
  HIDDEN = "keybinding-hint .KeybindingHint-chord .sr-only"
  PRIMARY_MEDIUM_HINT = ".Button--primary.Button--medium:not(:disabled):not(.Button--inactive) keybinding-hint"

  def test_upgrades_fallback_into_per_key_spans
    visit_preview(:default)

    assert_selector("keybinding-hint kbd.KeybindingHint-kbd", count: 1)
    assert_selector(VISIBLE, text: "Ctrl")
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
    assert_selector(VISIBLE, text: "Ctrl")
    assert_selector(HIDDEN, text: "control", visible: :all)

    visit_preview(:playground, keys: "Mod+p", platform: "other")
    assert_selector(VISIBLE, text: "Ctrl")
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

    assert_equal ["Ctrl", "⇧", "P"], all(VISIBLE).map(&:text)
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
    assert_selector(VISIBLE, text: "Ctrl")
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
    # data-platform="bogus" means "detect": ⌘ on a macOS dev machine, Ctrl on Linux CI.
    assert(all(VISIBLE).map(&:text).intersect?(["⌘", "Ctrl"]), "mod resolved for the detected platform")
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

  def test_button_hint_takes_button_state_colours
    visit_preview(:in_button)

    rest = chord_background(".Button--primary:not(:disabled):not(.Button--inactive) [data-kbd-chord]")
    disabled = chord_background(".Button--primary:disabled [data-kbd-chord]")
    inactive = chord_background(".Button--primary.Button--inactive [data-kbd-chord]")

    refute_equal rest, disabled, "disabled primary chord should differ from rest"
    refute_equal rest, inactive, "inactive primary chord should differ from rest"
  end

  def test_button_with_hint_gets_extra_end_padding
    visit_preview(:in_button)

    with_hint = page.evaluate_script("getComputedStyle(document.querySelector('.Button--small:has([data-kbd-chord])')).paddingInlineEnd")
    assert_equal "6px", with_hint
    large = page.evaluate_script("getComputedStyle(document.querySelector('.Button--large:has([data-kbd-chord])')).paddingInlineEnd")
    assert_equal "8px", large
  end

  def test_button_accessible_name_includes_each_key_once
    visit_preview(:in_button)
    assert_selector(".Button--primary.Button--medium [aria-hidden='true']", text: "S")

    assert_includes accessible_names("button"), "primary medium control s"
    assert_equal "control s", flat_hidden_text(PRIMARY_MEDIUM_HINT)

    page.execute_script(<<~JS)
      const button = [...document.querySelectorAll('.Button--primary.Button--medium')]
        .find((node) => node.textContent.includes('primary medium'))
      button.querySelector('keybinding-hint').setAttribute('data-keys', 'Mod+k')
    JS
    assert_selector(".Button--primary.Button--medium [aria-hidden='true']", text: "K")

    names = accessible_names("button")
    assert_includes names, "primary medium control k"
    refute_includes names, "primary medium control s"
    assert_equal "control k", flat_hidden_text(PRIMARY_MEDIUM_HINT)
  end

  def test_labelled_button_keeps_its_accessible_name
    visit_preview(:in_button)
    assert_selector("[aria-label='Save document'] [aria-hidden='true']", text: "S")

    assert_includes accessible_names("button"), "Save document"
  end

  def test_action_list_item_accessible_name_includes_hint
    visit_preview(:in_action_list)
    assert_selector(".ActionListItem [aria-hidden='true']", text: "⏎")

    names = accessible_names("button")
    assert names.any?(/\ASave\s+control\s+enter\z/), "expected a Save item named with its hint, got #{names.inspect}"
    assert_equal "control enter", flat_hidden_text(".ActionListItem:nth-child(2) keybinding-hint")
  end

  def test_action_list_danger_hover_resets_chord_background
    visit_preview(:in_action_list)
    # The hover rule sits inside `@media (hover: hover)`, which headless Chrome
    # on CI's Linux runners does not match.
    skip "browser reports no hover-capable pointer" unless page.evaluate_script('matchMedia("(hover: hover)").matches')

    selector = ".ActionListItem--danger [data-kbd-chord]"
    before = chord_background(selector)
    assert_match(/, 0\)\z/, before, "sanity: chord is transparent before hover")

    find(".ActionListItem--danger").hover
    after = chord_background(selector)

    refute_equal before, after, "danger hover must change the chord background"
    refute_match(/, 0\)\z/, after, "hovered chord must be opaque (--bgColor-default)")
  end

  def test_action_list_danger_active_resets_chord_background
    visit_preview(:in_action_list)

    selector = ".ActionListItem--danger [data-kbd-chord]"
    before = chord_background(selector)
    x, y = find(".ActionListItem--danger .ActionListContent").native.node.find_position
    mouse = page.driver.browser.mouse
    mouse.move(x: x, y: y).down
    after = chord_background(selector)
    mouse.up

    refute_equal before, after, "pressing a danger item must change the chord background"
    refute_match(/, 0\)\z/, after, "pressed chord must be opaque (--bgColor-default)")
  end

  def test_german_condensed_off_apple
    visit_preview(:playground, keys: "Mod+s", platform: "other", locale: "de")

    assert_selector(VISIBLE, text: "Strg")
    assert_includes flat_hidden_text("keybinding-hint"), "Steuerung"
  end

  def test_german_full_and_spoken_on_apple
    visit_preview(:playground, keys: "Control+s", format: "full", platform: "apple", locale: "de")

    assert_selector(VISIBLE, text: "Steuerung")
    assert_includes flat_hidden_text("keybinding-hint"), "Steuerung"
  end

  def test_german_then_in_sequence
    visit_preview(:playground, keys: "g i", platform: "other", locale: "de")

    assert_includes flat_hidden_text("keybinding-hint"), "dann"
  end

  def test_german_punctuation_spoken
    visit_preview(:playground, keys: "Mod+.", platform: "other", locale: "de")

    assert_selector(VISIBLE, text: ".")
    assert_includes flat_hidden_text("keybinding-hint"), "Punkt"
  end

  def test_names_only_change_rerenders
    visit_preview(:playground, keys: "Control+s", platform: "other")
    assert_selector(VISIBLE, text: "Ctrl")

    set_names("then" => "dann", "keys" => { "control" => { "condensed" => { "other" => "Strg" }, "accessible" => { "other" => "Steuerung" } } })

    assert_selector(VISIBLE, text: "Strg")
    assert_includes flat_hidden_text("keybinding-hint"), "Steuerung"
  end

  def test_malformed_names_fall_back_to_english
    visit_preview(:playground, keys: "Control+s", platform: "other")

    page.execute_script(%(document.querySelector("keybinding-hint").setAttribute("data-names", "{not json")))

    assert_selector(VISIBLE, text: "⌃")
    assert_includes flat_hidden_text("keybinding-hint"), "control"
  end

  def test_blank_names_fall_back_to_english
    visit_preview(:playground, keys: "Control+s g", platform: "other")

    set_names("then" => "", "keys" => { "control" => { "condensed" => { "other" => "" }, "accessible" => { "other" => "" } } })

    assert_selector(VISIBLE, text: "⌃")
    assert_includes flat_hidden_text("keybinding-hint"), "control"
    assert_includes flat_hidden_text("keybinding-hint"), "then"
  end

  def test_unicode_whitespace_names_fall_back_to_english
    visit_preview(:playground, keys: "Control+s", platform: "other")

    set_names("keys" => { "control" => { "condensed" => { "other" => "\u0085" }, "accessible" => { "other" => "\u3000" } } })

    assert_selector(VISIBLE, text: "⌃")
    assert_includes flat_hidden_text("keybinding-hint"), "control"
  end

  def test_markup_in_names_renders_as_text
    visit_preview(:playground, keys: "Control+s", platform: "other")

    set_names("keys" => { "control" => { "condensed" => { "other" => "<b>x</b>" } } })

    assert_selector(VISIBLE, text: "<b>x</b>")
    refute_selector("keybinding-hint b")
  end

  def test_inherited_property_key
    visit_preview(:playground, keys: "constructor", platform: "other")

    assert_selector(VISIBLE, text: "Constructor")
    assert_equal "constructor", flat_hidden_text("keybinding-hint")
  end

  PARITY_KEYS = ["Mod+s", "Control+Shift+p", "SHIFT+DELETE", "Mod+.", "Mod+Plus Space", "g i", "Alt+Meta+Escape", "Mod++p  g", "PageUp+/", "__proto__+constructor"].freeze

  def test_js_names_builder_matches_ruby
    visit_preview(:default)
    I18n.backend.store_translations(
      :de,
      keybinding_hint: {
        keys: {
          alt: { condensed: { apple: "Wahl" } },
          escape: "Esc",
          delete: { key: "x", condensed: { other: "Entf" }, full: { other: "" } },
          pageup: { condensed: { other: "Bild↑", bogus: "x" } },
          control: { condensed: { other: "\u0085" } },
          shift: { full: { other: "\uFEFF" }, accessible: { other: "\u3000" } }
        },
        then: "\u0085"
      }
    )
    I18n.backend.store_translations(:en, keybinding_hint: { keys: { __proto__: { full: { other: "Proto" } } } })

    %i[en de].each do |locale|
      english = I18n.t(:keybinding_hint, locale: :en)
      scope = I18n.t(:keybinding_hint, locale: locale)
      PARITY_KEYS.each do |keys|
        ruby = I18n.with_locale(locale) { Primer::OpenProject::KeybindingHint::Names.for(keys) }
        js = page.evaluate_script(
          "JSON.parse(JSON.stringify(KeybindingHintElement.buildNames(#{keys.to_json}, JSON.parse(#{scope.to_json.to_json}), JSON.parse(#{english.to_json.to_json}))))"
        )

        assert_equal ruby, js, "#{locale}: #{keys}"
      end
    end
  ensure
    I18n.reload!
  end

  private

  def set_names(names)
    page.execute_script(%(document.querySelector("keybinding-hint").setAttribute("data-names", #{names.to_json.to_json})))
  end

  # Computed accessible names of all nodes with the given ARIA role, read
  # from Chrome's accessibility tree over CDP (Cuprite exposes Ferrum).
  def accessible_names(role)
    tree = page.driver.browser.page.command("Accessibility.getFullAXTree")
    tree["nodes"].select { |node| node.dig("role", "value") == role }.map { |node| node.dig("name", "value") }
  end

  # The hint's text with aria-hidden glyphs removed, flattened as inline
  # text. Chrome's accname pads the blockified sr-only spans with spaces
  # on its own, so accessible_names cannot tell whether the element emits
  # the whitespace text nodes that other ATs rely on; this can.
  def flat_hidden_text(selector)
    page.evaluate_script(<<~JS)
      (() => {
        const clone = document.querySelector(#{selector.to_json}).cloneNode(true)
        clone.querySelectorAll('[aria-hidden="true"]').forEach((node) => node.remove())
        return clone.textContent.replace(/\\s+/g, ' ').trim()
      })()
    JS
  end

  def chord_background(selector)
    page.evaluate_script("getComputedStyle(document.querySelector(#{selector.to_json})).backgroundColor")
  end
end
