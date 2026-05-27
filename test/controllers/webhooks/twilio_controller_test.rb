require "test_helper"

class Webhooks::TwilioControllerTest < ActionDispatch::IntegrationTest
  test "POST whatsapp returns 200 and enqueues a job (skip-signature header in test)" do
    assert_enqueued_with(job: ProcessIntakeMessageJob) do
      post "/webhooks/twilio/whatsapp",
           params: {
             From: "whatsapp:+15551234567",
             Body: "Hello",
             MessageSid: "SM_WEBHOOK_1",
             NumMedia: "0"
           },
           headers: { "X-Skip-Twilio-Validation" => "true" }
    end

    assert_response :success
  end

  test "POST whatsapp rejects requests with bad signature" do
    post "/webhooks/twilio/whatsapp",
         params: { From: "whatsapp:+1", Body: "Hi", MessageSid: "SM_SIG_BAD" },
         headers: { "X-Twilio-Signature" => "totally-wrong" }

    assert_response :forbidden
  end
end
