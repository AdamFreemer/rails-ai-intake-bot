require "test_helper"

class Admin::Intake::ShabbatSettingsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:admin)
  end

  test "non-admin redirected" do
    sign_in users(:customer)
    get edit_admin_intake_shabbat_settings_path
    assert_redirected_to root_path
  end

  test "admin sees edit form" do
    sign_in @admin
    get edit_admin_intake_shabbat_settings_path
    assert_response :success
  end

  test "update toggles shabbat_mode_enabled and timezone" do
    sign_in @admin
    patch admin_intake_shabbat_settings_path, params: {
      setting: { shabbat_mode_enabled: "1", shabbat_timezone: "Asia/Jerusalem" }
    }
    s = Intake::AppSetting.current
    assert s.shabbat_mode_enabled
    assert_equal "Asia/Jerusalem", s.shabbat_timezone
  end
end
