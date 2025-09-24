# frozen_string_literal: true

require "components/test_helper"

class PrimerOpenProjectDangerDialogTest < Minitest::Test
  include Primer::ComponentTestHelpers

  def test_renders_default
    render_inline(Primer::OpenProject::DangerDialog.new(title: "Danger action")) do |dialog|
      dialog.with_confirmation_message do |message|
        message.with_heading(tag: :h2) { "Danger" }
      end
    end

    assert_selector("dialog.DangerDialog") do
      assert_selector(".Overlay-body h2", text: "Danger")
      assert_selector(".octicon-alert.blankslate-icon")
      assert_selector(".Overlay-footer .Button", count: 2)
    end
  end

  def test_renders_alertdialog_role
    render_inline(Primer::OpenProject::DangerDialog.new(title: "Danger action")) do |dialog|
      dialog.with_confirmation_message do |message|
        message.with_heading(tag: :h2) { "Danger" }
      end
    end

    assert_selector("dialog[role=alertdialog]")
    assert_selector("dialog[aria-modal=true]")
  end

  def test_renders_aria_describedby
    render_inline(Primer::OpenProject::DangerDialog.new(title: "Danger action")) do |dialog|
      dialog.with_confirmation_message do |message|
        message.with_heading(tag: :h2) { "Danger" }
      end
    end

    dialog_labelledby_id = page.find_css("dialog").first.attributes["aria-describedby"].value
    feedback_message_id = page.find_css(".FeedbackMessage").first.attributes["id"].value
    assert_equal dialog_labelledby_id, feedback_message_id
  end

  def test_renders_default_button_text
    render_inline(Primer::OpenProject::DangerDialog.new(title: "Danger action")) do |dialog|
      dialog.with_confirmation_message do |message|
        message.with_heading(tag: :h2) { "Danger" }
      end
    end

    assert_selector("dialog.DangerDialog") do
      assert_selector(".Overlay-footer .Button", text: "Cancel")
      assert_selector(".Overlay-footer .Button", text: "Delete")
    end
  end

  def test_renders_default_with_custom_button_text
    render_inline(Primer::OpenProject::DangerDialog.new(
      title: "Danger action",
      confirm_button_text: "Do it!",
      cancel_button_text: "Don't do it!"
    )) do |dialog|
      dialog.with_confirmation_message do |message|
        message.with_heading(tag: :h2) { "Danger" }
      end
    end

    assert_selector("dialog.DangerDialog") do
      assert_selector(".Overlay-footer .Button", text: "Don't do it!")
      assert_selector(".Overlay-footer .Button", text: "Do it!")
    end
  end

  def test_renders_with_confirmation_check_box
    render_inline(Primer::OpenProject::DangerDialog.new(title: "Danger confirmation action")) do |dialog|
      dialog.with_confirmation_message do |message|
        message.with_heading(tag: :h2) { "Danger" }
      end
      dialog.with_confirmation_check_box { "I confirm this deletion" }
    end

    assert_selector("dialog.DangerDialog") do
      assert_selector(".Overlay-body h2", text: "Danger")
      assert_selector(".octicon-alert.blankslate-icon")
      assert_selector(".FormControl-checkbox + * > .FormControl-label", text: "I confirm this deletion")
      assert_selector(".Overlay-footer .Button", count: 2)
    end
  end

  def test_renders_with_confirmation_check_box_button_text
    render_inline(Primer::OpenProject::DangerDialog.new(title: "Danger confirmation action")) do |dialog|
      dialog.with_confirmation_message do |message|
        message.with_heading(tag: :h2) { "Danger" }
      end
      dialog.with_confirmation_check_box { "I confirm this deletion" }
    end

    assert_selector("dialog.DangerDialog") do
      assert_selector(".Overlay-footer .Button", text: "Cancel")
      assert_selector(".Overlay-footer .Button", text: "Delete permanently")
    end
  end

  def test_renders_with_confirmation_check_box_custom_button_text
    render_inline(Primer::OpenProject::DangerDialog.new(
      title: "Danger confirmation action",
      confirm_button_text: "Do it FOREVER!",
      cancel_button_text: "Nah"
    )) do |dialog|
      dialog.with_confirmation_message do |message|
        message.with_heading(tag: :h2) { "Danger" }
        dialog.with_confirmation_check_box { "I am sure about this deletion" }
      end
    end

    assert_selector("dialog.DangerDialog") do
      assert_selector(".Overlay-footer .Button", text: "Nah")
      assert_selector(".Overlay-footer .Button", text: "Do it FOREVER!")
    end
  end

  def test_does_not_render_if_role_argument_provided
    error = assert_raises(ArgumentError) do
      render_inline(Primer::OpenProject::DangerDialog.new(title: "Invalid action", role: "button"))
    end

    assert_equal "`role` is an invalid argument. `role` will always be set to `alertdialog`.", error.message
  end

  def test_does_not_render_if_no_confirmation_message_provided
    error = assert_raises(ArgumentError) do
      render_inline(Primer::OpenProject::DangerDialog.new(title: "Danger action"))
    end

    assert_equal "DangerDialog requires a confirmation_message", error.message
  end

  def test_does_not_render_if_no_confirmation_check_box_content_provided
    error = assert_raises(ArgumentError) do
      render_inline(Primer::OpenProject::DangerDialog.new(title: "Danger confirmation action")) do |dialog|
        dialog.with_confirmation_message do |message|
          message.with_heading(tag: :h2) { "Danger" }
        end
        dialog.with_confirmation_check_box
      end
    end

    assert_equal "ConfirmationCheckBox requires a content block", error.message
  end

  def test_renders_without_form_by_default
    render_inline(Primer::OpenProject::DangerDialog.new(title: "Danger confirmation action")) do |dialog|
      dialog.with_confirmation_message do |message|
        message.with_heading(tag: :h2) { "Danger" }
      end
      dialog.with_confirmation_check_box { "I confirm this deletion" }
    end

    assert_selector("dialog.DangerDialog") do
      refute_selector("form")
    end
  end

  def test_renders_button_type_buttons_by_default
    render_inline(Primer::OpenProject::DangerDialog.new(title: "Danger confirmation action")) do |dialog|
      dialog.with_confirmation_message do |message|
        message.with_heading(tag: :h2) { "Danger" }
      end
      dialog.with_confirmation_check_box { "I confirm this deletion" }
    end

    assert_selector("dialog.DangerDialog") do
      refute_selector("button[type='submit']")
      assert_selector("button[type='button']", count: 3)
    end
  end

  def test_raises_argument_error_with_invalid_form_arguments
    error = assert_raises do
      render_in_view_context do
        form_with(url: "/my-action", method: :delete) do |f|
          render(Primer::OpenProject::DangerDialog.new(
            title: "Danger confirmation action",
            form_arguments: { builder: f, action: "/my-action" })
          ) do |dialog|
            dialog.with_confirmation_message do |message|
              message.with_heading(tag: :h2) { "Danger" }
            end
            dialog.with_confirmation_check_box { "I confirm this deletion" }
          end
        end
      end
    end

    assert_equal "Pass in either a :builder or :action argument, not both.", error.message
  end

  def test_renders_form_with_form_arguments
    render_inline(Primer::OpenProject::DangerDialog.new(
      title: "Danger confirmation action",
      form_arguments: { action: "/my-action", method: :delete, name: "custom_check" }
     )) do |dialog|
       dialog.with_confirmation_message do |message|
         message.with_heading(tag: :h2) { "Danger" }
       end
       dialog.with_confirmation_check_box { "I confirm this deletion" }
     end

    assert_selector("dialog.DangerDialog") do
      assert_selector("form[action='/my-action']") do
        assert_selector("input[type='hidden'][name='_method'][value='delete']", visible: false)
        assert_selector("input[type='checkbox'][name='custom_check']")
      end
    end
  end

  def test_renders_submit_type_button_with_form_arguments
    render_inline(Primer::OpenProject::DangerDialog.new(
      title: "Danger confirmation action",
      form_arguments: { action: "/my-action", method: :delete }
    )) do |dialog|
      dialog.with_confirmation_message do |message|
        message.with_heading(tag: :h2) { "Danger" }
      end
      dialog.with_confirmation_check_box { "I confirm this deletion" }
    end

    assert_selector("dialog.DangerDialog") do
      assert_selector("button[type='submit']")
      assert_selector("button[type='button']", count: 2)
    end
  end

  def test_renders_submit_type_button_with_form_builder_form_arguments
    render_in_view_context do
      form_with(url: "/my-action", method: :delete) do |f|
        render(Primer::OpenProject::DangerDialog.new(
          title: "Danger confirmation action",
          form_arguments: { builder: f })
        ) do |dialog|
          dialog.with_confirmation_message do |message|
            message.with_heading(tag: :h2) { "Danger" }
          end
          dialog.with_confirmation_check_box { "I confirm this deletion" }
        end
      end
    end

    assert_selector("dialog.DangerDialog") do
      assert_selector("button[type='submit']")
      assert_selector("button[type='button']", count: 2)
    end
  end

  def test_renders_provided_id
    render_inline(Primer::OpenProject::DangerDialog.new(
      id: "danger-dialog", title: "Danger confirmation action"
    )) do |dialog|
      dialog.with_confirmation_message do |message|
        message.with_heading(tag: :h2) { "Danger" }
      end
      dialog.with_confirmation_check_box { "I confirm this deletion" }
    end

    assert_selector("dialog#danger-dialog.DangerDialog") do
      assert_selector("input#danger-dialog-check_box")
      assert_selector("label[for='danger-dialog-check_box']", text: "I confirm this deletion")
    end
  end

  def test_renders_additional_details
    render_inline(Primer::OpenProject::DangerDialog.new(title: "Danger confirmation action")) do |dialog|
      dialog.with_confirmation_message do |message|
        message.with_heading(tag: :h2) { "Danger" }
      end
      dialog.with_additional_details { "Additional important information." }
      dialog.with_confirmation_check_box { "I confirm this deletion" }
    end

    assert_selector("dialog.DangerDialog") do
      assert_selector(".DangerDialog-additionalDetails", text: "Additional important information.")
    end
  end

  def test_renders_live_region_for_confirmation_checkbox
    render_inline(Primer::OpenProject::DangerDialog.new(
      title: "Danger confirmation action"
    )) do |dialog|
      dialog.with_confirmation_message do |message|
        message.with_heading(tag: :h2) { "Danger" }
      end
      dialog.with_confirmation_check_box { "I confirm this deletion" }
    end

    # Check that the live region exists
    assert_selector("live-region[data-target='danger-dialog-form-helper.liveRegion']")
  end
end
