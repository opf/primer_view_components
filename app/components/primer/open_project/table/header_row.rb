# frozen_string_literal: true

module Primer
  module OpenProject
    class Table
      # The `Table`'s header row.
      #
      # This component should not be used directly, except for advanced use
      # cases.
      class HeaderRow < Row
        status :open_project

        alias :with_header :with_column_header
      end
    end
  end
end
