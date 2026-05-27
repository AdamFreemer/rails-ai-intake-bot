class Intake::ChatbotConfig < ApplicationRecord
  # Singleton accessor — one row, seeded in db/seeds.rb.
  def self.current
    first || create!
  end
end
