namespace :intake do
  desc "Wipe all Intake::Conversation and Intake::Lead rows. Preserves ChatbotConfig + AppSetting."
  task wipe_conversations: :environment do
    if Rails.env.production? && ENV["CONFIRM"] != "match-app"
      abort <<~MSG.chomp

        Refusing to wipe in production without confirmation.
        Re-run with:

          heroku run rake intake:wipe_conversations CONFIRM=match-app -a match-app

      MSG
    end

    convo_count = Intake::Conversation.count
    lead_count  = Intake::Lead.count
    msg_count   = Intake::Message.count

    # Null out the FK from conversations -> leads first, then it's safe
    # to drop leads and conversations in any order.
    Intake::Conversation.update_all(lead_id: nil)
    Intake::Lead.destroy_all
    Intake::Conversation.destroy_all

    puts "Wiped #{convo_count} conversations, #{msg_count} messages, #{lead_count} leads."
    puts "Intake::ChatbotConfig + Intake::AppSetting preserved."
  end
end
