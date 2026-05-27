class ProcessIntakeMessageJob < ApplicationJob
  queue_as :default

  # Inbound Twilio WhatsApp message handler. Idempotent on whatsapp_message_id
  # so Twilio retries don't double-store.
  def perform(phone:, body:, message_sid:, num_media: 0, media_url: nil)
    conversation = Intake::Conversation.find_or_create_for_number(phone)

    return if message_sid.present? &&
              conversation.messages.exists?(whatsapp_message_id: message_sid)

    conversation.messages.create!(
      role: "user",
      content: body.presence || (media_url.present? ? "[media message]" : "(empty)"),
      message_type: num_media.to_i > 0 ? "image" : "text",
      whatsapp_message_id: message_sid,
      media_url: media_url
    )

    IntakeOrchestrator.new(conversation).call
  end
end
