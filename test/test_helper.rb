ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

WebMock.disable_net_connect!(allow_localhost: true)

# Inject deterministic credentials for services under test. Outbound HTTP is
# blocked by WebMock except when explicitly stubbed.
Rails.application.credentials[:anthropic] = { api_key: "sk-ant-test-key" }
Rails.application.credentials[:twilio] = {
  account_sid: "AC_test_sid",
  auth_token:  "test_auth_token",
  whatsapp_number: "whatsapp:+14155238886"
}

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    fixtures :all

    # Resolve namespaced models from flat fixture filenames
    set_fixture_class "intake/conversations":   "Intake::Conversation",
                      "intake/messages":        "Intake::Message",
                      "intake/leads":           "Intake::Lead",
                      "intake/chatbot_configs": "Intake::ChatbotConfig",
                      "intake/app_settings":    "Intake::AppSetting"
  end
end
