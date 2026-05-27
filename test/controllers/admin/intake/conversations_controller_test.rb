require "test_helper"

class Admin::Intake::ConversationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:admin)
    @customer = users(:customer)
    @conversation = intake_conversations(:active_new)
  end

  test "non-admin redirected" do
    sign_in @customer
    get admin_intake_conversations_path
    assert_redirected_to root_path
  end

  test "admin sees index" do
    sign_in @admin
    get admin_intake_conversations_path
    assert_response :success
  end

  test "index filters by status" do
    sign_in @admin
    get admin_intake_conversations_path, params: { status: "completed" }
    assert_response :success
    assert_includes response.body, intake_conversations(:completed).whatsapp_number[-4..]
    assert_not_includes response.body, "+15551234567" # active_new
  end

  test "index filters by mode" do
    sign_in @admin
    get admin_intake_conversations_path, params: { mode: "human" }
    assert_response :success
    assert_includes response.body, intake_conversations(:active_human).whatsapp_number[-4..]
  end

  test "search matches phone number substring" do
    sign_in @admin
    get admin_intake_conversations_path, params: { q: "1234567" }
    assert_response :success
    assert_includes response.body, intake_conversations(:active_new).whatsapp_number[-4..]
    assert_not_includes response.body, intake_conversations(:active_human).whatsapp_number[-4..]
  end

  test "search matches message content" do
    sign_in @admin
    @conversation.messages.create!(role: "user", content: "Found this through a friend in Brooklyn", message_type: "text")
    get admin_intake_conversations_path, params: { q: "brooklyn" }
    assert_response :success
    assert_includes response.body, @conversation.whatsapp_number[-4..]
  end

  test "search matches linked lead first/last name" do
    sign_in @admin
    lead = intake_leads(:sarah)
    intake_conversations(:active_new).update!(lead: lead)
    get admin_intake_conversations_path, params: { q: "cohen" }
    assert_response :success
    assert_includes response.body, intake_conversations(:active_new).whatsapp_number[-4..]
  end

  test "search returns each matching conversation exactly once" do
    sign_in @admin
    convo = intake_conversations(:active_new)
    3.times { |i| convo.messages.create!(role: "user", content: "needle text #{i}", message_type: "text") }
    get admin_intake_conversations_path, params: { q: "needle" }
    assert_response :success
    # phone displayed once in the row; check that the row isn't duplicated
    masked_phone = convo.whatsapp_number[-4..]
    assert_equal 1, response.body.scan(masked_phone).count
  end

  test "sort by phone ascending orders rows by whatsapp_number ASC" do
    sign_in @admin
    get admin_intake_conversations_path, params: { sort: "phone", dir: "asc" }
    assert_response :success

    phones_in_order = Intake::Conversation.order(:whatsapp_number).pluck(:whatsapp_number)
    body = response.body
    positions = phones_in_order.map { |p| body.index(p[-4..]) }.compact
    assert_equal positions, positions.sort,
                 "rows should appear in the same order as `ORDER BY whatsapp_number ASC`"
  end

  test "sort by phone descending reverses order" do
    sign_in @admin
    get admin_intake_conversations_path, params: { sort: "phone", dir: "desc" }
    assert_response :success

    phones_in_order = Intake::Conversation.order(whatsapp_number: :desc).pluck(:whatsapp_number)
    body = response.body
    positions = phones_in_order.map { |p| body.index(p[-4..]) }.compact
    assert_equal positions, positions.sort,
                 "rows should appear in the same order as `ORDER BY whatsapp_number DESC`"
  end

  test "unknown sort column falls back to default order without erroring" do
    sign_in @admin
    get admin_intake_conversations_path, params: { sort: "drop_table; DROP", dir: "asc" }
    assert_response :success
  end

  test "show renders the chat thread" do
    sign_in @admin
    get admin_intake_conversation_path(@conversation)
    assert_response :success
  end

  test "take_over flips to human and assigns" do
    sign_in @admin
    post take_over_admin_intake_conversation_path(@conversation)
    assert_redirected_to admin_intake_conversation_path(@conversation)
    @conversation.reload
    assert_equal "human", @conversation.mode
    assert_equal @admin, @conversation.assigned_to
  end

  test "release flips back to AI" do
    sign_in @admin
    @conversation.update!(mode: "human", assigned_to: @admin)
    post release_admin_intake_conversation_path(@conversation)
    @conversation.reload
    assert_equal "ai", @conversation.mode
    assert_nil @conversation.assigned_to
  end

  test "mark_complete sets status" do
    sign_in @admin
    post mark_complete_admin_intake_conversation_path(@conversation)
    @conversation.reload
    assert_equal "completed", @conversation.status
    assert @conversation.intake_complete
  end

  test "mark_abandoned sets status" do
    sign_in @admin
    post mark_abandoned_admin_intake_conversation_path(@conversation)
    @conversation.reload
    assert_equal "abandoned", @conversation.status
  end
end
