class Intake::Conversation < ApplicationRecord
  MODES = %w[ai paused human].freeze
  STATUSES = %w[active completed abandoned].freeze
  CHANNELS = %w[whatsapp web].freeze

  has_many :messages,
           -> { order(created_at: :asc) },
           class_name: "Intake::Message",
           foreign_key: :intake_conversation_id,
           dependent: :destroy
  belongs_to :lead, class_name: "Intake::Lead", optional: true
  belongs_to :assigned_to, class_name: "User", optional: true

  validates :whatsapp_number, presence: true
  validates :mode, inclusion: { in: MODES }
  validates :status, inclusion: { in: STATUSES }
  validates :channel, inclusion: { in: CHANNELS }

  scope :active, -> { where(status: "active") }
  scope :completed, -> { where(status: "completed") }

  # Returns the active conversation for this number, or builds a new one if the
  # last one was completed or abandoned. Returning users with a completed intake
  # get a fresh conversation (Phase 3 layers in the "returning user" reply).
  def self.find_or_create_for_number(phone)
    active.find_by(whatsapp_number: phone) ||
      create!(whatsapp_number: phone, mode: "ai", status: "active", channel: "whatsapp")
  end

  def ai_mode?
    mode == "ai"
  end

  def human_mode?
    mode == "human"
  end

  def paused_mode?
    mode == "paused"
  end

  # Live-update the admin view when intake completes — swap in the summary card
  # at the bottom of the chat thread and refresh the right-side sidebar with
  # the freshly-extracted lead. Without this, admins have to reload.
  after_update_commit :broadcast_intake_completion

  private

  def broadcast_intake_completion
    return unless saved_change_to_intake_complete? && intake_complete?

    broadcast_replace_to self,
                         target: "intake_summary_card_#{id}",
                         partial: "admin/intake/conversations/intake_summary_frame",
                         locals: { conversation: self }

    broadcast_replace_to self,
                         target: "intake_sidebar_#{id}",
                         partial: "admin/intake/conversations/sidebar",
                         locals: { conversation: self }
  end
end
