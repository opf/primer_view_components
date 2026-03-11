# frozen_string_literal: true

module Primer
  module OpenProject
    class DataTable
      # This component is part of `Primer::OpenProject::DataTable` and should
      # not be used as a standalone component.
      class Column < Primer::Component
        status :open_project

        COLUMN_WIDTH_OPTIONS = %i[grow grow_collapse auto].freeze

        attr_reader :id, :align, :field, :max_width, :min_width, :row_header, :sort_by, :width, :cell_block

        renders_one :header, -> { Primer::Content.new }

        # Provide a custom cell renderer.
        #
        # @yieldparam row [Object] The row object for the current table row
        # @yieldreturn [Object] Renderable content for the cell
        def with_cell(&block)
          @cell_block = block
        end

        # @param id [String, Symbol, nil] Optional DOM id for the column
        # @param field [Symbol, nil] Attribute/method name called on each row to render a default cell value
        # @param align [Symbol] Horizontal alignment of the column content
        # @param header [String, nil] Column header text (rendered in the table header)
        # @param width [Numeric, String, Symbol, nil] Width value or one of COLUMN_WIDTH_OPTIONS
        # @param sort_by [String, Symbol, nil] Sort key used for sorting
        # @param row_header [Boolean] Whether this column is a row header (`<th scope="row">`)
        # @param min_width [Numeric, String, nil] Minimum width
        # @param max_width [Numeric, String, nil] Maximum width
        def initialize(
          id: nil,
          field: nil,
          align: Primer::OpenProject::Table::Cell::DEFAULT_ALIGNMENT,
          header: nil,
          width: nil,
          sort_by: nil,
          row_header: false,
          min_width: nil,
          max_width: nil
        )
          @id = id
          @field = field
          @align = align
          @header = header

          @width =
            if width.is_a?(Numeric) || width.is_a?(String)
              width
            elsif width.present?
              fetch_or_fallback(COLUMN_WIDTH_OPTIONS, width)
            end

          @sort_by = sort_by
          @row_header = row_header
          @max_width = max_width
          @min_width = min_width
        end

        def header
          @header || super
        end

        def header?
          @header.present? || super
        end

        def render_cell(row)
          return @cell_block.call(row) if @cell_block
          return unless field

          row.public_send(field) # rubocop:disable GitHub/AvoidObjectSendWithDynamicMethod
        end
      end
    end
  end
end
