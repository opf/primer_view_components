# frozen_string_literal: true

module Primer
  module OpenProject
    class KeybindingHint < Primer::Component
      # Translated key names for the keys of one hint, in the shape
      # `<keybinding-hint>` reads from its `data-names` attribute:
      #
      #   { "then" => "dann", "keys" => { "control" => { "condensed" => { "other" => "Strg" } } } }
      #
      # Entries come from the `keybinding_hint` locale scope. Missing
      # translations fall back to the English defaults in PVC's `en.yml`.
      module Names
        module_function

        FORMATS = %w[condensed full accessible].freeze
        PLATFORMS = %w[apple windows other].freeze

        def for(keys)
          english = scope_for(:en)
          locale = I18n.locale == :en ? {} : scope_for(I18n.locale)
          index = token_index(english["keys"])

          {
            "then" => present(locale["then"]) || english["then"],
            "keys" => tokens(keys).each_with_object({}) do |token, names|
              entry = index[token]
              next unless entry

              names[token] = entry_names(english["keys"][entry], hash_at(locale, "keys", entry))
            end
          }
        end

        def tokens(keys)
          keys.to_s.split(/\s+/)
              .flat_map { |chord| chord.split("+") }
              .reject(&:empty?)
              .map(&:downcase)
              .flat_map { |token| token == "mod" ? %w[control meta] : [token] }
              .uniq
        end

        # I18n keys cannot contain `.`, so punctuation entries carry their
        # literal key in a `key` field. Built from English only: the field is
        # not translatable.
        def token_index(entries)
          entries.each_with_object({}) do |(name, entry), index|
            index[entry.fetch("key", name)] = name if entry.is_a?(Hash)
          end
        end

        # Locale data comes from translators; anything that is not a
        # non-blank string in the expected place is ignored, and symbols such
        # as ⌘ cannot be replaced.
        def entry_names(english_entry, locale_entry)
          FORMATS.each_with_object({}) do |format, names|
            english = platform_names(english_entry[format])
            translated = platform_names(hash_at(locale_entry, format)).reject { |platform, _| symbol?(english[platform]) }
            platforms = english.merge(translated)
            names[format] = platforms if platforms.any?
          end
        end

        def symbol?(name)
          name.present? && !name.match?(/\p{L}/)
        end

        def platform_names(value)
          return {} unless value.is_a?(Hash)

          value.each_with_object({}) do |(platform, name), names|
            names[platform] = name if PLATFORMS.include?(platform) && present(name)
          end
        end

        def hash_at(hash, *path)
          path.reduce(hash) { |node, key| node.is_a?(Hash) ? node[key] : nil }.then { |node| node.is_a?(Hash) ? node : {} }
        end

        def present(value)
          value if value.is_a?(String) && value.present?
        end

        def scope_for(locale)
          scope = I18n.t(:keybinding_hint, locale: locale, default: {})
          scope.is_a?(Hash) ? scope.deep_stringify_keys : {}
        end
      end
    end
  end
end
