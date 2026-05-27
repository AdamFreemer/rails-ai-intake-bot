require "test_helper"

class Admin::Intake::LeadsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:admin)
    @customer = users(:customer)
    @lead = intake_leads(:sarah)
  end

  test "non-admin redirected" do
    sign_in @customer
    get admin_intake_leads_path
    assert_redirected_to root_path
  end

  test "admin sees index" do
    sign_in @admin
    get admin_intake_leads_path
    assert_response :success
  end

  test "search filter narrows results" do
    sign_in @admin
    get admin_intake_leads_path, params: { q: "sarah" }
    assert_response :success
    assert_includes response.body, "Sarah"
    assert_not_includes response.body, intake_leads(:reviewed).first_name
  end

  test "status filter narrows results" do
    sign_in @admin
    get admin_intake_leads_path, params: { status: "reviewed" }
    assert_response :success
    assert_includes response.body, intake_leads(:reviewed).first_name
  end

  test "show renders" do
    sign_in @admin
    get admin_intake_lead_path(@lead)
    assert_response :success
  end

  test "edit renders" do
    sign_in @admin
    get edit_admin_intake_lead_path(@lead)
    assert_response :success
  end

  test "update persists changes" do
    sign_in @admin
    patch admin_intake_lead_path(@lead), params: {
      lead: { admin_notes: "Strong VIP candidate", status: "vip_prospect" }
    }
    @lead.reload
    assert_equal "Strong VIP candidate", @lead.admin_notes
    assert_equal "vip_prospect", @lead.status
  end
end
