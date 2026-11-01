# frozen_string_literal: true

require "components/test_helper"

class PrimerOpenProjectKeybindingHintNamesTest < Minitest::Test
  Names = Primer::OpenProject::KeybindingHint::Names

  def setup
    @available_locales = I18n.available_locales
    I18n.available_locales = @available_locales | [:de]
    I18n.backend.store_translations(
      :de,
      keybinding_hint: {
        then: "dann",
        keys: {
          control: { condensed: { other: "Strg" }, full: { other: "Steuerung" }, accessible: { other: "Steuerung" } },
          period: { key: ".", accessible: { other: "Punkt" } }
        }
      }
    )
  end

  def teardown
    I18n.available_locales = @available_locales
    I18n.reload!
  end

  def test_english_control_uses_ctrl_off_apple
    names = Names.for("Control+s")

    assert_equal "Ctrl", names["keys"]["control"]["condensed"]["other"]
    refute names["keys"].key?("s")
  end

  def test_mod_contributes_control_and_meta
    assert_includes Names.for("Mod+s")["keys"].keys, "control"
    assert_includes Names.for("Mod+s")["keys"].keys, "meta"
  end

  def test_german_overrides_and_falls_back_to_english
    I18n.with_locale(:de) do
      names = Names.for("Control+Insert")

      assert_equal "Steuerung", names["keys"]["control"]["full"]["other"]
      assert_equal I18n.t("keybinding_hint.keys.insert", locale: :en).deep_stringify_keys, names["keys"]["insert"]
    end
  end

  def test_lowercases_tokens
    assert_equal %w[delete shift], Names.for("SHIFT+DELETE")["keys"].keys.sort
  end

  def test_punctuation_and_literal_keys_use_slug_entries
    I18n.with_locale(:de) do
      assert_equal "Punkt", Names.for("Mod+.")["keys"]["."]["accessible"]["other"]
      assert_equal %w[plus space], (Names.for("Mod+Plus Space")["keys"].keys & %w[plus space]).sort
    end
  end

  def test_then_is_translated
    I18n.with_locale(:de) do
      assert_equal "dann", Names.for("g i")["then"]
    end
  end

  KEY_NAMES_TS = File.expand_path("../../../../app/components/primer/open_project/keybinding_hint/key_names.ts", __dir__)

  # Glyphs, and tokens that never reach a lookup (`mod` is resolved to
  # control/meta first; `+` and ` ` are chord/sequence separators).
  UNTRANSLATED = {
    "condensed" => %w[shift arrowup arrowdown arrowleft arrowright plus backspace space tab enter mod],
    "full" => %w[mod +],
    "accessible" => ["mod", "+", " "]
  }.freeze

  def test_upstream_table_keys_are_translated_or_excepted
    tables = upstream_table_keys
    assert_operator tables["accessible"].size, :>, 40, "sanity: parsed the upstream accessible table"

    english = I18n.t(:keybinding_hint, locale: :en).deep_stringify_keys["keys"]
    covered = english.each_with_object(Hash.new { |h, k| h[k] = [] }) do |(name, entry), formats|
      %w[condensed full accessible].each { |format| formats[format] << entry.fetch("key", name) if entry.key?(format) }
    end

    missing = tables.flat_map do |format, keys|
      (keys - covered[format] - UNTRANSLATED[format]).map { |key| "#{format}: #{key.inspect}" }
    end

    assert_empty missing, "Upstream key names neither translated in config/locales/en.yml nor listed in UNTRANSLATED"
  end

  def test_malformed_locale_entries_are_ignored
    I18n.backend.store_translations(
      :de,
      keybinding_hint: {
        keys: {
          period: "Punkt",
          control: { condensed: "Strg" },
          delete: { key: "x", condensed: { other: "Entf" } }
        }
      }
    )

    I18n.with_locale(:de) do
      names = Names.for("Mod+. Delete")

      assert_equal "period", names["keys"]["."]["accessible"]["other"]
      assert_equal "Ctrl", names["keys"]["control"]["condensed"]["other"]
      assert_equal "Entf", names["keys"]["delete"]["condensed"]["other"]
    end
  end

  def test_blank_translations_fall_back_to_english
    I18n.backend.store_translations(:de, keybinding_hint: { then: "", keys: { control: { condensed: { other: "" } } } })

    I18n.with_locale(:de) do
      names = Names.for("Control+s g")

      assert_equal "Ctrl", names["keys"]["control"]["condensed"]["other"]
      assert_equal "then", names["then"]
    end
  end

  def test_symbol_values_cannot_be_translated
    I18n.backend.store_translations(
      :de,
      keybinding_hint: {
        keys: {
          alt: { condensed: { apple: "Wahl", other: "Alt" } },
          meta: { condensed: { apple: "Befehl" } },
          control: { condensed: { apple: "Strg", other: "Strg" } }
        }
      }
    )

    I18n.with_locale(:de) do
      keys = Names.for("Alt+Meta+Control")["keys"]

      assert_equal "⌥", keys["alt"]["condensed"]["apple"]
      assert_equal "⌘", keys["meta"]["condensed"]["apple"]
      assert_equal "⌃", keys["control"]["condensed"]["apple"]
      assert_equal "Strg", keys["control"]["condensed"]["other"]
    end
  end

  def test_then_defaults_to_english
    assert_equal "then", Names.for("g i")["then"]
  end

  private

  # Keys of the three tables in the verbatim primer-react mirror.
  def upstream_table_keys
    source = File.read(KEY_NAMES_TS)
    {
      "condensed" => "condensedKeyName",
      "full" => "fullKeyName",
      "accessible" => "accessibleKeyName"
    }.transform_values do |function|
      table = source[/export const #{function} =.*?\}\)\[key\]/m]
      table.scan(/^\s+('(?:\\.|[^'])*'|"[^"]*"|[\w$]+):/).flatten.map { |key| unquote(key) }
    end
  end

  def unquote(key)
    return key unless key.start_with?("'", '"')

    key[1..-2].gsub(/\\(.)/, '\\1')
  end
end
