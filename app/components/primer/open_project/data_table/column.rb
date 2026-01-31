# frozen_string_literal: true

module Primer
  module OpenProject
    module DataTable
      # A component to be used inside Primer::Beta::BorderBox.
      # It will toggle the visibility of the complete Box body
      class Column < Primer::Component
        status :open_project

        COLUMN_WIDTH_OPTIONS = %i[grow grow_collapse auto].freeze

        attr_reader :id, :align, :field, :max_width, :min_width, :row_header, :sort_by, :width, :cell_block

        renders_one :header, -> {
          Primer::Content.new
        }

        def with_cell(&block)
          @cell_block = block
        end

        # @param align The horizontal alignment of the column's content
        # @param header Provide the name of the column. This will be rendered as a table header within the table itself
        def initialize( # rubocop:disable Lint/MissingSuper
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
          @width = fetch_or_fallback(COLUMN_WIDTH_OPTIONS, width) if width.present?
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

        def call
          content
        end

        def render_cell(row)
          return @cell_block.call(row) if @cell_block
          return unless field

          row.public_send(field)
        end
      end
    end
  end
end
