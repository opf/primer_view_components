# frozen_string_literal: true

require "components/test_helper"

module Primer
  module Alpha
    class PaginationTest < Minitest::Test
      include Primer::ComponentTestHelpers

      def test_renders_navigation
        render_inline(Primer::Alpha::Pagination.new(page_count: 10, current_page: 2))

        assert_selector("nav[aria-label='Pagination']")
        assert_selector(".PaginationContainer")
        assert_selector(".TablePaginationSteps")
      end

      def test_renders_page_numbers
        render_inline(Primer::Alpha::Pagination.new(page_count: 5, current_page: 2))

        assert_selector("a", text: "1")
        assert_selector("a", text: "2")
        assert_selector("a", text: "3")
        assert_selector("a", text: "4")
        assert_selector("a", text: "5")
      end

      def test_marks_current_page
        render_inline(Primer::Alpha::Pagination.new(page_count: 5, current_page: 3))

        assert_selector("[aria-current='page']", text: "3")
      end

      def test_disables_previous_on_first_page
        render_inline(Primer::Alpha::Pagination.new(page_count: 5, current_page: 1))

        assert_selector("[rel='prev'][aria-disabled='true']")
      end

      def test_disables_next_on_last_page
        render_inline(Primer::Alpha::Pagination.new(page_count: 5, current_page: 5))

        assert_selector("[rel='next'][aria-disabled='true']")
      end

      def test_renders_ellipsis_for_many_pages
        render_inline(
          Primer::Alpha::Pagination.new(
            page_count: 30,
            current_page: 10
          )
        )

        assert_selector("[role='presentation']", text: "…")
      end

      def test_show_pages_false_renders_only_prev_next
        render_inline(
          Primer::Alpha::Pagination.new(
            page_count: 10,
            current_page: 5,
            show_pages: false
          )
        )

        assert_selector("[rel='prev']")
        assert_selector("[rel='next']")

        refute_selector("a", text: "1")
        refute_selector("a", text: "2")
        refute_selector("a", text: "3")
      end

      def test_custom_href_builder
        render_inline(
          Primer::Alpha::Pagination.new(
            page_count: 5,
            current_page: 2,
            href_builder: ->(page) { "/page/#{page}" }
          )
        )

        assert_selector("a[href='/page/1']")
        assert_selector("a[href='/page/2']")
        assert_selector("a[href='/page/3']")
      end
    end
  end
end