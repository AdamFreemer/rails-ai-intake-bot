class Intake::Message < ApplicationRecord
  ROLES = %w[user assistant system].freeze
  MESSAGE_TYPES = %w[text image voice document].freeze

  belongs_to :conversation,
             class_name: "Intake::Conversation",
             foreign_key: :intake_conversation_id,
             touch: true

  validates :role, inclusion: { in: ROLES }
  validates :content, presence: true
  validates :message_type, inclusion: { in: MESSAGE_TYPES }
  validates :whatsapp_message_id, uniqueness: true, allow_nil: true

  after_create_commit :touch_conversation_last_message_at
  after_create_commit :broadcast_to_admin

  scope :chronological, -> { order(created_at: :asc) }

  private

  def touch_conversation_last_message_at
    conversation.update_column(:last_message_at, created_at)
  end

  def broadcast_to_admin
    broadcast_append_to(
      conversation,
      target: "intake_messages",
      partial: "admin/intake/messages/message",
      locals: { message: self }
    )
  end
end
