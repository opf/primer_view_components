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

      # @label Back button
      def back_button
        render(Primer::OpenProject::PageHeader.new) do |header|
          header.with_title() { "Hello" }
          header.with_back_button(href: "#", 'aria-label': "Back")
        end
      end

      # @label Back button and breadcrumbs
      def back_button_and_breadcrumbs
        breadcrumb_items = [
          {href: "/foo", text: "Foo"},
          "\u003ca href=\"/foo/bar\"\u003eBar\u003c/a\u003e" ,
          "test"
        ]
        render(Primer::OpenProject::PageHeader.new) do |header|
          header.with_title() { "Hello" }
          header.with_back_button(href: "#", 'aria-label': "Back")
          header.with_breadcrumbs(breadcrumb_items)
        end
      end

      # @label Breadcrumbs don't show breadcrumb
      def back_button_and_no_breadcrumbs
        breadcrumb_items = [
          "test1",
          "test2" ,
          "test3"
        ]
        render(Primer::OpenProject::PageHeader.new) do |header|
          header.with_title() { "Hello" }
          header.with_back_button(href: "#", 'aria-label': "Back")
          header.with_breadcrumbs(breadcrumb_items, show_breadcrumb: false)
        end
      end

      # @label With actions
      def actions
        render_with_template(locals: {})
      end
    end
  end
end
