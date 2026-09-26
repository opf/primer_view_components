# frozen_string_literal: true

module Primer
  module OpenProject
    # Displays a keyboard shortcut as a visible, screen-reader-friendly hint.
    # Port of Primer React's `KeybindingHint`.
    #
    # The server renders a plain-text fallback inside the styled chord box.
    # The `<keybinding-hint>` custom element replaces it with platform-specific
    # glyphs (for example ⌘ on Apple platforms, ⌃ elsewhere) and visually hidden
    # accessible key names ("command", "shift", …). Accessible names are English
    # only in this iteration.
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

      private

      # Readable degraded output for no-JS and the pre-upgrade frame. Not a
      # key table: only `Mod` is translated; other keys keep their spelling
      # with the first letter upcased, so `ArrowUp` stays `ArrowUp` and `p`
      # becomes `P`.
      def fallback_chords
        @keys.split(/\s+/).compact_blank.map do |chord|
          chord.split("+").compact_blank.map { |key| fallback_key_name(key) }.join("+")
        end
      end

      def fallback_key_name(key)
        key.casecmp?("mod") ? "Ctrl" : key.upcase_first
      end
    end
  end
end
