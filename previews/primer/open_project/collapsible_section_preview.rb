# frozen_string_literal: true

# Setup Playground to use all available component props
# Setup Features to use individual component props and combinations

module Primer
  module OpenProject
    # @label CollapsibleSection
    class CollapsibleSectionPreview < ViewComponent::Preview
      # @label Playground
      # @param caption [String] text
      # @param show_additional_information [Boolean] toggle
      # @param collapsed [String] select ["false", "true", "locked"]
      def playground(caption: "(optional)", show_additional_information: false, collapsed: "false")
        collapsed = { "false" => false, "true" => true, "locked" => :locked }.fetch(collapsed)
        render_with_template(
          template: "primer/open_project/collapsible_section_preview/playground",
          locals: { caption: caption, show_additional_information: show_additional_information, collapsed: collapsed }
        )
      end

      # @label Default
      # @snapshot
      def default
        render_with_template(
          template: "primer/open_project/collapsible_section_preview/default",
          locals: { }
        )
      end

      # @label With additional information
      # @snapshot
      def with_additional_information
        render_with_template(
          template: "primer/open_project/collapsible_section_preview/with_additional_information",
          locals: { }
        )
      end

      # @label With caption
      # @snapshot
      def with_caption
        render_with_template(
          template: "primer/open_project/collapsible_section_preview/with_caption",
          locals: { }
        )
      end

      # @label Collapsed
      # @snapshot
      def collapsed
        render_with_template(
          template: "primer/open_project/collapsible_section_preview/collapsed",
          locals: { }
        )
      end

      # @label Non-collapsible
      # @snapshot
      def non_collapsible
        render_with_template(
          template: "primer/open_project/collapsible_section_preview/non_collapsible",
          locals: { }
        )
      end

      # @label With link in title
      # @hidden
      def with_link_in_title
        render_with_template(
          template: "primer/open_project/collapsible_section_preview/with_link_in_title",
          locals: { }
        )
      end
    end
  end
end
