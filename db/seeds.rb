# Bootstrap an admin user + default chatbot config so the app is usable
# the moment you've migrated.

User.find_or_create_by!(email: "admin@example.com") do |u|
  u.password = "password123"
  u.admin = true
end

Intake::AppSetting.first_or_create! do |s|
  s.global_mode = "ai"
  s.shabbat_mode_enabled = false
  s.shabbat_timezone = "America/New_York"
  s.currently_paused = false
  s.paused_auto_reply = "Thanks for reaching out! We're currently offline and will get back to you soon."
end

# The default ChatbotConfig is set up with a generic service-business intake.
# Edit it via /admin/intake/chatbot_config (super admin only), or adjust this
# seed and re-run for your domain.
Intake::ChatbotConfig.first_or_create! do |c|
  c.brand_name = "AcmeBot"
  c.brand_tagline = "AI intake bot for service businesses"
  c.anthropic_model = "claude-haiku-4-5-20251001"
  c.bot_name = "AcmeBot Assistant"
  c.welcome_message = "Hi there! 👋 Welcome. I'd love to learn a little about you so we can connect you with the right person. Feel free to say \"skip\" to any question you'd rather not answer right now. Ready to get started?"
  c.completion_message = "Thank you so much for sharing! 🙏 Someone from our team will personally review your information and reach out shortly. Welcome aboard!"
  c.paused_reply = "Thanks for reaching out! We're currently offline and will get back to you soon."
  c.shabbat_reply = "Thanks for reaching out! We're currently observing Shabbat and will be back Saturday evening."
  c.media_received_reply = "Thanks for that! For now I work best with text messages — could you type that out for me?"
  c.rate_limit_reply = "You're sending messages a bit fast! Give me a moment to catch up."
  c.error_fallback_reply = "Sorry, I'm having a brief technical hiccup right now. Please try sending your message again in a moment."
  c.max_messages_per_5_min = 20
  c.abandon_timeout_hours = 24
  c.send_followup_on_abandon = false
  c.intake_questions = [
    { "field" => "name",          "question" => "What's your name?",                                                                "required" => true,  "active" => true, "order" => 1 },
    { "field" => "age",           "question" => "How old are you?",                                                                  "required" => true,  "active" => true, "order" => 2 },
    { "field" => "gender",        "question" => "Are you a man or a woman, and are you looking for a man or a woman?",               "required" => true,  "active" => true, "order" => 3 },
    { "field" => "location",      "question" => "Where are you based? (city and country)",                                            "required" => true,  "active" => true, "order" => 4 },
    { "field" => "background",    "question" => "Tell me a bit about your background and values.",                                    "required" => true,  "active" => true, "order" => 5 },
    { "field" => "services",      "question" => "Which of our services are you interested in? (matchmaking, coaching, or database)", "required" => true,  "active" => true, "order" => 6 },
    { "field" => "goal",          "question" => "What are you looking for? (long-term, casual, exploring, etc.)",                    "required" => true,  "active" => true, "order" => 7 },
    { "field" => "about_me",      "question" => "Tell me a bit about yourself!",                                                      "required" => true,  "active" => true, "order" => 8 },
    { "field" => "looking_for",   "question" => "What are you looking for in a partner / fit?",                                       "required" => true,  "active" => true, "order" => 9 },
    { "field" => "deal_breakers", "question" => "Any deal-breakers?",                                                                 "required" => false, "active" => true, "order" => 10 },
    { "field" => "source",        "question" => "How did you hear about us?",                                                         "required" => false, "active" => true, "order" => 11 }
  ]
  c.service_info = {
    "consultation_price" => "$195",
    "vip_description"    => "VIP Private Client — by application only",
    "database_size"      => "4,000+",
    "success_metric"     => "Nearly 50 successful matches"
  }
end

puts "Seeded admin user (admin@example.com / password123) + AcmeBot defaults."
