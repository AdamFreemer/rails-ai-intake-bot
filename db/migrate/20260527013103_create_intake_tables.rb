class CreateIntakeTables < ActiveRecord::Migration[8.1]
  def change
    create_table :intake_conversations do |t|
      t.string :whatsapp_number, null: false
      t.string :channel, default: "whatsapp", null: false
      t.string :mode, default: "ai", null: false
      t.string :status, default: "active", null: false
      t.references :assigned_to, foreign_key: { to_table: :users }, null: true
      t.bigint :lead_id
      t.jsonb :extracted_data, default: {}, null: false
      t.boolean :intake_complete, default: false, null: false
      t.datetime :last_message_at
      t.timestamps
    end
    add_index :intake_conversations, :whatsapp_number
    add_index :intake_conversations, [ :whatsapp_number, :status ]

    create_table :intake_messages do |t|
      t.references :intake_conversation, null: false, foreign_key: true
      t.string :role, null: false
      t.text :content, null: false
      t.string :message_type, default: "text", null: false
      t.string :whatsapp_message_id
      t.string :media_url
      t.timestamps
    end
    add_index :intake_messages, :whatsapp_message_id, unique: true, where: "whatsapp_message_id IS NOT NULL"

    create_table :intake_leads do |t|
      t.references :intake_conversation, foreign_key: true, null: true
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone
      t.integer :age
      t.string :gender
      t.string :seeking_gender
      t.string :location_city
      t.string :location_country
      t.string :religiosity_level
      t.string :relationship_goal
      t.string :occupation
      t.text :about_me
      t.text :what_looking_for
      t.text :deal_breakers
      t.jsonb :preferences, default: {}, null: false
      t.jsonb :tags, default: [], null: false
      t.string :source, default: "whatsapp", null: false
      t.string :status, default: "new", null: false
      t.text :admin_notes
      t.timestamps
    end
    add_index :intake_leads, :phone
    add_index :intake_leads, :status
    add_index :intake_conversations, :lead_id
    add_foreign_key :intake_conversations, :intake_leads, column: :lead_id

    create_table :intake_chatbot_configs do |t|
      t.string :brand_name, default: "AcmeBot", null: false
      t.string :brand_tagline
      t.string :anthropic_model, default: "claude-haiku-4-5-20251001", null: false
      t.string :bot_name, default: "AcmeBot Assistant"
      t.text :welcome_message
      t.text :completion_message
      t.text :custom_system_prompt_additions
      t.jsonb :intake_questions, default: [], null: false
      t.jsonb :service_info, default: {}, null: false
      t.text :paused_reply
      t.text :shabbat_reply
      t.text :returning_user_reply
      t.text :media_received_reply
      t.text :inappropriate_content_reply
      t.text :rate_limit_reply
      t.integer :max_messages_per_5_min, default: 20, null: false
      t.integer :abandon_timeout_hours, default: 24, null: false
      t.boolean :send_followup_on_abandon, default: false, null: false
      t.text :followup_message
      t.text :error_fallback_reply,
             default: "Sorry, I'm having a brief technical hiccup right now. Please try sending your message again in a moment."
      t.timestamps
    end

    create_table :intake_app_settings do |t|
      t.string :global_mode, default: "ai", null: false
      t.boolean :shabbat_mode_enabled, default: false, null: false
      t.string :shabbat_timezone, default: "America/New_York", null: false
      t.boolean :currently_paused, default: false, null: false
      t.text :paused_auto_reply
      t.timestamps
    end
  end
end
