class Intake::AppSetting < ApplicationRecord
  GLOBAL_MODES = %w[ai paused].freeze

  validates :global_mode, inclusion: { in: GLOBAL_MODES }

  def self.current
    first || create!
  end
end
