# frozen_string_literal: true

module Primer
  module OpenProject
    # @component Primer::OpenProject::PageHeader
    # @label Page Header
    class PageHeaderPreview < ViewComponent::Preview
      # @label Default
      # @snapshot
      def default
        render(Primer::OpenProject::PageHeader.new) do |header|
          header.with_title { "Hello" }
          header.with_description { "Last updated 5 minutes ago by XYZ." }
        end
      end

      # @label Playground
      # @param variant [Symbol] select [medium, large]
      # @param title [String] text
      # @param description [String] text
      def playground(variant: :medium, title: "Hello", description: "Last updated 5 minutes ago by XYZ.")
        render(Primer::OpenProject::PageHeader.new) do |header|
          header.with_title(variant: variant) { title }
          header.with_description { description }
        end
      end

      # @label Large
      def large_title
        render(Primer::OpenProject::PageHeader.new) do |header|
          header.with_title(variant: :large) { "Hello" }
          header.with_description { "Last updated 5 minutes ago by XYZ." }
        end
      end

      # @label With actions
      def actions
        render_with_template(locals: {})
      end

      # @label With back button
      # @param href [String] text
      # @param size [Symbol] select [small, medium, large]
      # @param icon [String] select ["arrow-left", "chevron-left", "triangle-left"]
      def back_button(href: "#", size: :medium, icon: "arrow-left")
        render(Primer::OpenProject::PageHeader.new) do |header|
          header.with_title() { "Hello" }
          header.with_back_button(href: href, size: size, icon: icon, 'aria-label': "Back")
        end
      end

      # @label With breadcrumbs
      def breadcrumbs
        breadcrumb_items = [
          {href: "/foo", text: "Foo"},
          "\u003ca href=\"/foo/bar\"\u003eBar\u003c/a\u003e" ,
          "Baz"
        ]
        render(Primer::OpenProject::PageHeader.new) do |header|
          header.with_title() { "A title" }
          header.with_breadcrumbs(breadcrumb_items)
        end
      end
    end
  end
end
