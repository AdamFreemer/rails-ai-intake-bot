require "test_helper"

class Intake::ChatbotConfigTest < ActiveSupport::TestCase
  test "current returns existing fixture row" do
    config = Intake::ChatbotConfig.current
    assert_equal "AcmeBot", config.brand_name
  end

  test "current creates a row if none exists" do
    Intake::ChatbotConfig.delete_all
    assert_difference "Intake::ChatbotConfig.count", 1 do
      Intake::ChatbotConfig.current
    end
  end
end
