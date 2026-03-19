# frozen_string_literal: true

module Primer
  module OpenProject
    class Pagination < Primer::Component
      status :open_project
      DEFAULT_MARGIN_PAGE_COUNT = 1
      DEFAULT_SURROUNDING_PAGE_COUNT = 2

      PageData = Struct.new(:key, :content, :props, keyword_init: true)

      attr_reader :class_name,
                  :page_count,
                  :current_page,
                  :href_builder,
                  :margin_page_count,
                  :show_pages,
                  :surrounding_page_count

      def initialize(
        page_count:,
        current_page:,
        class_name: nil,
        href_builder: nil,
        margin_page_count: DEFAULT_MARGIN_PAGE_COUNT,
        show_pages: true,
        surrounding_page_count: DEFAULT_SURROUNDING_PAGE_COUNT,
        **system_arguments
      )
        raise ArgumentError, "page_count is required" if page_count.nil?
        raise ArgumentError, "current_page is required" if current_page.nil?

        @class_name = class_name
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
        {
          tag: :nav,
          classes: class_names("PaginationContainer", class_name, @system_arguments[:classes]),
          "aria-label": I18n.t("pagination.label")
        }.merge(@system_arguments.except(:classes))
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

        unless show_pages.is_a?(TrueClass) || show_pages.is_a?(FalseClass) || show_pages.is_a?(Hash)
          raise ArgumentError, "show_pages must be a boolean or a hash of viewport ranges"
        end
      end

      def default_href_builder(page_num)
        "##{page_num}"
      end

      def show_pages_boolean
        !!show_pages
      end

      def build_pagination_model
        prev = {
          type: "PREV",
          num: current_page - 1,
          disabled: current_page == 1
        }

        next_page = {
          type: "NEXT",
          num: current_page + 1,
          disabled: current_page == page_count
        }

        return [prev, next_page] unless show_pages_boolean

        if page_count <= 0
          return [prev, next_page.merge(disabled: true)]
        end

        pages = []

        standard_gap = surrounding_page_count + margin_page_count
        max_visible_pages = standard_gap + standard_gap + 3

        if page_count <= max_visible_pages
          add_pages(pages, 1, page_count, false)
          return [prev, *pages, next_page]
        end

        start_gap = 0
        start_offset = 0

        if current_page - standard_gap - 1 <= 1
          start_offset = current_page - standard_gap - 2
        else
          start_gap = current_page - standard_gap - 1
        end

        end_gap = 0
        end_offset = 0

        if page_count - current_page - standard_gap <= 1
          end_offset = page_count - current_page - standard_gap - 1
        else
          end_gap = page_count - current_page - standard_gap
        end

        has_start_ellipsis = start_gap > 0
        has_end_ellipsis = end_gap > 0

        add_pages(pages, 1, margin_page_count, has_start_ellipsis)

        add_ellipsis(pages, margin_page_count) if has_start_ellipsis

        add_pages(
          pages,
          margin_page_count + start_gap + end_offset + 1,
          page_count - start_offset - end_gap - margin_page_count,
          has_end_ellipsis
        )

        add_ellipsis(pages, page_count - start_offset - end_gap - margin_page_count) if has_end_ellipsis

        add_pages(pages, page_count - margin_page_count + 1, page_count)

        [prev, *pages, next_page]
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
