class QuietHoursWindow
  # MVP: fixed Friday 4pm -> Saturday 9pm in the configured timezone.
  # Phase 3+ can swap in a zmanim API for sunset-accurate times.
  def self.active?(timezone)
    tz = ActiveSupport::TimeZone[timezone] || ActiveSupport::TimeZone["America/New_York"]
    now = Time.current.in_time_zone(tz)

    return true if now.friday? && now.hour >= 16
    return true if now.saturday? && now.hour < 21
    false
  end
end
