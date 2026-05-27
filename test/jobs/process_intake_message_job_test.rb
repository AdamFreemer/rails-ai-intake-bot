require "test_helper"

class ProcessIntakeMessageJobTest < ActiveJob::TestCase
  setup do
    @phone = "+15551234599"

    # Default stubs — opt-in tests can override
    stub_request(:post, %r{api\.twilio\.com})
      .to_return(status: 201, body: { sid: "SM_OUT" }.to_json,
                 headers: { "Content-Type" => "application/json" })
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(status: 200,
                 body: { content: [ { type: "text", text: "Hi!" } ] }.to_json,
                 headers: { "Content-Type" => "application/json" })
  end

  test "creates a conversation, stores the inbound, and dispatches orchestrator" do
    assert_difference "Intake::Conversation.count", 1 do
      assert_difference "Intake::Message.count", 2 do # user + assistant
        perform_enqueued_jobs do
          ProcessIntakeMessageJob.perform_later(
            phone: @phone,
            body: "Hi",
            message_sid: "SM_TEST_IN_1",
            num_media: 0
          )
        end
      end
    end

    convo = Intake::Conversation.find_by(whatsapp_number: @phone)
    assert convo, "conversation should be created"
    inbound = convo.messages.where(role: "user").first
    assert_equal "Hi", inbound.content
    assert_equal "SM_TEST_IN_1", inbound.whatsapp_message_id
  end

  test "is idempotent on duplicate MessageSid" do
    perform_enqueued_jobs do
      ProcessIntakeMessageJob.perform_later(phone: @phone, body: "Hi", message_sid: "SM_DUP", num_media: 0)
      ProcessIntakeMessageJob.perform_later(phone: @phone, body: "Hi", message_sid: "SM_DUP", num_media: 0)
    end

    convo = Intake::Conversation.find_by(whatsapp_number: @phone)
    assert_equal 1, convo.messages.where(role: "user").count
  end

  test "stores image message when num_media > 0" do
    perform_enqueued_jobs do
      ProcessIntakeMessageJob.perform_later(
        phone: @phone,
        body: "",
        message_sid: "SM_MEDIA_1",
        num_media: 1,
        media_url: "https://example.com/img.jpg"
      )
    end

    convo = Intake::Conversation.find_by(whatsapp_number: @phone)
    inbound = convo.messages.where(role: "user").first
    assert_equal "image", inbound.message_type
    assert_equal "https://example.com/img.jpg", inbound.media_url
  end
end
