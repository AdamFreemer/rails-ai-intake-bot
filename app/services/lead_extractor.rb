class LeadExtractor
  INTAKE_PATTERN = /---INTAKE_COMPLETE---(.*?)---END_INTAKE---/m.freeze

  Result = Struct.new(:lead, :stripped_content, keyword_init: true)

  def initialize(conversation)
    @conversation = conversation
  end

  # Returns a Result with the (possibly created) Intake::Lead and the
  # message text stripped of the intake block (safe to send to the user).
  def extract!(content)
    match = content.match(INTAKE_PATTERN)
    return Result.new(lead: nil, stripped_content: content) unless match

    parsed = parse_block(match[1])
    lead = build_or_update_lead(parsed)

    @conversation.update!(
      extracted_data: parsed,
      intake_complete: true,
      status: "completed",
      lead: lead
    )

    Result.new(lead: lead, stripped_content: strip_block(content))
  end

  def self.strip_block(content)
    content.gsub(INTAKE_PATTERN, "").strip
  end

  private

  def parse_block(block)
    block.strip.split("\n").each_with_object({}) do |line, hash|
      key, value = line.split(":", 2)
      next if key.blank?
      hash[key.strip] = value&.strip
    end
  end

  def build_or_update_lead(parsed)
    phone = @conversation.whatsapp_number
    lead = Intake::Lead.find_or_initialize_by(phone: phone)
    lead.assign_attributes(
      first_name: parsed["FIRST_NAME"],
      last_name: parsed["LAST_NAME"],
      age: parsed["AGE"]&.to_i,
      gender: parsed["GENDER"],
      seeking_gender: parsed["SEEKING_GENDER"],
      location_city: parsed["LOCATION_CITY"],
      location_country: parsed["LOCATION_COUNTRY"],
      religiosity_level: parsed["RELIGIOSITY"],
      relationship_goal: parsed["RELATIONSHIP_GOAL"],
      about_me: parsed["ABOUT"],
      what_looking_for: parsed["LOOKING_FOR"],
      deal_breakers: parsed["DEAL_BREAKERS"],
      preferences: {
        "raw_source" => parsed["SOURCE"],
        "services"   => parsed["SERVICES"]
      },
      source: "whatsapp",
      status: "new",
      conversation: @conversation
    )
    lead.save!
    lead
  end

  def strip_block(content)
    self.class.strip_block(content)
  end
end
