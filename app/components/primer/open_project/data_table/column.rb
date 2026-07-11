# frozen_string_literal: true

module Primer
  module OpenProject
    class DataTable
      # This component is part of `Primer::OpenProject::DataTable` and should
      # not be used as a standalone component.
      class Column < Primer::Component
        status :open_project

        COLUMN_WIDTH_OPTIONS = %i[grow grow_collapse auto].freeze

        attr_reader :id, :align, :field, :max_width, :min_width, :placeholder, :row_header, :sort_by, :width, :cell_block

        # Provide a custom cell renderer.
        #
        # @yieldparam row [Object] The row object for the current table row
        # @yieldreturn [Object] Renderable content for the cell
        def with_cell(&block)
          @cell_block = block
        end

        # Provide a custom header renderer.
        #
        # @yieldreturn [Object] Renderable content for the column header
        def with_header(&block)
          @header_block = block
        end

        # @param id [String, Symbol, nil] Optional DOM id for the column
        # @param field [Symbol, nil] Attribute/method name called on each row to render a default cell value
        # @param align [Symbol] Horizontal alignment of the column content
        # @param header [String, nil] Column header text (rendered in the table header)
        # @param width [Numeric, String, Symbol, nil] Width value or one of COLUMN_WIDTH_OPTIONS
        # @param sort_by [Boolean, Symbol, nil] Whether this column is sortable, or the sort strategy to use
        # @param sort_value [Proc, nil] Optional `->(row)` returning the value used when sorting this column.
        #   Enables sorting of computed/fieldless columns. Falls back to `field` when omitted.
        # @param row_header [Boolean] Whether this column is a row header (`<th scope="row">`)
        # @param placeholder [String, nil] Placeholder text substituted for blank cell values,
        #   rendered as a muted <%= link_to_component(Primer::OpenProject::DataTable::CellPlaceholder) %>.
        #   Display-only: blank values still sort as blank.
        # @param min_width [Numeric, String, nil] Minimum width
        # @param max_width [Numeric, String, nil] Maximum width
        def initialize(
          id: nil,
          field: nil,
          align: Primer::OpenProject::Table::Cell::DEFAULT_ALIGNMENT,
          header: nil,
          width: nil,
          sort_by: nil,
          sort_value: nil,
          row_header: false,
          placeholder: nil,
          min_width: nil,
          max_width: nil
        )
          @id = id
          @field = field
          @sort_value_proc = sort_value
          @placeholder = placeholder
          @align = align
          @header = header

          @width =
            if width.is_a?(Numeric) || width.is_a?(String)
              width
            elsif width.present?
              fetch_or_fallback(COLUMN_WIDTH_OPTIONS, width)
            end

          @sort_by = Sorting.normalize_strategy(sort_by)
          @row_header = row_header
          @max_width = max_width
          @min_width = min_width
        end

        def header
          @header || @header_block&.call
        end

        def header?
          @header.present? || @header_block.present?
        end

        def identifier
          id.presence || field
        end

        def render_cell(row)
          return @cell_block.call(row) if @cell_block
          return unless field

          row.public_send(field) # rubocop:disable GitHub/AvoidObjectSendWithDynamicMethod
        end

        def sortable?
          sort_by.present?
        end

        def sort_strategy
          sort_by if sortable?
        end

        def sort_value(row)
          return @sort_value_proc.call(row) if @sort_value_proc
          return unless field

          row.public_send(field) # rubocop:disable GitHub/AvoidObjectSendWithDynamicMethod
        end

        def sort_metadata(row)
          Sorting.metadata_for(sort_value(row), sort_strategy)
        end
      end
    end
  end
end
