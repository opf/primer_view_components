# frozen_string_literal: true

require "system/test_case"

module Beta
  class IntegrationBorderBoxTest < System::TestCase
    def test_rows_only_round_the_outer_corners
      visit_roundedness_playground(header: false, rows: true)

      assert_rounded_top ".Box-row:nth-of-type(1)"
      assert_square_top ".Box-row:nth-of-type(2)"
      assert_rounded_bottom ".Box-row:nth-of-type(3)"
    end

    def test_header_owns_the_top_corners_instead_of_the_first_row
      visit_roundedness_playground(header: true, rows: true)

      assert_rounded_top ".Box-header"
      assert_square_top ".Box-row:nth-of-type(1)"
      assert_rounded_bottom ".Box-row:nth-of-type(3)"
    end

    def test_footer_owns_the_bottom_corners_instead_of_the_last_row
      visit_roundedness_playground(header: false, rows: true, footer: true)

      assert_rounded_top ".Box-row:nth-of-type(1)"
      assert_square_bottom ".Box-row:nth-of-type(3)"
      assert_rounded_bottom ".Box-footer"
    end

    def test_body_does_not_round_when_rows_follow_it
      visit_roundedness_playground(header: false, body: true, rows: true, footer: false)

      assert_square_bottom ".Box-body"
      assert_rounded_bottom ".Box-row:nth-of-type(3)"
    end

    def test_body_rounds_when_it_is_the_last_element
      visit_roundedness_playground(header: true, body: true, rows: false)

      assert_rounded_bottom ".Box-body"
    end

    def test_header_rounds_the_bottom_when_it_is_the_only_element
      visit_roundedness_playground(header: true, body: false, rows: false, footer: false)

      assert_rounded_bottom ".Box-header"
    end

    private

    def visit_roundedness_playground(**params)
      visit_preview(:roundedness_playground, **{ header: false, body: false, rows: false, footer: false }.merge(params))
    end

    def assert_rounded_top(selector)
      refute_equal "0px", radius(selector, "TopLeft"), "expected #{selector} to round the top of the box"
      refute_equal "0px", radius(selector, "TopRight"), "expected #{selector} to round the top of the box"
    end

    def assert_square_top(selector)
      assert_equal "0px", radius(selector, "TopLeft"), "expected #{selector} not to round the top of the box"
      assert_equal "0px", radius(selector, "TopRight"), "expected #{selector} not to round the top of the box"
    end

    def assert_rounded_bottom(selector)
      refute_equal "0px", radius(selector, "BottomLeft"), "expected #{selector} to round the bottom of the box"
      refute_equal "0px", radius(selector, "BottomRight"), "expected #{selector} to round the bottom of the box"
    end

    def assert_square_bottom(selector)
      assert_equal "0px", radius(selector, "BottomLeft"), "expected #{selector} not to round the bottom of the box"
      assert_equal "0px", radius(selector, "BottomRight"), "expected #{selector} not to round the bottom of the box"
    end

    def radius(selector, corner)
      value = page.evaluate_script(
        "(() => { const el = document.querySelector(#{selector.to_json}); " \
        "return el && getComputedStyle(el).border#{corner}Radius; })()"
      )
      refute_nil value, "expected to find #{selector}"
      value
    end
  end
end
