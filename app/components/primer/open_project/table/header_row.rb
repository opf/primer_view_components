# frozen_string_literal: true

module Primer
  module OpenProject
    class Table
      # The `Table`'s header row.
      #
      # This component is should not be used directly, except for advanced user
      # cases.
      class HeaderRow < Row
        status :open_project

        alias :with_header :with_column_header
      end
    end
  end
end
