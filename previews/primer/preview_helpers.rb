# frozen_string_literal: true

module Primer
  # :nodoc:
  module PreviewHelpers
    # Lookbook toggle params arrive as the strings "true"/"false" rather than actual booleans.
    def coerce_bool(value)
      case value
      when true, false then value
      when "true" then true
      when "false" then false
      else false
      end
    end
  end
end
