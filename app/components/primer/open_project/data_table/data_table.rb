# frozen_string_literal: true

module Primer
  module OpenProject
    module DataTable
      class DataTable < Primer::Component
        Header = Data.define(:id, :column, :sortable, :sort_direction) do
          alias :sortable? :sortable
        end

        Cell = Data.define(:id, :column, :row_header) do
          alias :row_header? :row_header
        end

        CELL_PADDING_DEFAULT = :normal
        CELL_PADDING_OPTIONS = [:condensed, CELL_PADDING_DEFAULT, :spacious].freeze

        attr_reader :headers, :rows

        renders_one :title, ->(**system_arguments) {
          system_arguments[:id] = title_id
          system_arguments[:tag] ||= :h2
          system_arguments[:classes] = class_names(
            system_arguments[:classes],
            "TableTitle"
          )

          Primer::Beta::Heading.new(**system_arguments)
        }

        renders_one :subtitle, ->(**system_arguments) {
          system_arguments[:id] = subtitle_id
          system_arguments[:tag] ||= :div
          system_arguments[:classes] = class_names(
            system_arguments[:classes],
            "TableSubtitle"
          )

          Primer::BaseComponent.new(**system_arguments)
        }

        renders_many :columns, Column

        # @param data [Array, ActiveRecord::Relation] a collection of the rows which
        #   will be rendered inside of the table
        # @param cell_padding [Symbol] the amount of space that should be available
        #   around the contents of a cell
        # @param initial_sort_column [Symbol, Number] (CELL_PADDING_DEFAULT) id or
        #   field of the column by which the table is sorted
        #   <%= one_of(CELL_PADDING_OPTIONS) %>
        # @param initial_sort_direction [Symbol] (:ASC or :NONE) the sort direction
        #   that the table should be sorted by on the currently sorted column
        #   %= one_of(DataTableComponent::SortHeaderComponent::DIRECTION_OPTIONS) %>
        # @param html_data [Hash] HTML data attributes to be passed in
        # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
        def initialize( # rubocop:disable Lint/MissingSuper
          data:,
          cell_padding: CELL_PADDING_DEFAULT,
          initial_sort_column: nil,
          initial_sort_direction: nil,
          html_data: {},
          **system_arguments
        )
          @rows = data
          @cell_padding = fetch_or_fallback(CELL_PADDING_OPTIONS, cell_padding, CELL_PADDING_DEFAULT)
          @initial_sort_column = initial_sort_column
          @initial_sort_direction = initial_sort_direction
          @id = system_arguments[:id] ||= self.class.generate_id(base_name: "data-table")

          @system_arguments = system_arguments
          @system_arguments[:classes] = "Table"
          @system_arguments[:data] = merge_data(
            html_data, { data: { cell_padding: } }
          )

          @wrapper_arguments = { tag: :"scrollable-region" }
          @wrapper_arguments[:classes] = "TableOverflowWrapper"
          @wrapper_arguments[:data] = {}
        end

        def render?
          columns.any?
        end

        def before_render # rubocop:disable Metrics/AbcSize
          @initial_sort_state = build_initial_sort_state
          @headers = build_headers

          @system_arguments[:style] = join_style_arguments(
            @system_arguments[:style],
            "--grid-template-columns: #{grid_template_from_columns(columns).join(' ')}"
          )

          if title?
            @system_arguments[:aria] = merge_aria(
              @system_arguments, { aria: { labelledby: title_id } }
            )
            @wrapper_arguments[:data] = merge_data(
              @wrapper_arguments, { data: { labelled_by: title_id } }
            )
          end

          if subtitle?
            @system_arguments[:aria] = merge_aria(
              @system_arguments, { aria: { describedby: subtitle_id } }
            )
          end
        end

        private

        def title_id
          "title-#{@id}"
        end

        def subtitle_id
          "subtitle-#{@id}"
        end

        def build_initial_sort_state # rubocop:disable Metrics/AbcSize,Metrics/PerceivedComplexity
          if @initial_sort_column
            column = columns.find { |column| column.id == @initial_sort_column || column.field == @initial_sort_column }
            raise ArgumentError, "Invalid Sort column" unless column
            raise ArgumentError, "Invallid Sortby" unless column.sort_by

            return { id: @initial_sort_column, direction: @initial_sort_direction || :ASC }
          end

          if @initial_sort_direction
            column = columns.find { |column| column.sort_by.present? }
            raise ArgumentError, "Invalid Sort column" unless column

            id = column.id.presence || column.field
            raise ArgumentError, "Invalid Sort column" unless id

            return { id:, direction: @initial_sort_direction }
          end

          {}
        end

        def build_headers
          columns.map do |column|
            id = column.id.presence || column.field
            raise ArgumentError, "Expected either an 'id' or 'field' to be defined for a Column" if id.blank?

            sort_direction = @initial_sort_state[:id] == id ? @initial_sort_state[:direction] : :NONE
            Header.new(
              id:,
              column:,
              sortable: column.sort_by,
              sort_direction:
            )
          end
        end

        def grid_template_from_columns(columns) # rubocop:disable Metrics/AbcSize,Metrics/PerceivedComplexity
          columns.map do |column|
            column_width = column.width || :grow
            min_width = :auto
            max_width = "1fr"

            if column_width == :auto
              max_width = :auto
            end

            # Setting a min-width of 'max-content' ensures that the column will grow to fit the widest cell's content.
            # However, If the column has a max width, we can't set the min width to `max-content` because
            # the widest cell's content might overflow the container.
            if column_width == :grow && column.max_width.blank?
              min_width = :"max-content"
            end

            # Column widths set to "growCollapse" don't need a min width unless one is explicitly provided.
            if column_width == :grow_collapse
              min_width = "0"
            end

            # If a consumer passes `min_width` or `max_width`, we need to override whatever we set above.
            if column.min_width
              min_width = column.min_width.is_a?(Numeric) ? "#{column.min_width}px" : column.min_width
            end

            if column.max_width
              max_width = column.max_width.is_a?(Numeric) ? "#{column.max_width}px" : column.max_width
            end

            # If a consumer is passing one of the shorthand widths or doesn't pass a width at all, we use the
            # min and max width calculated above to create a minmax() column template value.
            if !column_width.is_a?(Numeric) && column_width.in?(%i[grow grow_collapse auto])
              next min_width == max_width ? min_width : "minmax(#{min_width}, #{max_width})"
            end

            # If we reach this point, the consumer is passing an explicit width value.
            column_width.is_a?(Numeric) ? "#{column_width}px" : column_width
          end
        end

        def cells_for(row)
          headers.map do |header|
            Cell.new(
              id: "#{row.id}:#{header.id}",
              column: header.column,
              row_header: header.column.row_header
            )
          end
        end
      end
    end
  end
end
