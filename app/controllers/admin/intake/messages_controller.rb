module Admin
  module Intake
    class MessagesController < ApplicationController
      before_action :authenticate_user!
      before_action :require_admin!
      layout "admin"

      def create
        @conversation = ::Intake::Conversation.find(params[:conversation_id])
        content = params.dig(:message, :content).to_s.strip

        if content.blank?
          redirect_to admin_intake_conversation_path(@conversation), alert: "Message can't be blank."
          return
        end

        @conversation.messages.create!(role: "assistant", content: content, message_type: "text")
        WhatsappSender.send_message(to: @conversation.whatsapp_number, body: content)

        redirect_to admin_intake_conversation_path(@conversation)
      end
    end
  end
end
