require "test_helper"

class Admin::Intake::ChatbotConfigsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:admin)
  end

  test "non-admin redirected" do
    sign_in users(:customer)
    get edit_admin_intake_chatbot_config_path
    assert_redirected_to root_path
  end

  test "regular admin (not super) redirected with super_admin alert" do
    sign_in users(:regular_admin)
    get edit_admin_intake_chatbot_config_path
    assert_redirected_to root_path
    assert_match(/super admin/i, flash[:alert])
  end

  test "super admin sees edit form" do
    sign_in @admin
    get edit_admin_intake_chatbot_config_path
    assert_response :success
  end

  test "update changes config" do
    sign_in @admin
    patch admin_intake_chatbot_config_path, params: {
      config: { brand_name: "Test Brand", brand_tagline: "Tagline", welcome_message: "Welcome!" }
    }
    c = Intake::ChatbotConfig.current
    assert_equal "Test Brand", c.brand_name
    assert_equal "Tagline", c.brand_tagline
    assert_equal "Welcome!", c.welcome_message
  end
end
