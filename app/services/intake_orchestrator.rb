class IntakeOrchestrator
  # Routes an inbound user message to the right handler based on global mode,
  # quiet hours window, and per-conversation mode. Persists assistant replies and
  # sends them out via Twilio. Returns the assistant message (if any).
  def initialize(conversation)
    @conversation = conversation
    @settings = Intake::AppSetting.current
    @config = Intake::ChatbotConfig.current
  end

  def call
    case determine_mode
    when :paused then handle_paused
    when :human  then handle_human
    when :ai     then handle_ai
    end
  end

  private

  def determine_mode
    return :paused if @settings.global_mode == "paused"
    return :paused if @settings.quiet_hours_enabled && QuietHoursWindow.active?(@settings.quiet_hours_timezone)
    return :human if @conversation.human_mode?
    :ai
  end

  def handle_paused
    reply = paused_reply_text
    persist_assistant(reply)
    deliver(reply)
    reply
  end

  def handle_human
    # Human takeover: just store the inbound; admin replies via the dashboard.
    # No outbound reply from this path.
    nil
  end

  def handle_ai
    history = @conversation.messages.chronological.map { |m| { role: m.role, content: m.content } }
    raw_reply = AnthropicClient.chat(
      system: SystemPromptBuilder.build(@config),
      messages: history,
      model: @config.anthropic_model.presence
    )

    extraction = LeadExtractor.new(@conversation).extract!(raw_reply)
    user_facing = extraction.stripped_content.presence || raw_reply

    # Persist the user-facing (stripped) version so the admin chat thread shows
    # what the WhatsApp user actually saw — not the raw Anthropic response with
    # the ephemeral ---INTAKE_COMPLETE--- parser block. The structured fields
    # already live on conversation.extracted_data + the lead, and render as a
    # styled summary card at the end of the thread.
    persist_assistant(user_facing)
    deliver(user_facing)
    user_facing
  rescue StandardError => e
    handle_ai_failure(e)
  end

  # Whenever the AI call (or downstream send) fails, the user just sees the
  # bot fall silent. Send a friendly fallback so they know to retry. Also
  # persist it so the admin can see what the user saw.
  def handle_ai_failure(error)
    Rails.logger.error("[IntakeOrchestrator] AI handling failed: #{error.class}: #{error.message}")
    fallback = @config.error_fallback_reply.presence ||
               "Sorry, I'm having a brief technical hiccup. Please try sending that again in a moment. 💕"
    persist_assistant(fallback)
    deliver(fallback) rescue nil
    fallback
  end

  def paused_reply_text
    if @settings.quiet_hours_enabled && QuietHoursWindow.active?(@settings.quiet_hours_timezone)
      @config.quiet_hours_reply.presence || @settings.paused_auto_reply.presence || "We're currently offline for Quiet Hours."
    else
      @config.paused_reply.presence || @settings.paused_auto_reply.presence || "We're currently offline."
    end
  end

  def persist_assistant(content)
    @conversation.messages.create!(role: "assistant", content: content, message_type: "text")
  end

  def deliver(body)
    WhatsappSender.send_message(to: @conversation.whatsapp_number, body: body)
  end
end
