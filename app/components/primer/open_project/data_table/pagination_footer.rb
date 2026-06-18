# frozen_string_literal: true

module Primer
  module OpenProject
    class DataTable
      # This component is part of `Primer::OpenProject::DataTable` and should
      # not be used as a standalone component.
      #
      # It renders the table's pagination footer: an optional "range" summary
      # (e.g. "1 ‒ 10 of 95") alongside the paginated navigation provided by
      # <%= link_to_component(Primer::OpenProject::Pagination) %>.
      class PaginationFooter < Primer::Component
        status :open_project

        # @param current_page [Integer]
        #   The page that is currently being viewed (1-based).
        # @param total_count [Integer, nil]
        #   The total number of items across all pages. Required (together with
        #   `page_size`) to render the range summary.
        # @param page_size [Integer, nil]
        #   The number of items rendered per page. Required (together with
        #   `total_count`) to render the range summary.
        # @param aria_label [String, nil]
        #   Accessible name for the pagination navigation landmark.
        # @param system_arguments [Hash]
        #   System arguments passed to the root element. All remaining arguments
        #   are forwarded to <%= link_to_component(Primer::OpenProject::Pagination) %>.
        def initialize(current_page:, total_count: nil, page_size: nil, aria_label: nil, **system_arguments)
          @current_page = current_page
          @total_count = total_count
          @page_size = page_size
          @aria_label = aria_label || I18n.t("pagination.label")
          @pagination_arguments = system_arguments.merge(current_page: current_page, tag: :div)
        end

        attr_reader :aria_label

        def render?
          @pagination_arguments.key?(:page_count)
        end

        def show_range?
          @total_count.present? && @page_size.present? && @current_page.present?
        end

        def range_start
          ((@current_page - 1) * @page_size) + 1
        end

        def range_end
          [@current_page * @page_size, @total_count].min
        end
      end
    end
  end
end
