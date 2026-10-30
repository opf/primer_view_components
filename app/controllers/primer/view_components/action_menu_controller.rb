# frozen_string_literal: true

module Primer
  module ViewComponents
    # :nodoc:
    # :nocov:
    class ActionMenuController < ApplicationController
      layout false

      def landing; end

      def deferred
        sleep params[:delay].to_f if params[:delay].present?
        status = request_gate_status
        return head(status) unless status == 200

        assign_deferred_params
        render "primer/view_components/action_menu/deferred"
      end

      def deferred_preload
        status = request_gate_status
        return head(status) unless status == 200

        assign_deferred_params
        render "primer/view_components/action_menu/deferred_preload"
      end

      def form_action
        respond_to do |format|
          format.html do
            @value = form_action_selected_value
            @other_params = form_action_other_params
          end

          format.json do
            render json: { value: form_action_selected_value, other_params: form_action_other_params }
          end
        end
      end

      private

      # Test-only: holds the request until the test releases it and returns
      # the status it was released with (see test/test_helpers/request_gate.rb).
      def request_gate_status
        return 200 unless params[:gate].present? && defined?(Primer::RequestGate)

        Primer::RequestGate.pass(params[:gate])
      end

      def assign_deferred_params
        @label = params[:label].presence
        @deferred_sub = params[:deferred_sub].present?
      end

      def form_action_selected_value
        params.permit(:foo)[:foo] || params.permit(foo: [])[:foo]
      end

      def form_action_other_params
        params.permit!.to_hash.tap do |all|
          case all
          when Hash
            all.delete("foo")
            all.delete("authenticity_token")
          when Array
            all.delete(form_action_selected_value)
          end
        end
      end
    end
  end
end
