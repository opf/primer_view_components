# frozen_string_literal: true

module Primer
  module OpenProject
    # @component Primer::OpenProject::Table
    class TablePreview < ViewComponent::Preview
      # @label Default
      # @snapshot
      def default
        render_with_template
      end

      # @label Playground
      # @param caption_text text
      # @param rows_count number
      # @param show_colgroup toggle
      # @param show_footer toggle
      # @param controller text
      def playground(
        caption_text: "Ice Cream Prices (Summer 2026)",
        rows_count: 4,
        show_colgroup: true,
        show_footer: true,
        controller: "table-highlighting"
      )
        rows_count = rows_count.to_i.clamp(1, 12)

        render_with_template(
          locals: {
            caption_text: caption_text,
            rows_count: rows_count,
            show_colgroup: show_colgroup,
            show_footer: show_footer,
            controller: controller
          }
        )
      end
    end
  end
end
