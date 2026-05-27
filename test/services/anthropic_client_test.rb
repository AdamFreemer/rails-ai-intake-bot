require "test_helper"

class AnthropicClientTest < ActiveSupport::TestCase
  setup do
    @stub_response = {
      id: "msg_test",
      type: "message",
      role: "assistant",
      content: [ { type: "text", text: "Welcome to AcmeBot! 💕" } ],
      model: "claude-haiku-4-5-20251001",
      stop_reason: "end_turn",
      stop_sequence: nil,
      usage: { input_tokens: 10, output_tokens: 8 }
    }
  end

  test "returns assistant reply text on success" do
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(status: 200, body: @stub_response.to_json, headers: { "Content-Type" => "application/json" })

    reply = AnthropicClient.chat(
      system: "You are a matchmaker assistant.",
      messages: [ { role: "user", content: "Hi" } ]
    )

    assert_equal "Welcome to AcmeBot! 💕", reply
  end
end
