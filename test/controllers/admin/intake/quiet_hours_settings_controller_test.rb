require "test_helper"

class Admin::Intake::QuietHoursSettingsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:admin)
  end

  test "non-admin redirected" do
    sign_in users(:customer)
    get edit_admin_intake_quiet_hours_settings_path
    assert_redirected_to root_path
  end

  test "admin sees edit form" do
    sign_in @admin
    get edit_admin_intake_quiet_hours_settings_path
    assert_response :success
  end

  test "update toggles quiet_hours_enabled and timezone" do
    sign_in @admin
    patch admin_intake_quiet_hours_settings_path, params: {
      setting: { quiet_hours_enabled: "1", quiet_hours_timezone: "Asia/Jerusalem" }
    }
    s = Intake::AppSetting.current
    assert s.quiet_hours_enabled
    assert_equal "Asia/Jerusalem", s.quiet_hours_timezone
  end
end
