require "test_helper"

class Admin::Intake::GeneralSettingsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:admin)
  end

  test "non-admin redirected" do
    sign_in users(:customer)
    get edit_admin_intake_general_settings_path
    assert_redirected_to root_path
  end

  test "admin sees edit form" do
    sign_in @admin
    get edit_admin_intake_general_settings_path
    assert_response :success
  end

  test "update changes global_mode and paused_auto_reply" do
    sign_in @admin
    patch admin_intake_general_settings_path, params: {
      setting: { global_mode: "paused", paused_auto_reply: "Be right back!" }
    }
    s = Intake::AppSetting.current
    assert_equal "paused", s.global_mode
    assert_equal "Be right back!", s.paused_auto_reply
  end

  test "update rejects invalid global_mode" do
    sign_in @admin
    patch admin_intake_general_settings_path, params: { setting: { global_mode: "frenzied" } }
    assert_response :unprocessable_entity
  end
end
