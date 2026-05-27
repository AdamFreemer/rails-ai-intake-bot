require "test_helper"

class WhatsappSenderTest < ActiveSupport::TestCase
  test "POSTs to Twilio messages endpoint with normalized to: address" do
    stub_request(:post, %r{api\.twilio\.com/2010-04-01/Accounts/AC_test_sid/Messages\.json})
      .with(body: hash_including(
        "From" => "whatsapp:+14155238886",
        "To" => "whatsapp:+15551234567",
        "Body" => "Hello!"
      ))
      .to_return(status: 201, body: { sid: "SM_TEST_OUT" }.to_json, headers: { "Content-Type" => "application/json" })

    WhatsappSender.send_message(to: "+15551234567", body: "Hello!")
    assert_requested :post, %r{api\.twilio\.com}
  end

  test "preserves existing whatsapp: prefix on to: argument" do
    stub_request(:post, %r{api\.twilio\.com})
      .with(body: hash_including("To" => "whatsapp:+15559876543"))
      .to_return(status: 201, body: { sid: "SM_TEST_OUT2" }.to_json)

    WhatsappSender.send_message(to: "whatsapp:+15559876543", body: "Hi")
    assert_requested :post, %r{api\.twilio\.com}
  end
end
