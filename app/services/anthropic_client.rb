class AnthropicClient
  DEFAULT_MODEL = "claude-haiku-4-5-20251001".freeze
  DEFAULT_MAX_TOKENS = 1024

  # Returns the assistant's reply text. Raises on hard failures so the
  # ProcessIntakeMessageJob can retry via Solid Queue.
  def self.chat(system:, messages:, model: nil, max_tokens: nil)
    new.chat(system: system, messages: messages, model: model, max_tokens: max_tokens)
  end

  def initialize
    api_key = Rails.application.credentials.dig(:anthropic, :api_key)
    raise "Missing Rails.application.credentials.anthropic.api_key" if api_key.blank?
    @client = Anthropic::Client.new(api_key: api_key)
  end

  def chat(system:, messages:, model: nil, max_tokens: nil)
    response = @client.messages.create(
      model: model || DEFAULT_MODEL,
      max_tokens: max_tokens || DEFAULT_MAX_TOKENS,
      system: system,
      messages: messages
    )

    # The SDK returns a Message object with a `content` array of blocks.
    text_block = response.content.find { |b| b.type == :text || b.type == "text" }
    text_block&.text.to_s
  end
end
