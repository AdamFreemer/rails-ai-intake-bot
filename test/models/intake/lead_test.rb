require "test_helper"

class Intake::LeadTest < ActiveSupport::TestCase
  setup do
    @sarah = intake_leads(:sarah)
    @reviewed = intake_leads(:reviewed)
  end

  test "rejects invalid status" do
    @sarah.status = "ghosted"
    assert_not @sarah.valid?
  end

  test "by_status scope filters" do
    assert_includes Intake::Lead.by_status("new"), @sarah
    assert_not_includes Intake::Lead.by_status("new"), @reviewed
  end

  test "search matches first_name case-insensitively" do
    assert_includes Intake::Lead.search("sar"), @sarah
    assert_not_includes Intake::Lead.search("sar"), @reviewed
  end

  test "search matches about_me" do
    assert_includes Intake::Lead.search("software"), @sarah
  end

  test "search with blank query returns all" do
    assert_equal Intake::Lead.count, Intake::Lead.search(nil).count
  end

  test "full_name returns combined name" do
    assert_equal "Sarah Cohen", @sarah.full_name
  end

  test "full_name is nil when no name present" do
    @sarah.first_name = nil
    @sarah.last_name = nil
    assert_nil @sarah.full_name
  end
end
