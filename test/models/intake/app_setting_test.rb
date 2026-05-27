require "test_helper"

class Intake::AppSettingTest < ActiveSupport::TestCase
  test "current returns fixture row" do
    setting = Intake::AppSetting.current
    assert_equal "ai", setting.global_mode
  end

  test "current creates a row if none exists" do
    Intake::AppSetting.delete_all
    assert_difference "Intake::AppSetting.count", 1 do
      Intake::AppSetting.current
    end
  end

  test "rejects invalid global_mode" do
    s = Intake::AppSetting.current
    s.global_mode = "frenzied"
    assert_not s.valid?
  end
end
