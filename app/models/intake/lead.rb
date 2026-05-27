class Intake::Lead < ApplicationRecord
  STATUSES = %w[new reviewed accepted declined vip_prospect].freeze
  SOURCES = %w[whatsapp web airtable_import].freeze

  belongs_to :conversation,
             class_name: "Intake::Conversation",
             foreign_key: :intake_conversation_id,
             optional: true

  validates :status, inclusion: { in: STATUSES }
  validates :source, inclusion: { in: SOURCES }

  scope :by_status, ->(status) { where(status: status) }
  scope :search, ->(q) {
    return all if q.blank?
    term = "%#{q.downcase}%"
    where(
      "LOWER(first_name) LIKE :t OR LOWER(last_name) LIKE :t OR LOWER(about_me) LIKE :t OR LOWER(what_looking_for) LIKE :t",
      t: term
    )
  }

  def full_name
    [ first_name, last_name ].compact.join(" ").presence
  end
end
