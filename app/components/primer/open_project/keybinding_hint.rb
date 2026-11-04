# frozen_string_literal: true

module Primer
  module OpenProject
    # Displays a keyboard shortcut as a visible, screen-reader-friendly hint.
    # Port of Primer React's `KeybindingHint`.
    #
    # The server renders a plain-text fallback inside the styled chord box.
    # The `<keybinding-hint>` custom element replaces it with platform-specific
    # names (for example ⌘ on Apple platforms, Ctrl elsewhere) and visually
    # hidden accessible key names ("command", "shift", …).
    #
    # ## Translation
    #
    # Key names follow the current locale: visible condensed and full names,
    # accessible names and the "then" spoken between chords of a sequence.
    # The component looks them up in the `keybinding_hint` locale scope
    # (English defaults in PVC's `config/locales/en.yml`) and passes the names
    # for its keys to the element as JSON in `data-names`. Each name is looked
    # up for the exact platform, then `other`, then Primer React's English
    # tables. Glyphs such as ↑, ⇧ and ⏎ are not translated.
    #
    # ## Key syntax
    #
    # Use the key names `KeyboardEvent.key` reports ("Control", "Shift",
    # "ArrowUp", "a", …), matching the github/hotkey format:
    #
    # - Join keys with `+` to form a chord pressed together: `"Mod+Shift+p"`.
    # - Join chords with a space to form a sequence pressed one after the
    #   other: `"g i"` (g, then i).
    # - Use `Plus` for the `+` key and `Space` for the space bar.
    # - `Mod` means Command on Apple platforms and Control everywhere else.
    #
    # Comma-separated alternatives (`"s,/"`) are not supported. The component only
    # displays hints; it does not register the shortcut.
    #
    # ## Terminology
    #
    # Primer React's `variant` is `scheme:` here (`normal` → `:default`,
    # `onEmphasis` → `:emphasis`) and its `size="normal"` is `size: :medium`.
    class KeybindingHint < Primer::Component
      status :open_project

      DEFAULT_FORMAT = :condensed
      FORMAT_OPTIONS = [DEFAULT_FORMAT, :full].freeze

      DEFAULT_SCHEME = :default
      SCHEME_MAPPINGS = {
        DEFAULT_SCHEME => "",
        :emphasis => "KeybindingHint-chord--emphasis"
      }.freeze
      SCHEME_OPTIONS = SCHEME_MAPPINGS.keys.freeze

      DEFAULT_SIZE = :medium
      SIZE_MAPPINGS = {
        DEFAULT_SIZE => "",
        :small => "KeybindingHint-chord--small"
      }.freeze
      SIZE_OPTIONS = SIZE_MAPPINGS.keys.freeze

      # @param keys [String] The keys of the shortcut, e.g. `"Mod+Shift+p"` or `"g i"`. See the class documentation for the syntax.
      # @param format [Symbol] <%= one_of(Primer::OpenProject::KeybindingHint::FORMAT_OPTIONS) %> `:condensed` shows symbols (⌘⇧P) and suits menus and buttons; `:full` spells keys out (Command + Shift + P) and suits prose.
      # @param scheme [Symbol] <%= one_of(Primer::OpenProject::KeybindingHint::SCHEME_OPTIONS) %> Use `:emphasis` on emphasis-coloured backgrounds.
      # @param size [Symbol] <%= one_of(Primer::OpenProject::KeybindingHint::SIZE_OPTIONS) %>
      # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
      def initialize(keys:, format: DEFAULT_FORMAT, scheme: DEFAULT_SCHEME, size: DEFAULT_SIZE, **system_arguments)
        @keys = keys.to_s.strip
        @format = fetch_or_fallback(FORMAT_OPTIONS, format, DEFAULT_FORMAT)
        @scheme = fetch_or_fallback(SCHEME_OPTIONS, scheme, DEFAULT_SCHEME)
        @size = fetch_or_fallback(SIZE_OPTIONS, size, DEFAULT_SIZE)

        @system_arguments = deny_tag_argument(**system_arguments)
        @system_arguments[:tag] = "keybinding-hint"
        @system_arguments[:classes] = class_names(@system_arguments[:classes], "KeybindingHint")
        @system_arguments[:data] = merge_data(
          @system_arguments,
          { data: { keys: @keys, format: @format, scheme: @scheme, size: @size } }
        )

        @chord_classes = class_names("KeybindingHint-chord", SCHEME_MAPPINGS[@scheme], SIZE_MAPPINGS[@size])
      end

      def render?
        @keys.present?
      end

      # Translations depend on the locale at render time, not at construction.
      def before_render
        @names = Names.for(@keys)
        @system_arguments[:data][:names] = @names.to_json
      end

      private

      # Readable degraded output for no-JS and the pre-upgrade frame. Uses the
      # translated condensed name for non-Apple platforms where one exists
      # (`Mod` as Control); other keys keep their spelling with the first
      # letter upcased, so `ArrowUp` stays `ArrowUp` and `p` becomes `P`.
      def fallback_chords
        @keys.split(/\s+/).compact_blank.map do |chord|
          chord.split("+").compact_blank.map { |key| fallback_key_name(key) }.join("+")
        end
      end

      def fallback_key_name(key)
        token = key.downcase
        token = "control" if token == "mod"
        @names.dig("keys", token, "condensed", "other") || key.upcase_first
      end
    end
  end
end
