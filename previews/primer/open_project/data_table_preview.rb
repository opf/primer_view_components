# frozen_string_literal: true

require "ostruct"

module Primer
  module OpenProject
    # @component Primer::OpenProject::DataTable
    class DataTablePreview < ViewComponent::Preview
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

      private

      def sample_rows
        now = Time.now

        10.times.map do |i|
          OpenStruct.new(
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
