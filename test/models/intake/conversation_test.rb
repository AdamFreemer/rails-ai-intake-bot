require "test_helper"

class Intake::ConversationTest < ActiveSupport::TestCase
  setup do
    @active = intake_conversations(:active_new)
    @completed = intake_conversations(:completed)
  end

  test "requires a whatsapp_number" do
    convo = Intake::Conversation.new(mode: "ai", status: "active", channel: "whatsapp")
    assert_not convo.valid?
    assert_includes convo.errors[:whatsapp_number], "can't be blank"
  end

  test "rejects invalid mode" do
    @active.mode = "telepathy"
    assert_not @active.valid?
  end

  test "rejects invalid status" do
    @active.status = "schrodinger"
    assert_not @active.valid?
  end

  test "active scope excludes completed" do
    assert_includes Intake::Conversation.active, @active
    assert_not_includes Intake::Conversation.active, @completed
  end

  test "find_or_create_for_number returns active conversation" do
    found = Intake::Conversation.find_or_create_for_number(@active.whatsapp_number)
    assert_equal @active, found
  end

  test "find_or_create_for_number creates new when no active exists" do
    assert_difference "Intake::Conversation.count", 1 do
      created = Intake::Conversation.find_or_create_for_number("+15550000999")
      assert created.persisted?
      assert_equal "active", created.status
      assert_equal "ai", created.mode
    end
  end

  test "find_or_create_for_number creates new conversation for returning user with completed intake" do
    assert_difference "Intake::Conversation.count", 1 do
      Intake::Conversation.find_or_create_for_number(@completed.whatsapp_number)
    end
  end

  test "mode helpers" do
    @active.mode = "ai"
    assert @active.ai_mode?
    @active.mode = "human"
    assert @active.human_mode?
    @active.mode = "paused"
    assert @active.paused_mode?
  end
end
