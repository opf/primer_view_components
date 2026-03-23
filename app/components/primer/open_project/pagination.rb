# frozen_string_literal: true

module Primer
  module OpenProject
    class Pagination < Primer::Component
      status :open_project
      DEFAULT_MARGIN_PAGE_COUNT = 1
      DEFAULT_SURROUNDING_PAGE_COUNT = 2

      PageData = Struct.new(:key, :content, :props, keyword_init: true)

      attr_reader :page_count,
                  :current_page,
                  :href_builder,
                  :margin_page_count,
                  :show_pages,
                  :surrounding_page_count

      def initialize(
        page_count:,
        current_page:,
        href_builder: nil,
        margin_page_count: DEFAULT_MARGIN_PAGE_COUNT,
        show_pages: true,
        surrounding_page_count: DEFAULT_SURROUNDING_PAGE_COUNT,
        **system_arguments
      )
        raise ArgumentError, "page_count is required" if page_count.nil?
        raise ArgumentError, "current_page is required" if current_page.nil?

        @page_count = Integer(page_count)
        @current_page = Integer(current_page)

        @href_builder = href_builder || method(:default_href_builder)

        @margin_page_count =
          Integer(margin_page_count.nil? ? DEFAULT_MARGIN_PAGE_COUNT : margin_page_count)

        @show_pages = show_pages

        @surrounding_page_count =
          Integer(surrounding_page_count.nil? ? DEFAULT_SURROUNDING_PAGE_COUNT : surrounding_page_count)

        @system_arguments = system_arguments

        validate_arguments!
      end

      def render?
        true
      end

      def nav_arguments
        system_arguments = @system_arguments.dup
        system_arguments[:tag] = :nav
        system_arguments[:classes] = class_names(
          "PaginationContainer",
          system_arguments[:classes]
        )
        system_arguments["aria-label"] = I18n.t("pagination.label")

        system_arguments
      end

      def pages
        build_pagination_model.map do |page|
          build_component_data(page)
        end
      end

      private

      def validate_arguments!
        raise ArgumentError, "page_count must be >= 0" if page_count < 0
        raise ArgumentError, "current_page must be >= 1" if current_page < 1
        raise ArgumentError, "margin_page_count must be >= 0" if margin_page_count < 0
        raise ArgumentError, "surrounding_page_count must be >= 0" if surrounding_page_count < 0
        raise ArgumentError, "href_builder must respond to #call" unless href_builder.respond_to?(:call)
        raise ArgumentError, "show_pages must be a boolean" unless [true, false].include?(show_pages)
      end

      def default_href_builder(page_num)
        "##{page_num}"
      end

      def build_pagination_model
        prev = previous_page_item
        next_page = next_page_item

        return [prev, next_page] unless show_pages
        return pagination_without_pages(prev, next_page) if page_count <= 0
        return full_pagination_without_breaks(prev, next_page) if all_pages_fit?

        [prev, *paginated_number_items, next_page]
      end

      def previous_page_item
        {
          type: "PREV",
          num: current_page - 1,
          disabled: current_page == 1
        }
      end

      def next_page_item
        {
          type: "NEXT",
          num: current_page + 1,
          disabled: current_page == page_count
        }
      end

      def pagination_without_pages(prev, next_page)
        [prev, next_page.merge(disabled: true)]
      end

      def full_pagination_without_breaks(prev, next_page)
        pages = []
        add_pages(pages, 1, page_count)
        [prev, *pages, next_page]
      end

      def paginated_number_items
        pages = []

        add_start_pages_and_ellipsis(pages)
        add_middle_pages(pages)
        add_end_pages_and_ellipsis(pages)

        pages
      end

      def add_start_pages_and_ellipsis(pages)
        add_pages(pages, 1, margin_page_count, has_start_ellipsis?)
        add_ellipsis(pages, margin_page_count) if has_start_ellipsis?
      end

      def add_middle_pages(pages)
        add_pages(
          pages,
          middle_start_page,
          middle_end_page,
          has_end_ellipsis?
        )
      end

      def add_end_pages_and_ellipsis(pages)
        add_ellipsis(pages, middle_end_page) if has_end_ellipsis?
        add_pages(pages, ending_start_page, page_count)
      end

      def all_pages_fit?
        page_count <= max_visible_pages
      end

      def max_visible_pages
        (standard_gap * 2) + 3
      end

      def standard_gap
        surrounding_page_count + margin_page_count
      end

      def has_start_ellipsis?
        start_gap.positive?
      end

      def has_end_ellipsis?
        end_gap.positive?
      end

      def start_gap
        @start_gap ||= near_start? ? 0 : current_page - standard_gap - 1
      end

      def start_offset
        @start_offset ||= near_start? ? current_page - standard_gap - 2 : 0
      end

      def end_gap
        @end_gap ||= near_end? ? 0 : page_count - current_page - standard_gap
      end

      def end_offset
        @end_offset ||= near_end? ? page_count - current_page - standard_gap - 1 : 0
      end

      def near_start?
        current_page - standard_gap - 1 <= 1
      end

      def near_end?
        page_count - current_page - standard_gap <= 1
      end

      def middle_start_page
        margin_page_count + start_gap + end_offset + 1
      end

      def middle_end_page
        page_count - start_offset - end_gap - margin_page_count
      end

      def ending_start_page
        page_count - margin_page_count + 1
      end

      def add_ellipsis(pages, previous_page)
        pages << {
          type: "BREAK",
          num: previous_page + 1
        }
      end

      def add_pages(pages, start_page, end_page, precedes_break = false)
        (start_page..end_page).each do |i|
          pages << {
            type: "NUM",
            num: i,
            selected: i == current_page,
            precedes_break: i == end_page && precedes_break
          }
        end
      end

      def build_component_data(page)
        props = {}
        content = ""
        key = ""

        case page[:type]
        when "PREV"
          key = "page-prev"
          content = I18n.t("pagination.previous")

          if page[:disabled]
            props.merge!(
              rel: "prev",
              "aria-hidden": "true",
              "aria-disabled": "true"
            )
          else
            props.merge!(
              rel: "prev",
              href: href_builder.call(page[:num]),
              "aria-label": I18n.t("pagination.previous_page")
            )
          end

        when "NEXT"
          key = "page-next"
          content = I18n.t("pagination.next")

          if page[:disabled]
            props.merge!(
              rel: "next",
              "aria-hidden": "true",
              "aria-disabled": "true"
            )
          else
            props.merge!(
              rel: "next",
              href: href_builder.call(page[:num]),
              "aria-label": I18n.t("pagination.next_page")
            )
          end

        when "NUM"
          key = "page-#{page[:num]}"
          content = page[:num].to_s

          props.merge!(
            href: href_builder.call(page[:num]),
            "aria-label": page[:precedes_break] ? I18n.t("pagination.page_with_more", number: page[:num]) : I18n.t("pagination.page", number: page[:num])
          )

          props[:"aria-current"] = "page" if page[:selected]

        when "BREAK"
          key = "page-#{page[:num]}-break"
          content = "…"

          props.merge!(
            role: "presentation",
            as: "span"
          )
        end

        PageData.new(
          key: key,
          content: content,
          props: props
        )
      end
    end
  end
end
