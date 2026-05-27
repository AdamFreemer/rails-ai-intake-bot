require "test_helper"

class Admin::Intake::MessagesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:admin)
    @conversation = intake_conversations(:active_human)
    stub_request(:post, %r{api\.twilio\.com})
      .to_return(status: 201, body: { sid: "SM_ADMIN_OUT" }.to_json,
                 headers: { "Content-Type" => "application/json" })
  end

  test "admin reply creates an assistant message and sends via Twilio" do
    sign_in @admin

    assert_difference "@conversation.messages.where(role: 'assistant').count", 1 do
      post admin_intake_conversation_messages_path(@conversation),
           params: { message: { content: "Hi, it's the admin team! I saw your message." } }
    end

    assert_redirected_to admin_intake_conversation_path(@conversation)
    assert_requested :post, %r{api\.twilio\.com},
      body: hash_including("Body" => "Hi, it's the admin team! I saw your message.")
  end

  test "blank message is rejected" do
    sign_in @admin
    post admin_intake_conversation_messages_path(@conversation), params: { message: { content: "   " } }
    assert_redirected_to admin_intake_conversation_path(@conversation)
    assert_not_requested :post, %r{api\.twilio\.com}
  end
end
