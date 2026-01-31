# frozen_string_literal: true

module Primer
  module OpenProject
    module Table
      class HeaderRow < Row
        status :open_project
        alias :with_header :with_column_header
      end
    end
  end
end
