# frozen_string_literal: true

module Primer
  module OpenProject
    module BorderBox
      # A component to be used inside Primer::Beta::BorderBox.
      # It will toggle the visibility of the complete Box body
      class CollapsibleHeader < Primer::Component
        status :open_project

        TITLE_TAG_DEFAULT = :h3
        TITLE_TAG_OPTIONS = [:h1, :h2, TITLE_TAG_DEFAULT, :h4, :h5, :h6].freeze

        # Required title
        #
        # @param tag [Symbol] <%= one_of(Primer::OpenProject::BorderBox::CollapsibleHeader::TITLE_TAG_OPTIONS) %>
        # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
        renders_one :title, lambda { |tag: TITLE_TAG_DEFAULT, **system_arguments|
          system_arguments[:classes] = class_names(
            system_arguments[:classes],
            "CollapsibleHeader-title",
            "Box-title"
          )

          Primer::Beta::Heading.new(tag: fetch_or_fallback(TITLE_TAG_OPTIONS, tag, TITLE_TAG_DEFAULT), **system_arguments)
        }

        # Optional count
        #
        # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
        renders_one :count, lambda { |**system_arguments|
          system_arguments[:mr] ||= 2
          system_arguments[:scheme] ||= :primary
          system_arguments[:classes] = class_names(
            system_arguments[:classes],
            "CollapsibleHeader-count"
          )

          Primer::Beta::Counter.new(**system_arguments)
        }

        # Optional description
        #
        # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
        renders_one :description, lambda { |**system_arguments|
          system_arguments[:color] ||= :subtle
          system_arguments[:trim] = true
          system_arguments[:classes] = class_names(
            system_arguments[:classes],
            "CollapsibleHeader-description"
          )

          Primer::Beta::Text.new(**system_arguments)
        }

        # @param id [String] The unique ID of the collapsible header.
        # @param box [Primer::Beta::BorderBox] Deprecated. Previously used to reference the parent BorderBox.
        # @param collapsed [Boolean] Whether the header is collapsed on initial render.
        # @param collapsible_id [String] The id or ids of the elements that will be collapsed. This should include the BorderBox's list, body and footer. This will be required in future versions.
        # @param multi_line [Boolean] Whether the description is on its own line and can wrap across multiple lines.
        # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
        def initialize(id: self.class.generate_id, box: nil, collapsed: false, collapsible_id: nil, multi_line: true, **system_arguments)
          deprecation_warn("The `box:` param is deprecated and a no-op. It will be removed in a future version.") if box
          deprecation_warn("Omitting the `collapsible_id` param is deprecated. It will be required in a future version.") unless collapsible_id

          @collapsed = collapsed
          @collapsible_id = collapsible_id

          @system_arguments = deny_tag_argument(**system_arguments)
          @system_arguments[:tag] = :"collapsible-header"
          @system_arguments[:id] = id
          @system_arguments[:classes] = class_names(
            system_arguments[:classes],
            "CollapsibleHeader",
            "CollapsibleHeader--collapsed" => @collapsed,
            "CollapsibleHeader--multi-line" => multi_line
          )

          if @collapsed
            @system_arguments[:data] = merge_data(
              @system_arguments, {
                data: {
                  collapsed: @collapsed
                }
              }
            )
          end

          @trigger_area_arguments = { tag: :div }
          @trigger_area_arguments[:role] = "button"
          @trigger_area_arguments[:tabindex] = 0
          @trigger_area_arguments[:classes] = "CollapsibleHeader-triggerArea"
          @trigger_area_arguments[:aria] = {
            controls: @collapsible_id,
            expanded: !@collapsed
          }
          @trigger_area_arguments[:data] = {
            target: "collapsible-header.triggerElement",
            action: "click:collapsible-header#toggle keydown:collapsible-header#toggleViaKeyboard"
          }
        end

        private

        def before_render
          content
        end

        def render?
          raise ArgumentError, "Title must be present" unless title?

          true
        end

        def deprecation_warn(message)
          return if Rails.env.production? || silence_deprecations?

          ::Primer::ViewComponents.deprecation.warn(message)
        end
      end
    end
  end
end
