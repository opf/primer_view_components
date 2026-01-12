# frozen_string_literal: true

require "components/test_helper"

class PrimerOpenProjectAvatarStackTest < Minitest::Test
  include Primer::ComponentTestHelpers

  def test_renders_with_image_avatars
    render_inline(Primer::OpenProject::AvatarStack.new) do |component|
      component.with_avatar_with_fallback(src: "https://github.com/github.png", alt: "@github")
    end

    assert_selector("div.AvatarStack") do
      assert_selector(".AvatarStack-body") do
        # Fallback-first pattern: img shows fallback SVG, real URL in data-avatar-src for JS
        assert_selector("avatar-fallback[data-avatar-src='https://github.com/github.png']") do
          assert_selector("img.avatar[src^='data:image/svg+xml;base64,']", count: 1)
        end
      end
    end
  end

  def test_renders_with_fallback_avatars
    render_inline(Primer::OpenProject::AvatarStack.new) do |component|
      component.with_avatar_with_fallback(src: nil, alt: "Alice Johnson", unique_id: 1)
      component.with_avatar_with_fallback(src: nil, alt: "Bob Smith", unique_id: 2)
    end

    assert_selector("div.AvatarStack") do
      assert_selector(".AvatarStack-body") do
        assert_selector("avatar-fallback", count: 2)
        assert_selector("img.avatar[src^='data:image/svg+xml;base64,']", count: 2)
      end
    end
  end

  def test_renders_mixed_avatars
    render_inline(Primer::OpenProject::AvatarStack.new) do |component|
      component.with_avatar_with_fallback(src: "https://github.com/github.png", alt: "@github")
      component.with_avatar_with_fallback(src: nil, alt: "Alice Johnson", unique_id: 10)
    end

    assert_selector("div.AvatarStack") do
      assert_selector(".AvatarStack-body") do
        # 2 img tags total, both with data URI fallback initially (fallback-first pattern)
        assert_selector("img.avatar", count: 2)
        # All avatars wrapped in avatar-fallback for 404 error handling
        assert_selector("avatar-fallback", count: 2)
        # Both start with fallback SVG; JS swaps to real URL on successful load
        assert_selector("img.avatar[src^='data:image/svg+xml;base64,']", count: 2)
        # One has a real URL for JS to test-load
        assert_selector("avatar-fallback[data-avatar-src='https://github.com/github.png']", count: 1)
      end
    end
  end

  def test_renders_three_plus_fallback_avatars
    render_inline(Primer::OpenProject::AvatarStack.new) do |component|
      component.with_avatar_with_fallback(src: nil, alt: "User 1", unique_id: 1)
      component.with_avatar_with_fallback(src: nil, alt: "User 2", unique_id: 2)
      component.with_avatar_with_fallback(src: nil, alt: "User 3", unique_id: 3)
    end

    assert_selector(".AvatarStack.AvatarStack--three-plus") do
      assert_selector(".AvatarStack-body") do
        assert_selector("avatar-fallback", count: 3)
        assert_selector("img.avatar[src^='data:image/svg+xml;base64,']", count: 3)
      end
    end
  end

  def test_status
    assert_component_state(Primer::OpenProject::AvatarStack, :open_project)
  end
end
