require "test_helper"

class LeadExtractorTest < ActiveSupport::TestCase
  setup do
    @conversation = intake_conversations(:active_new)
  end

  test "returns the original content untouched when no intake block" do
    result = LeadExtractor.new(@conversation).extract!("Just a normal message.")
    assert_nil result.lead
    assert_equal "Just a normal message.", result.stripped_content
  end

  test "creates a lead and marks conversation complete on full block" do
    content = <<~MSG
      Thank you so much! 💕 Welcome to AcmeBot.
      ---INTAKE_COMPLETE---
      FIRST_NAME: Sarah
      AGE: 28
      GENDER: Female
      SEEKING_GENDER: Male
      LOCATION_CITY: Brooklyn
      LOCATION_COUNTRY: USA
      RELIGIOSITY: Modern Orthodox
      RELATIONSHIP_GOAL: Marriage
      ABOUT: Software engineer
      LOOKING_FOR: Someone kind
      DEAL_BREAKERS: Smoking
      SOURCE: Instagram
      ---END_INTAKE---
    MSG

    result = LeadExtractor.new(@conversation).extract!(content)

    assert result.lead.persisted?
    assert_equal "Sarah", result.lead.first_name
    assert_equal 28, result.lead.age
    assert_equal "Brooklyn", result.lead.location_city
    assert_equal "whatsapp", result.lead.source
    assert_equal "new", result.lead.status
    assert_equal @conversation, result.lead.conversation

    @conversation.reload
    assert @conversation.intake_complete
    assert_equal "completed", @conversation.status
    assert_equal result.lead, @conversation.lead
    assert_equal "Sarah", @conversation.extracted_data["FIRST_NAME"]
  end

  test "strips the intake block from user-facing content" do
    content = "Thanks Sarah! 💕\n---INTAKE_COMPLETE---\nFIRST_NAME: Sarah\n---END_INTAKE---"
    result = LeadExtractor.new(@conversation).extract!(content)
    assert_equal "Thanks Sarah! 💕", result.stripped_content
    refute_includes result.stripped_content, "INTAKE_COMPLETE"
  end

  test "strip_block class helper removes markers cleanly" do
    stripped = LeadExtractor.strip_block("Hi!\n---INTAKE_COMPLETE---\nFOO: bar\n---END_INTAKE---\n")
    assert_equal "Hi!", stripped
  end
end
