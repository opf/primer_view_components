# frozen_string_literal: true

require "components/test_helper"

class PrimerOpenProjectAvatarWithFallbackTest < Minitest::Test
  include Primer::ComponentTestHelpers

  def setup
    # Disable URL validation by default in tests to avoid HTTP requests
    @original_validate_urls = Primer::OpenProject::AvatarWithFallback.validate_urls
    Primer::OpenProject::AvatarWithFallback.validate_urls = false
  end

  def teardown
    Primer::OpenProject::AvatarWithFallback.validate_urls = @original_validate_urls
  end

  def test_renders_image_avatar_with_src
    render_inline(Primer::OpenProject::AvatarWithFallback.new(src: "https://github.com/github.png", alt: "github"))

    # Always wrapped in avatar-fallback for 404 error handling
    assert_selector("avatar-fallback[data-fallback-src^='data:image/svg+xml;base64,']") do
      assert_selector("img.avatar[src='https://github.com/github.png']")
    end
  end

  def test_image_avatar_error_handling_setup
    render_inline(Primer::OpenProject::AvatarWithFallback.new(src: "https://example.com/avatar.png", alt: "Alice Johnson", unique_id: 123))

    # Original src is preserved (client-side JS handles error -> fallback swap)
    assert_selector("avatar-fallback[data-unique-id='123'][data-alt-text='Alice Johnson']") do
      assert_selector("img.avatar[src='https://example.com/avatar.png']")
    end

    # Verify fallback SVG is available and contains correct initials
    fallback_wrapper = page.find("avatar-fallback")
    fallback_src = fallback_wrapper["data-fallback-src"]

    assert fallback_src.start_with?("data:image/svg+xml;base64,")
    svg_content = Base64.decode64(fallback_src.sub("data:image/svg+xml;base64,", ""))
    assert_includes svg_content, ">AJ<", "Fallback SVG should contain initials 'AJ'"
  end

  def test_falls_back_when_absolute_url_is_inaccessible
    Primer::OpenProject::AvatarWithFallback.validate_urls = true
    Primer::OpenProject::AvatarWithFallback.any_instance.stubs(:url_accessible?).returns(false)

    render_inline(Primer::OpenProject::AvatarWithFallback.new(src: "https://broken.example.com/avatar.png", alt: "Test User", unique_id: 42))

    # Should render fallback SVG when URL is inaccessible
    assert_selector("avatar-fallback[data-unique-id='42']") do
      assert_selector("img.avatar[src^='data:image/svg+xml;base64,']")
    end
  end

  def test_renders_fallback_when_src_is_nil
    render_inline(Primer::OpenProject::AvatarWithFallback.new(src: nil, alt: "OpenProject Admin"))

    # Should render avatar-fallback element wrapping an img with base64 SVG data URI
    assert_selector("avatar-fallback[data-alt-text='OpenProject Admin']") do
      assert_selector("img.avatar[src^='data:image/svg+xml;base64,']")
    end
  end

  def test_renders_fallback_when_src_is_blank
    render_inline(Primer::OpenProject::AvatarWithFallback.new(src: "", alt: "OpenProject Admin"))

    assert_selector("avatar-fallback[data-alt-text='OpenProject Admin']") do
      assert_selector("img.avatar[src^='data:image/svg+xml;base64,']")
    end
  end

  def test_defaults_to_size_20
    render_inline(Primer::OpenProject::AvatarWithFallback.new(src: "https://github.com/github.png", alt: "github"))

    assert_selector("img.avatar[size=20][height=20][width=20]")
  end

  def test_fallback_defaults_to_size_20
    render_inline(Primer::OpenProject::AvatarWithFallback.new(src: nil, alt: "Test User"))

    assert_selector("img.avatar[src^='data:image/svg+xml;base64,']")
  end

  def test_falls_back_when_size_isn_t_valid
    without_fetch_or_fallback_raises do
      render_inline(Primer::OpenProject::AvatarWithFallback.new(src: "https://github.com/github.png", alt: "github", size: 1_000_000_000))

      assert_selector("img.avatar[size=20][height=20][width=20]")
    end
  end

  def test_defaults_to_circle_avatar
    render_inline(Primer::OpenProject::AvatarWithFallback.new(src: "https://github.com/github.png", alt: "github"))

    assert_selector("img.avatar.circle")
  end

  def test_fallback_defaults_to_circle_avatar
    render_inline(Primer::OpenProject::AvatarWithFallback.new(src: nil, alt: "Test User"))

    assert_selector("img.avatar.circle[src^='data:image/svg+xml;base64,']")
  end

  def test_adds_small_modifier_when_size_is_less_than_threshold
    render_inline(Primer::OpenProject::AvatarWithFallback.new(src: "https://github.com/github.png", alt: "github", size: Primer::OpenProject::AvatarWithFallback::SMALL_THRESHOLD - 4))

    assert_selector("img.avatar.avatar-small")
  end

  def test_fallback_adds_small_modifier_when_size_is_less_than_threshold
    render_inline(Primer::OpenProject::AvatarWithFallback.new(src: nil, alt: "Test User", size: Primer::OpenProject::AvatarWithFallback::SMALL_THRESHOLD - 4))

    assert_selector("img.avatar.avatar-small[src^='data:image/svg+xml;base64,']")
  end

  def test_sets_size_height_and_width
    render_inline(Primer::OpenProject::AvatarWithFallback.new(src: "https://github.com/github.png", alt: "github", size: 24))

    assert_selector("img.avatar[size=24][height=24][width=24]")
  end

  def test_fallback_sets_correct_size_class
    render_inline(Primer::OpenProject::AvatarWithFallback.new(src: nil, alt: "Test User", size: 40))

    # Size is set via attributes, not a dedicated class
    assert_selector("img.avatar[size='40'][height='40'][width='40'][src^='data:image/svg+xml;base64,']")
  end

  def test_squared_avatar
    render_inline(Primer::OpenProject::AvatarWithFallback.new(src: "https://github.com/github.png", alt: "github", shape: :square))

    assert_selector("img.avatar")
    refute_selector(".circle")
  end

  def test_fallback_squared_avatar
    render_inline(Primer::OpenProject::AvatarWithFallback.new(src: nil, alt: "Test User", shape: :square))

    assert_selector("img.avatar[src^='data:image/svg+xml;base64,']")
    refute_selector(".circle")
  end

  def test_renders_link_wrapper
    render_inline(Primer::OpenProject::AvatarWithFallback.new(src: "https://github.com/github.png", alt: "github", href: "#given-href"))

    assert_selector("a.avatar") do |(a)|
      assert_equal("#given-href", a["href"])
      assert_selector("img")
      refute_selector("img.avatar")
    end
  end

  def test_fallback_renders_link_wrapper
    render_inline(Primer::OpenProject::AvatarWithFallback.new(src: nil, alt: "Test User", href: "#test"))

    # When href is provided, the avatar class is on the <a> tag, not the <img>
    assert_selector("avatar-fallback") do
      assert_selector("a.avatar[href='#test']") do
        assert_selector("img[src^='data:image/svg+xml;base64,']")
      end
    end
  end

  def test_fallback_with_unique_id_in_data_attribute
    render_inline(Primer::OpenProject::AvatarWithFallback.new(src: nil, alt: "Test User", unique_id: 123))

    # Should have data attributes for client-side processing
    assert_selector("avatar-fallback[data-unique-id='123'][data-alt-text='Test User']") do
      assert_selector("img.avatar[src^='data:image/svg+xml;base64,']")
    end
  end

  def test_fallback_without_unique_id
    render_inline(Primer::OpenProject::AvatarWithFallback.new(src: nil, alt: "Test User"))

    # Should still render, just without unique_id data attribute
    assert_selector("avatar-fallback[data-alt-text='Test User']") do
      assert_selector("img.avatar[src^='data:image/svg+xml;base64,']")
    end
  end

  def test_adds_custom_classes
    render_inline(Primer::OpenProject::AvatarWithFallback.new(src: "https://github.com/github.png", alt: "github", classes: "custom-class"))

    assert_selector("img.avatar.custom-class")
  end

  def test_fallback_adds_custom_classes
    render_inline(Primer::OpenProject::AvatarWithFallback.new(src: nil, alt: "Test User", classes: "custom-class"))

    assert_selector("img.avatar.custom-class[src^='data:image/svg+xml;base64,']")
  end

  def test_raises_when_both_src_and_alt_are_missing
    error = assert_raises(ArgumentError) do
      render_inline(Primer::OpenProject::AvatarWithFallback.new(src: nil, alt: nil))
    end

    assert_includes(error.message, "`src` or `alt` is required")
  end

  def test_raises_when_both_src_and_alt_are_blank
    error = assert_raises(ArgumentError) do
      render_inline(Primer::OpenProject::AvatarWithFallback.new(src: "", alt: ""))
    end

    assert_includes(error.message, "`src` or `alt` is required")
  end

  def test_fallback_with_single_word_name
    render_inline(Primer::OpenProject::AvatarWithFallback.new(src: nil, alt: "Alice"))

    assert_selector("avatar-fallback") do
      assert_selector("img.avatar[src^='data:image/svg+xml;base64,']")
    end
  end

  def test_status
    assert_component_state(Primer::OpenProject::AvatarWithFallback, :open_project)
  end
end
