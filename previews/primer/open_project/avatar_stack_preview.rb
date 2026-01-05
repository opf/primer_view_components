# frozen_string_literal: true

module Primer
  module OpenProject
    # @label OpenProject AvatarStack
    class AvatarStackPreview < ViewComponent::Preview
      # @label Playground
      #
      # @param number_of_avatars [Integer] number
      # @param with_fallbacks toggle
      # @param align select [["Left", left], ["Right", right]]
      def playground(number_of_avatars: 3, with_fallbacks: true, align: :left)
        render(Primer::OpenProject::AvatarStack.new(align: align)) do |component|
          Array.new(number_of_avatars&.to_i || 1) do |i|
            if with_fallbacks
              component.with_avatar_with_fallback(src: nil, alt: "User #{i + 1}", unique_id: i + 1)
            else
              component.with_avatar_with_fallback(src: Primer::ExampleImage::BASE64_SRC, alt: "@kittenuser")
            end
          end
        end
      end

      # @label Default
      # @snapshot
      def default
        render(Primer::OpenProject::AvatarStack.new) do |component|
          component.with_avatar_with_fallback(src: Primer::ExampleImage::BASE64_SRC, alt: "@kittenuser")
        end
      end

      # @label With fallback avatars
      # @snapshot
      def with_fallback_avatars
        render(Primer::OpenProject::AvatarStack.new) do |component|
          component.with_avatar_with_fallback(src: nil, alt: "Alice Johnson", unique_id: 1)
          component.with_avatar_with_fallback(src: nil, alt: "Bob Smith", unique_id: 2)
          component.with_avatar_with_fallback(src: nil, alt: "Charlie Brown", unique_id: 3)
        end
      end

      # @label Mixed (image and fallback)
      def mixed_avatars
        render(Primer::OpenProject::AvatarStack.new) do |component|
          component.with_avatar_with_fallback(src: Primer::ExampleImage::BASE64_SRC, alt: "@kittenuser")
          component.with_avatar_with_fallback(src: nil, alt: "Alice Johnson", unique_id: 10)
          component.with_avatar_with_fallback(src: nil, alt: "Bob Smith", unique_id: 20)
        end
      end

      # @label Align right with fallbacks
      def align_right_with_fallbacks
        render(Primer::OpenProject::AvatarStack.new(align: :right)) do |component|
          component.with_avatar_with_fallback(src: nil, alt: "Alice Johnson", unique_id: 1)
          component.with_avatar_with_fallback(src: nil, alt: "Bob Smith", unique_id: 2)
          component.with_avatar_with_fallback(src: nil, alt: "Charlie Brown", unique_id: 3)
        end
      end

      # @label With tooltip and fallbacks
      def with_tooltip_and_fallbacks
        render(Primer::OpenProject::AvatarStack.new(tooltipped: true, body_arguments: { label: "Team members" })) do |component|
          component.with_avatar_with_fallback(src: nil, alt: "Alice Johnson", unique_id: 1)
          component.with_avatar_with_fallback(src: nil, alt: "Bob Smith", unique_id: 2)
          component.with_avatar_with_fallback(src: nil, alt: "Charlie Brown", unique_id: 3)
        end
      end
    end
  end
end
