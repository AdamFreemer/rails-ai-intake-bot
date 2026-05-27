require "test_helper"

class SystemPromptBuilderTest < ActiveSupport::TestCase
  setup do
    @config = intake_chatbot_configs(:default)
  end

  test "includes brand name" do
    prompt = SystemPromptBuilder.build(@config)
    assert_includes prompt, "AcmeBot"
  end

  test "includes tagline when present" do
    prompt = SystemPromptBuilder.build(@config)
    assert_includes prompt, "AI intake bot for service businesses"
  end

  test "includes welcome and completion messages" do
    prompt = SystemPromptBuilder.build(@config)
    assert_includes prompt, @config.welcome_message
    assert_includes prompt, @config.completion_message
  end

  test "includes the INTAKE_COMPLETE marker instructions" do
    prompt = SystemPromptBuilder.build(@config)
    assert_includes prompt, "---INTAKE_COMPLETE---"
    assert_includes prompt, "---END_INTAKE---"
  end

  test "uses configured intake_questions when present" do
    @config.intake_questions = [
      { "field" => "first_name", "question" => "What's your first name?", "active" => true, "order" => 1 },
      { "field" => "favorite_color", "question" => "What's your favorite color?", "active" => true, "order" => 2 }
    ]
    prompt = SystemPromptBuilder.build(@config)
    assert_includes prompt, "What's your favorite color?"
  end

  test "falls back to defaults when intake_questions is empty" do
    @config.intake_questions = []
    prompt = SystemPromptBuilder.build(@config)
    assert_includes prompt, "Name"
    assert_includes prompt, "Religious background"
  end

  test "renders service_info entries" do
    prompt = SystemPromptBuilder.build(@config)
    assert_includes prompt, "$195"
  end
end
