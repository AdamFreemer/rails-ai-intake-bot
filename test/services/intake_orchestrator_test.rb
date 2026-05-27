require "test_helper"

class IntakeOrchestratorTest < ActiveSupport::TestCase
  setup do
    @settings = intake_app_settings(:default)
    @config = intake_chatbot_configs(:default)
    @conversation = intake_conversations(:active_new)

    # Stub Twilio outbound by default
    stub_request(:post, %r{api\.twilio\.com})
      .to_return(status: 201, body: { sid: "SM_OUT" }.to_json, headers: { "Content-Type" => "application/json" })
  end

  test "AI mode: calls Anthropic, stores assistant reply, sends via Twilio" do
    stub_anthropic("Hi! What's your name?")

    @conversation.messages.create!(role: "user", content: "Hello", message_type: "text")

    assert_difference -> { @conversation.messages.where(role: "assistant").count }, 1 do
      IntakeOrchestrator.new(@conversation.reload).call
    end

    assert_requested :post, %r{api\.twilio\.com}
  end

  test "AI mode with intake completion: creates a lead and strips block before send" do
    canned = <<~MSG
      Thank you Sarah! 💕
      ---INTAKE_COMPLETE---
      FIRST_NAME: Sarah
      AGE: 28
      ---END_INTAKE---
    MSG
    stub_anthropic(canned)

    twilio_stub = stub_request(:post, %r{api\.twilio\.com})
      .with(body: hash_including("Body" => "Thank you Sarah! 💕"))
      .to_return(status: 201, body: { sid: "SM_OUT_STRIPPED" }.to_json)

    @conversation.messages.create!(role: "user", content: "I'm Sarah, 28, in Brooklyn", message_type: "text")
    IntakeOrchestrator.new(@conversation.reload).call

    assert_requested twilio_stub
    assert @conversation.reload.intake_complete
    assert_equal "completed", @conversation.status
    lead = @conversation.lead
    assert_equal "Sarah", lead.first_name
  end

  test "paused mode (global): sends paused_reply, no Anthropic call" do
    @settings.update!(global_mode: "paused", shabbat_mode_enabled: false)

    IntakeOrchestrator.new(@conversation).call

    assert_not_requested :post, "https://api.anthropic.com/v1/messages"
    assert_requested :post, %r{api\.twilio\.com},
      body: hash_including("Body" => @config.paused_reply)
  end

  test "Shabbat window: sends shabbat_reply, no Anthropic call" do
    @settings.update!(global_mode: "ai", shabbat_mode_enabled: true, shabbat_timezone: "America/New_York")

    travel_to Time.find_zone("America/New_York").parse("2026-05-22 18:00:00") do
      IntakeOrchestrator.new(@conversation).call
    end

    assert_not_requested :post, "https://api.anthropic.com/v1/messages"
    assert_requested :post, %r{api\.twilio\.com},
      body: hash_including("Body" => @config.shabbat_reply)
  end

  test "human mode: stores nothing outbound, no Twilio call" do
    @conversation.update!(mode: "human")

    IntakeOrchestrator.new(@conversation).call

    assert_not_requested :post, "https://api.anthropic.com/v1/messages"
    assert_not_requested :post, %r{api\.twilio\.com}
  end

  private

  def stub_anthropic(text)
    body = {
      id: "msg_test",
      type: "message",
      role: "assistant",
      content: [ { type: "text", text: text } ],
      model: "claude-haiku-4-5-20251001",
      stop_reason: "end_turn",
      usage: { input_tokens: 10, output_tokens: 8 }
    }
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end
end
