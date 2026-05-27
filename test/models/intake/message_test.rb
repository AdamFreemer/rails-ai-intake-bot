require "test_helper"

class Intake::MessageTest < ActiveSupport::TestCase
  setup do
    @conversation = intake_conversations(:active_new)
  end

  test "requires content" do
    msg = @conversation.messages.build(role: "user", content: "")
    assert_not msg.valid?
  end

  test "requires valid role" do
    msg = @conversation.messages.build(role: "wizard", content: "Hi")
    assert_not msg.valid?
  end

  test "whatsapp_message_id must be unique when present" do
    @conversation.messages.create!(role: "user", content: "Hi", whatsapp_message_id: "SM_UNIQ_1")
    dup = @conversation.messages.build(role: "user", content: "Hey", whatsapp_message_id: "SM_UNIQ_1")
    assert_not dup.valid?
  end

  test "nil whatsapp_message_id is allowed for multiple messages" do
    m1 = @conversation.messages.create!(role: "assistant", content: "A")
    m2 = @conversation.messages.create!(role: "assistant", content: "B")
    assert_nil m1.whatsapp_message_id
    assert_nil m2.whatsapp_message_id
  end

  test "updates conversation last_message_at on create" do
    travel_to Time.zone.parse("2026-05-23 10:00:00") do
      @conversation.messages.create!(role: "user", content: "New")
      assert_equal Time.zone.parse("2026-05-23 10:00:00"), @conversation.reload.last_message_at
    end
  end

  test "chronological scope orders oldest first" do
    @conversation.messages.destroy_all
    old = @conversation.messages.create!(role: "user", content: "Old", created_at: 2.hours.ago)
    new_msg = @conversation.messages.create!(role: "assistant", content: "New", created_at: 1.minute.ago)
    ordered = @conversation.messages.chronological
    assert_equal old, ordered.first
    assert_equal new_msg, ordered.last
  end
end
