# frozen_string_literal: true

require "components/test_helper"

class PrimerBetaAvatarTest < Minitest::Test
  include Primer::ComponentTestHelpers

  def test_renders_an_avatar
    render_inline(Primer::Beta::Avatar.new(src: "https://github.com/github.png", alt: "github"))

    assert_selector("img.avatar")
  end

  def test_defaults_to_size_20
    render_inline(Primer::Beta::Avatar.new(src: "https://github.com/github.png", alt: "github"))

    assert_selector("img.avatar[size=20][height=20][width=20]")
  end

  def test_falls_back_when_size_isn_t_valid
    without_fetch_or_fallback_raises do
      render_inline(Primer::Beta::Avatar.new(src: "https://github.com/github.png", alt: "github", size: 1_000_000_000))

      assert_selector("img.avatar[size=20][height=20][width=20]")
    end
  end

  def test_defaults_to_circle_avatar
    render_inline(Primer::Beta::Avatar.new(src: "https://github.com/github.png", alt: "github"))

    assert_selector("img.avatar.circle")
  end

  def test_defaults_adds_small_modifier_when_size_is_less_than_threshold
    render_inline(Primer::Beta::Avatar.new(src: "https://github.com/github.png", alt: "github", size: Primer::Beta::Avatar::SMALL_THRESHOLD - 4))

    assert_selector("img.avatar.avatar-small")
  end

  def test_defaults_does_not_add_small_modifier_when_size_is_greater_than_threshold
    render_inline(Primer::Beta::Avatar.new(src: "https://github.com/github.png", alt: "github", size: Primer::Beta::Avatar::SMALL_THRESHOLD + 8))

    assert_selector("img.avatar")
    refute_selector(".avatar-small")
  end

  def test_adds_custom_classes
    render_inline(Primer::Beta::Avatar.new(src: "https://github.com/github.png", alt: "github", classes: "custom-class"))

    assert_selector("img.avatar.custom-class")
  end

  def test_sets_size_height_and_width
    render_inline(Primer::Beta::Avatar.new(src: "https://github.com/github.png", alt: "github", size: 24))

    assert_selector("img.avatar[size=24][height=24][width=24]")
  end

  def test_squared_avatar
    render_inline(Primer::Beta::Avatar.new(src: "https://github.com/github.png", alt: "github", shape: :square))

    assert_selector("img.avatar")
    refute_selector(".circle")
  end

  def test_renders_link_wrapper
    render_inline(Primer::Beta::Avatar.new(src: "https://github.com/github.png", alt: "github", href: "#given-href"))

    assert_selector("a.avatar") do |(a)|
      assert_equal("#given-href", a["href"])
      assert_selector("img")
      refute_selector("img.avatar")
    end
  end

  def test_defaults_circle_link_wrapper
    render_inline(Primer::Beta::Avatar.new(src: "https://github.com/github.png", alt: "github", href: "#"))

    assert_selector("a.avatar.circle") do
      assert_selector("img")
      refute_selector("img.circle")
    end
  end

  def test_squared_link_wrapper
    render_inline(Primer::Beta::Avatar.new(src: "https://github.com/github.png", alt: "github", href: "#", shape: :square))

    assert_selector("a.avatar") do
      assert_selector("img")
    end
    refute_selector(".circle")
  end

  def test_adds_small_modifier_to_link_wrapper_when_size_is_less_than_threshold
    render_inline(Primer::Beta::Avatar.new(src: "https://github.com/github.png", alt: "github", href: "#", size: Primer::Beta::Avatar::SMALL_THRESHOLD - 4))

    assert_selector("a.avatar.avatar-small") do
      assert_selector("img")
      refute_selector("img.avatar-small")
    end
  end

  def test_does_not_add_small_modifier_to_link_wrapper_when_size_is_greater_than_threshold
    render_inline(Primer::Beta::Avatar.new(src: "https://github.com/github.png", alt: "github", href: "#", size: Primer::Beta::Avatar::SMALL_THRESHOLD + 8))

    assert_selector("a.avatar") do
      assert_selector("img")
    end
    refute_selector(".avatar-small")
  end

  def test_adds_custom_classes_to_link_wrapper
    render_inline(Primer::Beta::Avatar.new(src: "https://github.com/github.png", alt: "github", href: "#", classes: "custom-class"))

    assert_selector("a.avatar.custom-class") do
      assert_selector("img")
      refute_selector("img.custom-class")
    end
  end

  def test_clears_link_wrapper_line_height
    render_inline(Primer::Beta::Avatar.new(src: "https://github.com/github.png", alt: "github", href: "#"))

    assert_selector("a.lh-0") do
      assert_selector("img")
      refute_selector("img.lh-0")
    end
  end

  def test_renders_svg_fallback_when_src_is_nil
    render_inline(Primer::Beta::Avatar.new(src: nil, alt: "OpenProject Admin"))

    assert_selector("img.avatar[src^='data:image/svg+xml;base64,']")
  end

  def test_renders_svg_fallback_when_src_is_blank
    render_inline(Primer::Beta::Avatar.new(src: "", alt: "OpenProject Admin"))

    assert_selector("img.avatar[src^='data:image/svg+xml;base64,']")
  end

  def test_fallback_generates_initials_from_full_name
    render_inline(Primer::Beta::Avatar.new(alt: "OpenProject Admin"))

    # Decode the base64 SVG and check it contains "OA"
    img = page.find("img.avatar")
    svg_data = img["src"].sub("data:image/svg+xml;base64,", "")
    svg_content = Base64.decode64(svg_data)

    assert_includes(svg_content, "OA")
  end

  def test_fallback_generates_single_initial_from_single_name
    render_inline(Primer::Beta::Avatar.new(alt: "John"))

    img = page.find("img.avatar")
    svg_data = img["src"].sub("data:image/svg+xml;base64,", "")
    svg_content = Base64.decode64(svg_data)

    # Check for "J" in the text element (accounting for whitespace)
    assert_match(/<text[^>]*>\s*J\s*<\/text>/, svg_content)
  end

  def test_fallback_generates_consistent_color_with_unique_id
    # Generate SVG twice with same parameters
    component1 = Primer::Beta::Avatar.new(alt: "Test User", unique_id: 123)
    component2 = Primer::Beta::Avatar.new(alt: "Test User", unique_id: 123)

    render_inline(component1)
    svg1 = page.find("img.avatar")["src"]

    # Re-render with new component
    render_inline(component2)
    svg2 = page.find("img.avatar")["src"]

    # SVG data should be identical
    assert_equal(svg1, svg2)
  end

  def test_fallback_generates_different_colors_for_different_unique_ids
    # Generate SVGs with different unique_ids
    component1 = Primer::Beta::Avatar.new(alt: "Test User", unique_id: 123)
    component2 = Primer::Beta::Avatar.new(alt: "Test User", unique_id: 456)

    render_inline(component1)
    svg1 = page.find("img.avatar")["src"]

    # Re-render with different unique_id
    render_inline(component2)
    svg2 = page.find("img.avatar")["src"]

    # SVG data should be different (different colors)
    refute_equal(svg1, svg2)
  end

  def test_fallback_respects_size_parameter
    render_inline(Primer::Beta::Avatar.new(alt: "Test User", size: 40))

    img = page.find("img.avatar")
    svg_data = img["src"].sub("data:image/svg+xml;base64,", "")
    svg_content = Base64.decode64(svg_data)

    # Check SVG has correct dimensions
    assert_includes(svg_content, 'width="40"')
    assert_includes(svg_content, 'height="40"')
  end

  def test_fallback_respects_circle_shape
    render_inline(Primer::Beta::Avatar.new(alt: "Test User", shape: :circle, size: 20))

    img = page.find("img.avatar")
    svg_data = img["src"].sub("data:image/svg+xml;base64,", "")
    svg_content = Base64.decode64(svg_data)

    # Circle should have rx="10" (50% of size)
    assert_includes(svg_content, 'rx="10')
  end

  def test_fallback_respects_square_shape
    render_inline(Primer::Beta::Avatar.new(alt: "Test User", shape: :square, size: 20))

    img = page.find("img.avatar")
    svg_data = img["src"].sub("data:image/svg+xml;base64,", "")
    svg_content = Base64.decode64(svg_data)

    # Square should have smaller border radius
    assert_includes(svg_content, 'rx="2.5"')
  end

  def test_fallback_with_href_wrapper
    render_inline(Primer::Beta::Avatar.new(alt: "Test User", href: "#test"))

    assert_selector("a.avatar[href='#test']") do
      assert_selector("img[src^='data:image/svg+xml;base64,']")
    end
  end

  def test_raises_when_both_src_and_alt_are_missing
    error = assert_raises(ArgumentError) do
      render_inline(Primer::Beta::Avatar.new(src: nil, alt: nil))
    end

    assert_includes(error.message, "`src` or `alt` is required")
  end

  def test_raises_when_both_src_and_alt_are_blank
    error = assert_raises(ArgumentError) do
      render_inline(Primer::Beta::Avatar.new(src: "", alt: ""))
    end

    assert_includes(error.message, "`src` or `alt` is required")
  end

  def test_fallback_wrapped_in_catalyst_controller
    render_inline(Primer::Beta::Avatar.new(src: nil, alt: "Test User", unique_id: 123))

    # Should be wrapped in avatar-fallback element with data attributes
    assert_selector("avatar-fallback[data-unique-id='123'][data-alt-text='Test User']") do
      assert_selector("img.avatar[src^='data:image/svg+xml']")
    end
  end

  def test_real_image_not_wrapped_in_catalyst_controller
    render_inline(Primer::Beta::Avatar.new(src: "https://example.com/avatar.png", alt: "Test"))

    # Real images should NOT be wrapped
    refute_selector("avatar-fallback")
    assert_selector("img.avatar[src='https://example.com/avatar.png']")
  end

  def test_status
    assert_component_state(Primer::Beta::Avatar, :beta)
  end
end
