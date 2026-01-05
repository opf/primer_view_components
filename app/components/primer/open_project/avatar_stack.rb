# frozen_string_literal: true

module Primer
  module OpenProject
    # OpenProject-specific AvatarStack that extends Primer::Beta::AvatarStack
    # to support avatar fallbacks with initials.
    #
    # Uses a different slot name (avatar_with_fallbacks) to avoid conflicts with the parent's avatars slot.
    class AvatarStack < Primer::Beta::AvatarStack
      status :open_project

      # Required list of stacked avatars with fallback support.
      #
      # @param kwargs [Hash] The same arguments as <%= link_to_component(Primer::OpenProject::AvatarWithFallback) %>.
      renders_many :avatar_with_fallbacks, "Primer::OpenProject::AvatarWithFallback"

      # Alias avatar_with_fallbacks as avatars for use in the template
      def avatars
        avatar_with_fallbacks
      end
    end
  end
end
