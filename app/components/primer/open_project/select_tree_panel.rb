# frozen_string_literal: true

module Primer
  module OpenProject

    class SelectTreePanel < Primer::Component
      # @private
      module Utils
        def raise_if_role_given!(**system_arguments)
          return if shouldnt_raise_error?
          return unless system_arguments.include?(:role)

          raise(
            "Please avoid passing the `role:` argument to `SelectTreePanel` and its subcomponents. "\
            "The component will automatically apply the correct roles where necessary."
          )
        end
      end

      include Utils

      # The component that should be used to render the list of items in the body of a SelectTreePanel.
      class ItemList < Primer::Alpha::TreeView
        include Utils

        # @param system_arguments [Hash] The arguments accepted by <%= link_to_component(Primer::Alpha::TreeView) %>.
        def initialize(**system_arguments)
          raise_if_role_given!(**system_arguments)
          select_variant = system_arguments.delete(:select_variant) || Primer::Alpha::ActionList::DEFAULT_SELECT_VARIANT

          super(
            p: 2,
            role: "listbox",
            aria_selection_variant: select_variant == :single ? :selected : :checked,
            select_variant: select_variant == :multiple ? :multiple_checkbox : :single,
            **system_arguments
          )
        end

        def with_sub_tree(**system_arguments)
          raise_if_role_given!(**system_arguments)
          super
        end

        def with_leaf(**system_arguments)
          raise_if_role_given!(**system_arguments)
          super
        end
      end

      status :open_project

      DEFAULT_PRELOAD = false

      DEFAULT_FETCH_STRATEGY = :remote
      FETCH_STRATEGIES = [
        DEFAULT_FETCH_STRATEGY,
        :eventually_local,
        :local
      ]

      DEFAULT_SELECT_VARIANT = :single
      SELECT_VARIANT_OPTIONS = [
        DEFAULT_SELECT_VARIANT,
        :multiple,
        :none,
      ].freeze

      DEFAULT_BANNER_SCHEME = :danger
      BANNER_SCHEME_OPTIONS = [
        DEFAULT_BANNER_SCHEME,
        :warning
      ].freeze



      # The unique ID of the panel.
      #
      # @return [String]
      attr_reader :panel_id

      # The unique ID of the panel body.
      #
      # @return [String]
      attr_reader :body_id

      # <%= one_of(Primer::Alpha::ActionMenu::Menu::SELECT_VARIANT_OPTIONS) %>
      #
      # @return [Symbol]
      attr_reader :select_variant

      # <%= one_of(Primer::Alpha::SelectTreePanel::BANNER_SCHEME_OPTIONS) %>
      #
      # @return [Symbol]
      attr_reader :banner_scheme

      # <%= one_of(Primer::Alpha::SelectTreePanel::FETCH_STRATEGIES) %>
      #
      # @return [Symbol]
      attr_reader :fetch_strategy

      # Whether to preload search results when the page loads. If this option is false, results are loaded when the panel is opened.
      #
      # @return [Boolean]
      attr_reader :preload

      alias preload? preload

      # Whether or not to show the filter input.
      #
      # @return [Boolean]
      attr_reader :show_filter

      alias show_filter? show_filter

      # @param title [String] The title that appears at the top of the panel.
      # @param id [String] The unique ID of the panel.
      # @param size [Symbol] The size of the panel. <%= one_of(Primer::Alpha::Overlay::SIZE_OPTIONS) %>
      # @param select_variant [Symbol] <%= one_of(Primer::Alpha::SelectTreePanel::SELECT_VARIANT_OPTIONS) %>
      # @param fetch_strategy [Symbol] <%= one_of(Primer::Alpha::SelectTreePanel::FETCH_STRATEGIES) %>
      # @param no_results_label [String] The label to display when no results are found.
      # @param preload [Boolean] Whether to preload search results when the page loads. If this option is false, results are loaded when the panel is opened.
      # @param dynamic_label [Boolean] Whether or not to display the text of the currently selected item in the show button.
      # @param dynamic_label_prefix [String] If provided, the prefix is prepended to the dynamic label and displayed in the show button.
      # @param dynamic_aria_label_prefix [String] If provided, the prefix is prepended to the dynamic label and set as the value of the `aria-label` attribute on the show button.
      # @param body_id [String] The unique ID of the panel body. If not provided, the body ID will be set to the panel ID with a "-body" suffix.
      # @param tree_arguments [Hash] Arguments to pass to the underlying <%= link_to_component(Primer::Alpha::TreeView) %> component. Only has an effect for the local fetch strategy.
      # @param form_arguments [Hash] Form arguments. Supported for all fetch strategies.
      # @param show_filter [Boolean] Whether or not to show the filter input.
      # @param open_on_load [Boolean] Open the panel when the page loads.
      # @param anchor_align [Symbol] The anchor alignment of the Overlay. <%= one_of(Primer::Alpha::Overlay::ANCHOR_ALIGN_OPTIONS) %>
      # @param anchor_side [Symbol] The side to anchor the Overlay to. <%= one_of(Primer::Alpha::Overlay::ANCHOR_SIDE_OPTIONS) %>
      # @param loading_label [String] The aria-label to use when the panel is loading, defaults to 'Loading content...'.
      # @param loading_description [String] The description to use when the panel is loading. If not provided, no description will be used.
      # @param banner_scheme [Symbol] The scheme for the error banner <%= one_of(Primer::Alpha::SelectTreePanel::BANNER_SCHEME_OPTIONS) %>
      # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
      def initialize(
        title: "Menu",
        id: self.class.generate_id,
        size: :small,
        select_variant: DEFAULT_SELECT_VARIANT,
        fetch_strategy: DEFAULT_FETCH_STRATEGY,
        no_results_label: "No results found",
        preload: DEFAULT_PRELOAD,
        dynamic_label: false,
        dynamic_label_prefix: nil,
        dynamic_aria_label_prefix: nil,
        body_id: nil,
        tree_arguments: {},
        form_arguments: {},
        show_filter: true,
        open_on_load: false,
        anchor_align: Primer::Alpha::Overlay::DEFAULT_ANCHOR_ALIGN,
        anchor_side: Primer::Alpha::Overlay::DEFAULT_ANCHOR_SIDE,
        loading_label: "Loading content...",
        loading_description: nil,
        banner_scheme: DEFAULT_BANNER_SCHEME,
        **system_arguments
      )
        raise_if_role_given!(**system_arguments)

        @panel_id = id
        @body_id = body_id || "#{@panel_id}-body"
        @preload = fetch_or_fallback_boolean(preload, DEFAULT_PRELOAD)
        @select_variant = fetch_or_fallback(SELECT_VARIANT_OPTIONS, select_variant, DEFAULT_SELECT_VARIANT)
        @fetch_strategy = fetch_or_fallback(FETCH_STRATEGIES, fetch_strategy, DEFAULT_FETCH_STRATEGY)
        @no_results_label = no_results_label
        @show_filter = show_filter
        @dynamic_label = dynamic_label
        @dynamic_label_prefix = dynamic_label_prefix
        @dynamic_aria_label_prefix = dynamic_aria_label_prefix
        @loading_label = loading_label
        @loading_description_id = nil

        @form_builder = form_arguments[:builder]
        @value = form_arguments[:value]
        @input_name = form_arguments[:name]

        @tree_form_arguments = {}

        if loading_description.present?
          @loading_description_id = "#{@panel_id}-loading-description"
        end
        @loading_description = loading_description
        @banner_scheme = fetch_or_fallback(BANNER_SCHEME_OPTIONS, banner_scheme, DEFAULT_BANNER_SCHEME)

        @system_arguments = deny_tag_argument(**system_arguments)
        @system_arguments[:id] = @panel_id
        @system_arguments[:"anchor-align"] = fetch_or_fallback(Primer::Alpha::Overlay::ANCHOR_ALIGN_OPTIONS, anchor_align, Primer::Alpha::Overlay::DEFAULT_ANCHOR_ALIGN)
        @system_arguments[:"anchor-side"] = Primer::Alpha::Overlay::ANCHOR_SIDE_MAPPINGS[fetch_or_fallback(Primer::Alpha::Overlay::ANCHOR_SIDE_OPTIONS, anchor_side, Primer::Alpha::Overlay::DEFAULT_ANCHOR_SIDE)]

        @title = title
        @system_arguments[:tag] = :"select-tree-panel"

        @system_arguments[:data] = merge_data(
          system_arguments, {
            data: { select_variant: @select_variant, fetch_strategy: @fetch_strategy, open_on_load: open_on_load }.tap do |data|
              data[:dynamic_label] = dynamic_label if dynamic_label
              data[:dynamic_label_prefix] = dynamic_label_prefix if dynamic_label_prefix.present?
              data[:dynamic_aria_label_prefix] = dynamic_aria_label_prefix if dynamic_aria_label_prefix.present?
            end
          }
        )

        @dialog = Primer::BaseComponent.new(
          id: "#{@panel_id}-dialog",
          "aria-labelledby": "#{@panel_id}-dialog-title",
          tag: :dialog,
          data: { target: "select-tree-panel.dialog" },
          classes: class_names(
            "Overlay",
            "Overlay-whenNarrow",
            Primer::Alpha::Dialog::SIZE_MAPPINGS[
              fetch_or_fallback(Primer::Alpha::Dialog::SIZE_OPTIONS, size, Primer::Alpha::Dialog::DEFAULT_SIZE)
            ],
          ),
          style: "position: absolute;",
        )

        @tree = Primer::OpenProject::SelectTreePanel::ItemList.new(
          **tree_arguments,
          form_arguments: @tree_form_arguments,
          id: "#{@panel_id}-list",
          select_variant: @select_variant,
          aria: {
            label: "#{title} options"
          }
        )

        return if @show_filter || @fetch_strategy != :remote
        return if shouldnt_raise_error?

        raise(
          "Hiding the filter input with a remote fetch strategy is not permitted, "\
          "since such a combinaton of options will cause the component to only "\
          "fetch items from the server once when the panel opens for the first time; "\
          "this is what the `:eventually_local` fetch strategy is designed to do. "\
          "Consider passing `show_filter: true` or use the `:eventually_local` fetch "\
          "strategy instead."
        )
      end

      # @!parse
      #   # Adds an item to the list. Note that this method only has an effect for the local fetch strategy.
      #   #
      #   # @param system_arguments [Hash] The arguments accepted by <%= link_to_component(Primer::Alpha::TreeView) %>'s `item` slot.
      #   def with_item(**system_arguments)
      #   end
      #
      #   # Adds an avatar item to the list. Note that this method only has an effect for the local fetch strategy.
      #
      #   # @param system_arguments [Hash] The arguments accepted by <%= link_to_component(Primer::Alpha::TreeView) %>'s `item` slot.
      #   def with_avatar_item
      #   end

      delegate :with_sub_tree, :with_leaf, to: :@tree

      # Renders content in a footer region below the list of items.
      #
      # @param system_arguments [Hash] The arguments accepted by <%= link_to_component(Primer::Alpha::Dialog::Footer) %>.
      renders_one :footer, Primer::Alpha::Dialog::Footer

      # Renders content underneath the title at the top of the panel.
      #
      # @param system_arguments [Hash] The arguments accepted by <%= link_to_component(Primer::Alpha::Dialog::Header) %>'s `subtitle` slot.
      renders_one :subtitle

      # Adds a show button (i.e. a button) that will open the panel when clicked.
      #
      # @param icon [String] Name of <%= link_to_octicons %> to use instead of text. If an [icon](https://primer.style/octicons/usage-guidelines/) is provided, a <%= link_to_component(Primer::Beta::IconButton) %> will be rendered. Otherwise a <%= link_to_component(Primer::Beta::Button) %> will be rendered.
      # @param system_arguments [Hash] The arguments accepted by <%= link_to_component(Primer::Beta::Button) %>.
      renders_one :show_button, lambda { |icon: nil, **system_arguments|
        system_arguments[:id] = "#{@panel_id}-button"

        system_arguments[:aria] = merge_aria(
          system_arguments,
          { aria: { controls: "#{@panel_id}-dialog", "haspopup": "dialog", "expanded": "false" } }
        )

        if icon.present?
          Primer::Beta::IconButton.new(icon: icon, **system_arguments)
        else
          Primer::Beta::Button.new(**system_arguments)
        end
      }

      # Customizable content for the error message that appears when items are fetched for the first time. This message
      # appears in place of the list of items.
      # For more information, see the [documentation regarding SelectTreePanel error messaging](/components/SelectTreePanel#errorwarning).
      renders_one :preload_error_content

      # Customizable content for the error message that appears when items are fetched as the result of a filter
      # operation. This message appears as a banner above the previously fetched list of items.
      # For more information, see the [documentation regarding SelectTreePanel error messaging](/components/SelectTreePanel#errorwarning).
      renders_one :error_content

      private

      def before_render
        content
      end

      def required_form_arguments_given?
        @input_name && @form_builder
      end

      def multi_select?
        select_variant == :multiple
      end
    end
  end
end
