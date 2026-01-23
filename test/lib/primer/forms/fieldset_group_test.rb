# frozen_string_literal: true

require "lib/test_helper"

class Primer::Forms::FieldsetGroupTest < Minitest::Test
  include Primer::ComponentTestHelpers

  # Minimal input-like component that works with Primer::Forms::Group
  class DummyInputComponent < Primer::BaseComponent
    def initialize(hidden: false, type: :text)
      @hidden = hidden
      @type = type
      super(tag: :div)
    end

    def hidden?
      @hidden
    end

    def to_component
      self
    end

    def call
      content_tag(:input, nil, type: @type, class: "dummy-input", hidden: (@hidden ? true : nil))
    end
  end

  def test_renders_heading_section_fieldset_and_fields
    heading_id = "fieldset-group-heading"
    inputs = [
      DummyInputComponent.new(type: :checkbox),
      DummyInputComponent.new(type: :checkbox),
      DummyInputComponent.new(type: :checkbox)
    ]

    render_in_view_context do
      primer_form_with(url: "/foo") do |f|
        render(
          Primer::Forms::FieldsetGroup.new(
            title: "Ultimate answers",
            inputs: inputs,
            builder: f,
            form: Object.new,
            heading_arguments: { id: heading_id }
          )
        )
      end
    end

    assert_selector "section", text: "Ultimate answers"
    assert_selector "fieldset"
    assert_selector "h3##{heading_id}", text: "Ultimate answers"
    assert_selector "section[aria-labelledby='#{heading_id}']"
    assert_selector "fieldset[aria-labelledby='#{heading_id}']"
    assert_selector "fieldset input[type='checkbox']", count: 3
  end

  def test_hides_wrapper_when_all_inputs_are_hidden
    heading_id = "fieldset-group-heading"
    inputs = [DummyInputComponent.new(hidden: true), DummyInputComponent.new(hidden: true)]

    render_in_view_context do
      primer_form_with(url: "/foo") do |f|
        render(
          Primer::Forms::FieldsetGroup.new(
            title: "Foobar",
            inputs: inputs,
            builder: f,
            form: Object.new,
            heading_arguments: { id: heading_id }
          )
        )
      end
    end

    assert_selector "section", visible: :hidden
    assert_selector "fieldset", visible: :hidden
  end
end
