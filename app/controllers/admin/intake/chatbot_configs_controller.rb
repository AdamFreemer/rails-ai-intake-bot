module Admin
  module Intake
    class ChatbotConfigsController < ApplicationController
      before_action :authenticate_user!
      before_action :require_super_admin!
      layout "admin"

      def edit
        @config = ::Intake::ChatbotConfig.current
      end

      def update
        @config = ::Intake::ChatbotConfig.current
        if @config.update(config_params)
          redirect_to edit_admin_intake_chatbot_config_path, notice: "Chatbot config updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      private

      def config_params
        params.require(:config).permit(
          :brand_name, :brand_tagline, :bot_name,
          :welcome_message, :completion_message,
          :paused_reply, :quiet_hours_reply,
          :media_received_reply, :returning_user_reply,
          :error_fallback_reply,
          :custom_system_prompt_additions
        )
      end
    end
  end
end
