require "test_helper"

class ShabbatWindowTest < ActiveSupport::TestCase
  TZ = "America/New_York"

  test "active on Friday evening after 4pm" do
    travel_to Time.find_zone(TZ).parse("2026-05-22 18:00:00") do
      assert ShabbatWindow.active?(TZ)
    end
  end

  test "inactive on Friday morning" do
    travel_to Time.find_zone(TZ).parse("2026-05-22 09:00:00") do
      assert_not ShabbatWindow.active?(TZ)
    end
  end

  test "active on Saturday afternoon" do
    travel_to Time.find_zone(TZ).parse("2026-05-23 14:00:00") do
      assert ShabbatWindow.active?(TZ)
    end
  end

  test "inactive on Saturday night after 9pm" do
    travel_to Time.find_zone(TZ).parse("2026-05-23 22:00:00") do
      assert_not ShabbatWindow.active?(TZ)
    end
  end

  test "inactive on Sunday" do
    travel_to Time.find_zone(TZ).parse("2026-05-24 12:00:00") do
      assert_not ShabbatWindow.active?(TZ)
    end
  end

  test "falls back to America/New_York on unknown timezone" do
    travel_to Time.find_zone(TZ).parse("2026-05-22 18:00:00") do
      assert ShabbatWindow.active?("Atlantis/Lost")
    end
  end
end
