# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_27_040438) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "intake_app_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "currently_paused", default: false, null: false
    t.string "global_mode", default: "ai", null: false
    t.text "paused_auto_reply"
    t.boolean "quiet_hours_enabled", default: false, null: false
    t.string "quiet_hours_timezone", default: "America/New_York", null: false
    t.datetime "updated_at", null: false
  end

  create_table "intake_chatbot_configs", force: :cascade do |t|
    t.integer "abandon_timeout_hours", default: 24, null: false
    t.string "anthropic_model", default: "claude-haiku-4-5-20251001", null: false
    t.string "bot_name", default: "AcmeBot Assistant"
    t.string "brand_name", default: "AcmeBot", null: false
    t.string "brand_tagline"
    t.text "completion_message"
    t.datetime "created_at", null: false
    t.text "custom_system_prompt_additions"
    t.text "error_fallback_reply", default: "Sorry, I'm having a brief technical hiccup right now. Please try sending your message again in a moment."
    t.text "followup_message"
    t.text "inappropriate_content_reply"
    t.jsonb "intake_questions", default: [], null: false
    t.integer "max_messages_per_5_min", default: 20, null: false
    t.text "media_received_reply"
    t.text "paused_reply"
    t.text "quiet_hours_reply"
    t.text "rate_limit_reply"
    t.text "returning_user_reply"
    t.boolean "send_followup_on_abandon", default: false, null: false
    t.jsonb "service_info", default: {}, null: false
    t.datetime "updated_at", null: false
    t.text "welcome_message"
  end

  create_table "intake_conversations", force: :cascade do |t|
    t.bigint "assigned_to_id"
    t.string "channel", default: "whatsapp", null: false
    t.datetime "created_at", null: false
    t.jsonb "extracted_data", default: {}, null: false
    t.boolean "intake_complete", default: false, null: false
    t.datetime "last_message_at"
    t.bigint "lead_id"
    t.string "mode", default: "ai", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.string "whatsapp_number", null: false
    t.index ["assigned_to_id"], name: "index_intake_conversations_on_assigned_to_id"
    t.index ["lead_id"], name: "index_intake_conversations_on_lead_id"
    t.index ["whatsapp_number", "status"], name: "index_intake_conversations_on_whatsapp_number_and_status"
    t.index ["whatsapp_number"], name: "index_intake_conversations_on_whatsapp_number"
  end

  create_table "intake_leads", force: :cascade do |t|
    t.text "about_me"
    t.text "admin_notes"
    t.integer "age"
    t.datetime "created_at", null: false
    t.text "deal_breakers"
    t.string "email"
    t.string "first_name"
    t.string "gender"
    t.bigint "intake_conversation_id"
    t.string "last_name"
    t.string "location_city"
    t.string "location_country"
    t.string "occupation"
    t.string "phone"
    t.jsonb "preferences", default: {}, null: false
    t.string "relationship_goal"
    t.string "religiosity_level"
    t.string "seeking_gender"
    t.string "source", default: "whatsapp", null: false
    t.string "status", default: "new", null: false
    t.jsonb "tags", default: [], null: false
    t.datetime "updated_at", null: false
    t.text "what_looking_for"
    t.index ["intake_conversation_id"], name: "index_intake_leads_on_intake_conversation_id"
    t.index ["phone"], name: "index_intake_leads_on_phone"
    t.index ["status"], name: "index_intake_leads_on_status"
  end

  create_table "intake_messages", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "intake_conversation_id", null: false
    t.string "media_url"
    t.string "message_type", default: "text", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.string "whatsapp_message_id"
    t.index ["intake_conversation_id"], name: "index_intake_messages_on_intake_conversation_id"
    t.index ["whatsapp_message_id"], name: "index_intake_messages_on_whatsapp_message_id", unique: true, where: "(whatsapp_message_id IS NOT NULL)"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "intake_conversations", "intake_leads", column: "lead_id"
  add_foreign_key "intake_conversations", "users", column: "assigned_to_id"
  add_foreign_key "intake_leads", "intake_conversations"
  add_foreign_key "intake_messages", "intake_conversations"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
end
