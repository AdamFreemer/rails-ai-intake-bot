module Admin
  module Intake
    class ConversationsController < ApplicationController
      before_action :authenticate_user!
      before_action :require_admin!
      layout "admin"

      before_action :set_conversation, only: [ :show, :take_over, :release, :mark_complete, :mark_abandoned ]

      # Allowlist of sortable columns. Maps the user-facing sort key (sent in
      # ?sort=) to the SQL expression we ORDER BY. Anything outside this map
      # falls back to the default (newest activity first).
      SORTABLE_COLUMNS = {
        "phone"        => "intake_conversations.whatsapp_number",
        "status"       => "intake_conversations.status",
        "mode"         => "intake_conversations.mode",
        "lead_name"    => "intake_leads.first_name",
        "last_message" => "intake_conversations.last_message_at"
      }.freeze

      def index
        @conversations = ::Intake::Conversation
          .includes(:lead, :messages)
          .left_joins(:lead)

        @conversations = @conversations.where(status: params[:status]) if params[:status].present?
        @conversations = @conversations.where(mode: params[:mode]) if params[:mode].present?
        @conversations = apply_search(@conversations, params[:q]) if params[:q].present?

        @conversations = apply_sort(@conversations)
      end

      def show
        @messages = @conversation.messages.chronological
        @lead = @conversation.lead
      end

      def take_over
        @conversation.update!(mode: "human", assigned_to: current_user)
        redirect_to admin_intake_conversation_path(@conversation), notice: "You've taken over this conversation."
      end

      def release
        @conversation.update!(mode: "ai", assigned_to: nil)
        redirect_to admin_intake_conversation_path(@conversation), notice: "Released back to the AI."
      end

      def mark_complete
        @conversation.update!(status: "completed", intake_complete: true)
        redirect_to admin_intake_conversation_path(@conversation), notice: "Marked complete."
      end

      def mark_abandoned
        @conversation.update!(status: "abandoned")
        redirect_to admin_intake_conversations_path, notice: "Marked abandoned."
      end

      private

      def set_conversation
        @conversation = ::Intake::Conversation.find(params[:id])
      end

      # Searches across phone number, any message content in the thread, and
      # the linked lead's first/last name. Single search box, ORed across fields.
      def apply_search(scope, query)
        term = "%#{query.downcase}%"
        scope
          .left_joins(:messages)
          .where(
            "LOWER(intake_conversations.whatsapp_number) LIKE :t " \
            "OR LOWER(intake_messages.content) LIKE :t " \
            "OR LOWER(intake_leads.first_name) LIKE :t " \
            "OR LOWER(intake_leads.last_name) LIKE :t",
            t: term
          )
          .distinct
      end

      def apply_sort(scope)
        column = SORTABLE_COLUMNS[params[:sort]]
        if column
          direction = params[:dir] == "asc" ? "asc" : "desc"
          # NULLS LAST keeps rows missing the sorted field (e.g. no linked lead)
          # at the bottom regardless of direction.
          scope.order(Arel.sql("#{column} #{direction} NULLS LAST, intake_conversations.last_message_at DESC NULLS LAST"))
        else
          scope.order(Arel.sql("intake_conversations.last_message_at DESC NULLS LAST, intake_conversations.created_at DESC"))
        end
      end
    end
  end
end
