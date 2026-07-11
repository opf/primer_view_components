# frozen_string_literal: true

module Primer
  module OpenProject
    # @component Primer::OpenProject::DataTable
    class DataTablePreview < ViewComponent::Preview
      DemoProject = Data.define(:id, :name, :status_code, :created_at)
      DemoAssignment = Data.define(:id, :name, :assignee)

      # @label Default
      # @snapshot
      def default
        render_with_template(locals: { projects: sample_rows })
      end

      # @label With Row Actions
      # @snapshot
      def with_row_actions
        render_with_template(locals: { projects: sample_rows })
      end

      # @label Playground
      # @param cell_padding [Symbol] select [condensed, normal, spacious]
      # @param initial_sort_column [Symbol] select [none, name, status_code, created_at]
      # @param initial_sort_direction [Symbol] select [none, ASC, DESC]
      # @param rows_count [Integer] number
      # @param show_subtitle toggle
      def playground(
        cell_padding: :normal,
        initial_sort_column: :name,
        initial_sort_direction: :ASC,
        rows_count: 10,
        show_subtitle: true
      )
        rows_count = rows_count.to_i.clamp(1, 50)

        resolved_sort_column =
          initial_sort_column.to_s == "none" ? nil : initial_sort_column.to_sym

        resolved_sort_direction =
          initial_sort_direction.to_s == "none" ? nil : initial_sort_direction.to_sym

        render_with_template(
          locals: {
            rows: sample_rows.first(rows_count),
            cell_padding: cell_padding.to_sym,
            initial_sort_column: resolved_sort_column,
            initial_sort_direction: resolved_sort_direction,
            show_subtitle: show_subtitle
          }
        )
      end

      # @label With Actions
      # @snapshot
      def with_actions
        render_with_template(locals: { projects: sample_rows.first(3) })
      end

      # @label Empty State
      # @snapshot
      # @param custom toggle
      def empty_state(custom: false)
        render_with_template(locals: { custom: custom })
      end

      # @label With Cell Placeholder
      # @snapshot
      def with_cell_placeholder
        rows = [
          DemoAssignment.new(id: 1, name: "Project 1", assignee: "Ada Lovelace"),
          DemoAssignment.new(id: 2, name: "Project 2", assignee: nil),
          DemoAssignment.new(id: 3, name: "Project 3", assignee: "Grace Hopper")
        ]

        render_with_template(locals: { rows: rows })
      end

      # @label With External Sorting
      # @snapshot
      # @param sort_column [Symbol] select [name, status_code, created_at]
      # @param sort_direction [Symbol] select [ASC, DESC]
      def with_external_sorting(sort_column: :name, sort_direction: :ASC)
        column = sort_column.to_sym
        direction = sort_direction.to_s.upcase == "DESC" ? :DESC : :ASC

        rows = sample_rows.sort_by { |row| row.public_send(column).to_s } # rubocop:disable GitHub/AvoidObjectSendWithDynamicMethod
        rows.reverse! if direction == :DESC

        render_with_template(
          locals: { rows: rows, sort_column: column, sort_direction: direction }
        )
      end

      # @label With Pagination
      # @snapshot
      # @param page [Integer] number
      def with_pagination(page: 1)
        render_pagination_example(page: page, total_count: 95, page_size: 10, default_page: 1)
      end

      # @label With Pagination Using Default Page Index
      # @snapshot
      # @param page [Integer] number
      def with_pagination_using_default_page_index(page: nil)
        render_pagination_example(page: page, total_count: 1000, page_size: 10, default_page: 50)
      end

      private

      def render_pagination_example(page:, total_count:, page_size:, default_page:)
        page_count = (total_count.to_f / page_size).ceil
        current_page = (page.presence || default_page).to_i.clamp(1, page_count)
        offset = (current_page - 1) * page_size

        render_with_template(
          template: "primer/open_project/data_table_preview/pagination_example",
          locals: {
            rows: paginated_sample_rows(total_count)[offset, page_size],
            current_page: current_page,
            page_count: page_count,
            page_size: page_size,
            total_count: total_count
          }
        )
      end

      def paginated_sample_rows(count)
        now = Time.now

        count.times.map do |i|
          DemoProject.new(
            id: i + 1,
            name: "Project #{i + 1}",
            status_code: %w[active on_track at_risk off_track].fetch(i % 4),
            created_at: now - (i * 86_400) # i days ago
          )
        end
      end

      def sample_rows
        now = Time.now

        10.times.map do |i|
          DemoProject.new(
            id: i + 1,
            name: "Project #{i + 1}",
            status_code: %w[active on_track at_risk off_track].fetch(i % 4),
            created_at: now - (i * 86_400) # i days ago
          )
        end
      end
    end
  end
end
