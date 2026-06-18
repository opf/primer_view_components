# frozen_string_literal: true

module Primer
  module OpenProject
    # DataTable is a 2-dimensional data structure where each row is an item, and
    # each column is a data point about the item.
    class DataTable < Primer::Component
      status :open_project

      Header = Data.define(:id, :column, :sortable, :sort_direction, :sort_strategy) do
        alias :sortable? :sortable
      end

      Cell = Data.define(:column, :row_header, :sort_value, :sort_type, :sort_blank) do
        alias :row_header? :row_header

        def sortable?
          sort_type.present?
        end

        def sort_data
          return {} unless sortable?

          data = {
            sort_value: sort_value,
            sort_type: sort_type
          }
          data[:sort_blank] = true if sort_blank
          data
        end
      end

      CELL_PADDING_DEFAULT = :normal
      CELL_PADDING_OPTIONS = [:condensed, CELL_PADDING_DEFAULT, :spacious].freeze

      TITLE_TAG_DEFAULT = :h2

      SUBTITLE_TAG_DEFAULT = :div
      SUBTITLE_TAG_OPTIONS = %i[div p span].freeze

      attr_reader :headers, :rows

      renders_one :title, ->(tag: TITLE_TAG_DEFAULT, **system_arguments) {
        system_arguments[:id] = title_id
        system_arguments[:tag] = tag
        system_arguments[:classes] = class_names(
          system_arguments[:classes],
          "TableTitle"
        )

        # `Primer::Beta::Heading` validates the tag against its own h1–h6 options.
        Primer::Beta::Heading.new(**system_arguments)
      }

      renders_one :subtitle, ->(tag: SUBTITLE_TAG_DEFAULT, **system_arguments) {
        system_arguments[:id] = subtitle_id
        system_arguments[:tag] = fetch_or_fallback(SUBTITLE_TAG_OPTIONS, tag, SUBTITLE_TAG_DEFAULT)
        system_arguments[:classes] = class_names(
          system_arguments[:classes],
          "TableSubtitle"
        )

        Primer::BaseComponent.new(**system_arguments)
      }

      renders_many :columns, ->(**args, &block) {
        column = Column.new(**args)
        block&.call(column)
        column
      }

      renders_one :pagination, Primer::OpenProject::DataTable::PaginationFooter

      # @param data [Array, ActiveRecord::Relation]
      #   A collection of rows that will be rendered inside the table
      # @param cell_padding [Symbol]
      #   The amount of space around the contents of each cell.
      #   Options: :condensed, :normal, :spacious
      # @param initial_sort_column [String, Symbol, nil]
      #   ID or field of the column by which the table is initially sorted
      # @param initial_sort_direction [Symbol, nil]
      #   Sort direction for the initially sorted column.
      #   Options: :ASC, :DESC
      # @param html_data [Hash]
      #   HTML data attributes to be passed to the table
      # @param system_arguments [Hash]
      #   System arguments passed to the root table element
      def initialize(
        data,
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

        @container_arguments = {}
        @container_arguments[:classes] = "TableContainer"

        @system_arguments = system_arguments
        @system_arguments[:classes] = class_names(@system_arguments[:classes], "Table")
        @system_arguments[:data] = merge_data(
          @system_arguments,
          { data: html_data },
          { data: { cell_padding: @cell_padding } }
        )

        @wrapper_arguments = { tag: :"scrollable-region" }
        @wrapper_arguments[:classes] = "TableOverflowWrapper"
        @wrapper_arguments[:data] = {}
      end

      def render?
        columns.any?
      end

      def before_render
        return unless render?

        @initial_sort_state = build_initial_sort_state
        @headers = build_headers
        @rows = sorted_rows

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

      def build_initial_sort_state
        if @initial_sort_column
          column = columns.find { |column| column.id == @initial_sort_column || column.field == @initial_sort_column }
          raise ArgumentError, "Invalid sort column" unless column
          raise ArgumentError, "Invalid sort_by for initial sort column" unless column.sortable?

          return sort_state_for(column)
        end

        if @initial_sort_direction
          column = columns.find(&:sortable?)
          raise ArgumentError, "Invalid sort column" unless column

          return sort_state_for(column)
        end

        nil
      end

      def sort_state_for(column)
        id = column.identifier
        raise ArgumentError, "Invalid sort column" unless id

        { id: id, direction: Sorting.normalize_direction(@initial_sort_direction), column: column }
      end

      def build_headers
        columns.map do |column|
          id = column.identifier
          raise ArgumentError, "Expected either an 'id' or 'field' to be defined for a Column" if id.blank?

          sort_direction = @initial_sort_state&.fetch(:id) == id ? @initial_sort_state[:direction] : :NONE
          Header.new(
            id: id,
            column: column,
            sortable: column.sortable?,
            sort_direction: sort_direction,
            sort_strategy: column.sort_strategy
          )
        end
      end

      def sorted_rows
        return @rows unless @initial_sort_state

        Sorting.sort_rows(
          @rows,
          column: @initial_sort_state[:column],
          direction: @initial_sort_state[:direction]
        )
      end

      def grid_template_from_columns(columns)
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
          sort_metadata = header.sortable? ? header.column.sort_metadata(row) : {}

          Cell.new(
            column: header.column,
            row_header: header.column.row_header,
            sort_value: sort_metadata[:value],
            sort_type: sort_metadata[:type],
            sort_blank: sort_metadata[:blank]
          )
        end
      end
    end
  end
end
