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

      status :open_project

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

      # Whether or not to show the filter input.
      #
      # @return [Boolean]
      attr_reader :show_filter

      alias show_filter? show_filter

      # @param title [String] The title that appears at the top of the panel.
      # @param id [String] The unique ID of the panel.
      # @param size [Symbol] The size of the panel. <%= one_of(Primer::Alpha::Overlay::SIZE_OPTIONS) %>
      # @param select_variant [Symbol] <%= one_of(Primer::Alpha::SelectTreePanel::SELECT_VARIANT_OPTIONS) %>
      # @param no_results_node_arguments [Hash] Arguments that will be passed to a <%= link_to_component(Primer::Alpha::TreeView::LeafNode) %> component that appears when no items match the filter criteria.
      # @param dynamic_label [Boolean] Whether or not to display the text of the currently selected item in the show button.
      # @param dynamic_label_prefix [String] If provided, the prefix is prepended to the dynamic label and displayed in the show button.
      # @param dynamic_aria_label_prefix [String] If provided, the prefix is prepended to the dynamic label and set as the value of the `aria-label` attribute on the show button.
      # @param body_id [String] The unique ID of the panel body. If not provided, the body ID will be set to the panel ID with a "-body" suffix.
      # @param tree_view_arguments [Hash] Arguments to pass to the underlying <%= link_to_component(Primer::Alpha::TreeView) %> component. Only has an effect for the local fetch strategy.
      # @param form_arguments [Hash] Form arguments. Supported for all fetch strategies.
      # @param show_filter [Boolean] Whether or not to show the filter input.
      # @param filter_input_arguments [Hash] Arguments that will be passed to the <%= link_to_component(Primer::Alpha::TextField) %> component.
      # @param filter_mode_control_arguments [Hash] Arguments that will be passed to the <%= link_to_component(Primer::Alpha::SegmentedControl) %> component.
      # @param include_sub_items_check_box_arguments [Hash] Arguments that will be passed to the <%= link_to_component(Primer::Alpha::CheckBox) %> component.
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
        no_results_node_arguments: Primer::OpenProject::FilterableTreeView::DEFAULT_NO_RESULTS_NODE_ARGUMENTS.dup,
        dynamic_label: false,
        dynamic_label_prefix: nil,
        dynamic_aria_label_prefix: nil,
        body_id: nil,
        tree_view_arguments: {},
        form_arguments: {},
        show_filter: true,
        filter_input_arguments: Primer::OpenProject::FilterableTreeView::DEFAULT_FILTER_INPUT_ARGUMENTS.dup,
        filter_mode_control_arguments: Primer::OpenProject::FilterableTreeView::DEFAULT_FILTER_MODE_CONTROL_ARGUMENTS.dup,
        include_sub_items_check_box_arguments: Primer::OpenProject::FilterableTreeView::DEFAULT_INCLUDE_SUB_ITEMS_CHECK_BOX_ARGUMENTS.dup,
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
        @select_variant = fetch_or_fallback(SELECT_VARIANT_OPTIONS, select_variant, DEFAULT_SELECT_VARIANT)
        @show_filter = show_filter
        @dynamic_label = dynamic_label
        @dynamic_label_prefix = dynamic_label_prefix
        @dynamic_aria_label_prefix = dynamic_aria_label_prefix
        @loading_label = loading_label
        @loading_description_id = nil

        @form_builder = form_arguments[:builder]
        @value = form_arguments[:value]
        @input_name = form_arguments[:name]

        @tree_view_form_arguments = {}

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
            data: { select_variant: @select_variant, open_on_load: open_on_load }.tap do |data|
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

        @tree_view = Primer::Alpha::TreeView.new(
          **tree_view_arguments,
          form_arguments: @tree_view_form_arguments,
          id: "#{@panel_id}-list",
          select_variant: @select_variant,
          aria: {
            label: "#{title} options"
          }
        )

        @filter_mode_control_arguments = filter_mode_control_arguments.reverse_merge(Primer::OpenProject::FilterableTreeView::DEFAULT_FILTER_MODE_CONTROL_ARGUMENTS)
        @filter_mode_control_arguments[:data] = merge_data(
          @filter_mode_control_arguments, {
            data: { target: "select-tree-panel.filterModeControlList" }
          }
        )
        @filter_mode_control = Primer::Alpha::SegmentedControl.new(**@filter_mode_control_arguments)

        @include_sub_items_check_box_arguments = include_sub_items_check_box_arguments.reverse_merge(Primer::OpenProject::FilterableTreeView::DEFAULT_INCLUDE_SUB_ITEMS_CHECK_BOX_ARGUMENTS)
        @include_sub_items_check_box_arguments[:data] = merge_data(
          @include_sub_items_check_box_arguments, {
            data: { target: "elect-tree-panel.includeSubItemsCheckBox" }
          }
        )
        @include_sub_items_check_box = Primer::Alpha::CheckBox.new(**@include_sub_items_check_box_arguments)

        @no_results_node_arguments = no_results_node_arguments
      end

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

      # Customizable content for the error message that appears when items are fetched as the result of a filter
      # operation. This message appears as a banner above the previously fetched list of items.
      # For more information, see the [documentation regarding SelectTreePanel error messaging](/components/SelectTreePanel#errorwarning).
      renders_one :error_content

      def with_default_filter_modes
        Primer::OpenProject::FilterableTreeView::DEFAULT_FILTER_MODES.each do |name, system_arguments|
          with_filter_mode(name: name, **system_arguments)
        end
      end

      def with_filter_mode(name:, **system_arguments)
        system_arguments[:data] = merge_data(
          system_arguments, {
            data: { name: name }
          }
        )

        @filter_mode_control.with_item(**system_arguments)
      end

      def with_sub_tree(**system_arguments, &block)
        system_arguments[:select_variant] ||= :multiple

        if system_arguments[:select_variant] != :multiple && system_arguments[:select_variant] != :single
          raise ArgumentError, "FilterableTreeView only supports `:multiple` or `:single` as select_variant"
        end

        if system_arguments[:select_variant] == :single
          # In single selection, the include sub-items checkbox and the SegmentedControl make no sense
          @include_sub_items_check_box_arguments[:hidden] = true
          @include_sub_items_check_box_arguments[:checked] = false
          @filter_mode_control_arguments[:hidden] = true
        end

        @tree_view.with_sub_tree(
          sub_tree_component_klass: Primer::OpenProject::FilterableTreeView::SubTree,
          **system_arguments,
          select_strategy: :self,
          &block
        )
      end

      def with_leaf(**system_arguments, &block)
        system_arguments[:select_variant] ||= :multiple

        if system_arguments[:select_variant] != :multiple && system_arguments[:select_variant] != :single
          raise ArgumentError, "FilterableTreeView only supports `:multiple` or `:single` as select_variant"
        end

        if system_arguments[:select_variant] == :single
          # In single selection, the include sub-items checkbox and the SegmentedControl make no sense
          @include_sub_items_check_box_arguments[:hidden] = true
          @include_sub_items_check_box_arguments[:checked] = false
          @filter_mode_control_arguments[:hidden] = true
        end

        @tree_view.with_leaf(
          **system_arguments,
          &block
        )
      end

      private

      def before_render
        content

        if @filter_mode_control.present? && @filter_mode_control.items.empty?
          with_default_filter_modes
        end
      end

      def hide_filter_mode_control?
        @filter_mode_control_arguments[:hidden]
      end

      def hide_include_sub_items_check_box?
        @include_sub_items_check_box_arguments[:hidden]
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
