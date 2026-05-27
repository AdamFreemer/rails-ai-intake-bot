# Dev-only demo data for the admin dashboard.
# Run with:  bin/rails runner db/seeds/dev_demo.rb
#
# Wipes and re-creates ~20 Intake::Conversation rows with varied phone numbers,
# message threads, and lead profiles so the typeahead search + filters have
# real material to bite into. Safe to re-run anytime in development.

unless Rails.env.development? || ENV["ALLOW_DEMO_SEED"] == "true"
  abort "Refusing to seed demo data outside development. Set ALLOW_DEMO_SEED=true to force (e.g. on a showcase production deploy)."
end

puts "Wiping existing Intake data…"
# Order matters — Intake::Lead has a FK to Intake::Conversation, AND
# Intake::Conversation has a FK to Intake::Lead. Null out the back-ref
# from conversations first, then it's safe to drop leads and conversations.
Intake::Conversation.update_all(lead_id: nil)
Intake::Lead.destroy_all
Intake::Conversation.destroy_all

# ---- Active AI intakes, at various stages ---------------------------------

active_specs = [
  { phone: "+15551234567", first: "Emma",     ago: 4.minutes,  msg: "Hi! I found you on Instagram", reply: "Hi Emma! 💕 Welcome to BlindFate. Where are you based?" },
  { phone: "+15552345678", first: "Olivia",   ago: 12.minutes, msg: "Just started looking for a matchmaker, can I learn more?", reply: "Of course! What city are you in?" },
  { phone: "+15553456789", first: "Noah",     ago: 1.hour,     msg: "Hello, my friend Naomi recommended you", reply: "So lovely — give Naomi our regards! What's your first name?" },
  { phone: "+15554567890", first: "Ava",      ago: 2.hours,    msg: "I'm 31, in Chicago, looking for marriage", reply: "Thank you Ava! Are you Modern Orthodox, Conservative, or another denomination?" },
  { phone: "+15555678901", first: "Liam",     ago: 3.hours,    msg: "Saw the Forward article and wanted to reach out", reply: "Welcome! Tell me a bit about yourself — what's your name and age?" },
  { phone: "+15556789012", first: "Sophia",   ago: 5.hours,    msg: "Are you accepting new clients in the LA area?", reply: "Yes! LA is a great region for us. Tell me your name and a bit about what you're looking for." },
  { phone: "+15557890123", first: "Benjamin", ago: 8.hours,    msg: "Hi — I'm 35, divorced, Modern Orthodox, in Teaneck", reply: "Welcome Benjamin. Are you looking for a serious relationship or marriage specifically?" }
]

active_specs.each do |spec|
  c = Intake::Conversation.create!(
    whatsapp_number: spec[:phone],
    mode: "ai", status: "active", channel: "whatsapp",
    last_message_at: spec[:ago].ago
  )
  c.messages.create!(role: "user", content: spec[:msg], message_type: "text", created_at: (spec[:ago] + 30.seconds).ago)
  c.messages.create!(role: "assistant", content: spec[:reply], message_type: "text", created_at: spec[:ago].ago,
                     whatsapp_message_id: "DEMO_ACTIVE_#{spec[:phone][-4..]}")
end

# ---- Human takeover ----------------------------------------------------------

human_specs = [
  { phone: "+15559876543", note: "VIP prospect — Rivkah taking over",
    user: "I'd really like to speak with Rivkah directly please. I've been a fan for years.",
    reply: "Of course — let me get Rivkah for you." },
  { phone: "+15558765432", note: "Sensitive — recently widowed",
    user: "Hi, this is a difficult question. I'm recently widowed and unsure if I'm ready.",
    reply: "Thank you for trusting us. Let me bring Rivkah in — she handles this kind of conversation personally." }
]

human_specs.each do |spec|
  c = Intake::Conversation.create!(
    whatsapp_number: spec[:phone],
    mode: "human", status: "active", channel: "whatsapp",
    last_message_at: 15.minutes.ago
  )
  c.messages.create!(role: "user", content: spec[:user], message_type: "text", created_at: 20.minutes.ago)
  c.messages.create!(role: "assistant", content: spec[:reply], message_type: "text",
                     created_at: 15.minutes.ago, whatsapp_message_id: "DEMO_HUMAN_#{spec[:phone][-4..]}")
end

# ---- Completed intakes with extracted leads ---------------------------------

completed_specs = [
  { first: "Sarah",   last: "Cohen",   phone: "+15555550100", age: 28, gender: "female", seeking: "male",
    city: "Brooklyn",     country: "USA",    religiosity: "Modern Orthodox", goal: "marriage",
    about: "Software engineer who loves hiking. Family is everything.",
    looking: "Someone kind, ambitious, and family-oriented",
    deal: "Smoking", status: "new", ago: 30.minutes },
  { first: "Daniel",  last: "Levin",   phone: "+15555550101", age: 32, gender: "male", seeking: "female",
    city: "Tel Aviv",     country: "Israel", religiosity: "Traditional",     goal: "serious relationship",
    about: "Doctor, runs marathons, three siblings",
    looking: "Smart, warm, ambitious partner",
    deal: nil, status: "reviewed", ago: 2.hours },
  { first: "Maya",    last: "Goldberg", phone: "+15555550102", age: 26, gender: "female", seeking: "male",
    city: "Boston",       country: "USA",    religiosity: "Conservative",    goal: "marriage",
    about: "PhD student in psychology, plays cello, runs an Instagram book club.",
    looking: "Curious, well-read, emotionally available",
    deal: "Drugs", status: "vip_prospect", ago: 4.hours },
  { first: "Jacob",   last: "Friedman", phone: "+15555550103", age: 38, gender: "male", seeking: "female",
    city: "Toronto",      country: "Canada", religiosity: "Modern Orthodox", goal: "marriage",
    about: "Attorney, divorced, two kids (10 and 7), very involved father.",
    looking: "Patient, warm, OK with blended family",
    deal: "Not open to step-parenting", status: "accepted", ago: 8.hours },
  { first: "Tova",    last: "Rosen",    phone: "+15555550104", age: 24, gender: "female", seeking: "male",
    city: "Jerusalem",    country: "Israel", religiosity: "Orthodox",        goal: "marriage",
    about: "Just finished seminary, teaches preschool, very close with family.",
    looking: "Learning, kind, mensch",
    deal: nil, status: "new", ago: 1.day },
  { first: "Ezra",    last: "Katz",     phone: "+15555550105", age: 29, gender: "male", seeking: "female",
    city: "London",       country: "UK",     religiosity: "Modern Orthodox", goal: "marriage",
    about: "Tech founder, plays rugby, family in both London and NY.",
    looking: "Ambitious, fun, traditional but open-minded",
    deal: "Doesn't want kids", status: "new", ago: 1.day },
  { first: "Hannah",  last: "Bernstein", phone: "+15555550106", age: 34, gender: "female", seeking: "male",
    city: "Miami",        country: "USA",    religiosity: "Traditional",     goal: "serious relationship",
    about: "Marketing director, divorced, no kids, three nieces I adore.",
    looking: "Settled, kind, ready for a real partnership",
    deal: "Heavy drinking", status: "reviewed", ago: 2.days },
  { first: "Adam",    last: "Schwartz", phone: "+15555550107", age: 41, gender: "male", seeking: "female",
    city: "Philadelphia", country: "USA",    religiosity: "Conservative",    goal: "marriage",
    about: "Pediatrician, widower, one teenager. Sailing on weekends.",
    looking: "Compassionate, comfortable around teens, independent",
    deal: nil, status: "vip_prospect", ago: 3.days }
]

completed_specs.each do |spec|
  c = Intake::Conversation.create!(
    whatsapp_number: spec[:phone],
    mode: "ai", status: "completed", channel: "whatsapp",
    intake_complete: true,
    last_message_at: spec[:ago].ago,
    extracted_data: { "FIRST_NAME" => spec[:first], "AGE" => spec[:age].to_s, "LOCATION_CITY" => spec[:city] }
  )
  c.messages.create!(role: "user", content: "I'm #{spec[:first]}, #{spec[:age]}, in #{spec[:city]}",
                     message_type: "text", created_at: (spec[:ago] + 5.minutes).ago)
  c.messages.create!(role: "assistant",
                     content: "Thank you #{spec[:first]}! 💕 Welcome to the BlindFate family!",
                     message_type: "text", created_at: spec[:ago].ago,
                     whatsapp_message_id: "DEMO_DONE_#{spec[:phone][-4..]}")

  lead = Intake::Lead.create!(
    intake_conversation_id: c.id,
    first_name: spec[:first], last_name: spec[:last], phone: spec[:phone],
    age: spec[:age], gender: spec[:gender], seeking_gender: spec[:seeking],
    location_city: spec[:city], location_country: spec[:country],
    religiosity_level: spec[:religiosity], relationship_goal: spec[:goal],
    about_me: spec[:about], what_looking_for: spec[:looking],
    deal_breakers: spec[:deal], status: spec[:status], source: "whatsapp"
  )
  c.update!(lead: lead)
end

# ---- Abandoned -------------------------------------------------------------

abandoned_specs = [
  { phone: "+15554440001", user: "Hello", ago: 4.days },
  { phone: "+15554440002", user: "What does this cost?", ago: 6.days }
]

abandoned_specs.each do |spec|
  c = Intake::Conversation.create!(
    whatsapp_number: spec[:phone],
    mode: "ai", status: "abandoned", channel: "whatsapp",
    last_message_at: spec[:ago].ago
  )
  c.messages.create!(role: "user", content: spec[:user], message_type: "text",
                     created_at: (spec[:ago] + 1.minute).ago)
  c.messages.create!(role: "assistant",
                     content: "Hi! 💕 What's your first name?",
                     message_type: "text", created_at: spec[:ago].ago,
                     whatsapp_message_id: "DEMO_ABAN_#{spec[:phone][-4..]}")
end

# ---- Edge-case leads (layout stress tests) ---------------------------------

# Hebrew name + Hebrew message content. Tests RTL handling, font support,
# table truncation behavior.
hebrew_convo = Intake::Conversation.create!(
  whatsapp_number: "+972541234567",
  mode: "ai", status: "completed", channel: "whatsapp",
  intake_complete: true,
  last_message_at: 6.hours.ago
)
hebrew_convo.messages.create!(role: "user",
  content: "שלום! שמי שרה לוי, אני בת 29 וגרה בירושלים. מחפשת חתן רציני.",
  message_type: "text", created_at: 7.hours.ago)
hebrew_convo.messages.create!(role: "assistant",
  content: "שלום שרה! 💕 ברוכה הבאה ל-BlindFate. אשמח לעזור לך.",
  message_type: "text", created_at: 6.hours.ago,
  whatsapp_message_id: "DEMO_HEB_001")
hebrew_lead = Intake::Lead.create!(
  intake_conversation_id: hebrew_convo.id,
  first_name: "שרה", last_name: "לוי", phone: "+972541234567",
  age: 29, gender: "female", seeking_gender: "male",
  location_city: "ירושלים", location_country: "Israel",
  religiosity_level: "Orthodox", relationship_goal: "marriage",
  about_me: "מורה לאנגלית, אוהבת לטייל ולקרוא ספרים",
  what_looking_for: "בן זוג רציני, בעל לב טוב, מחויב למשפחה",
  source: "whatsapp", status: "new"
)
hebrew_convo.update!(lead: hebrew_lead)

# Very long name — tests table cell truncation
Intake::Lead.create!(
  first_name: "Christopher Bartholomew", last_name: "Featherstonehaugh-Vandenberg",
  phone: "+15556660003", age: 39, gender: "male", seeking_gender: "female",
  location_city: "San Francisco", location_country: "USA",
  religiosity_level: "Reform", relationship_goal: "marriage",
  about_me: "Investment banker, sailing, three older brothers all in finance",
  what_looking_for: "Independent, ambitious, comfortable in upscale circles",
  source: "airtable_import", status: "vip_prospect"
)

# Multi-paragraph message — tests message bubble height + scroll behavior
multi_para_convo = Intake::Conversation.create!(
  whatsapp_number: "+15554440003",
  mode: "ai", status: "active", channel: "whatsapp",
  last_message_at: 20.minutes.ago
)
multi_para_convo.messages.create!(role: "user",
  content: <<~MSG.strip,
    Hi! I wasn't sure where to start so I'll just lay it all out.

    I'm 34, divorced two years ago after a 9-year marriage. No kids. I'm a
    therapist in private practice, work from home most days, very close with
    my parents (we light Quiet Hours candles together every Friday).

    What I'm looking for is someone emotionally available. I've been on every
    app and the conversations are exhausting. A real conversation with
    Rivkah feels like the right next step.

    I should mention — I keep kosher but I'm not Orthodox. Looking for someone
    similar in observance level. Open to relocating to Israel within a year or
    two if the right match makes that make sense.

    Thank you for reading all of this. 💕
  MSG
  message_type: "text", created_at: 25.minutes.ago)
multi_para_convo.messages.create!(role: "assistant",
  content: "Thank you for sharing all of that — it really helps me understand what you're looking for. What's your first name, and where are you currently based?",
  message_type: "text", created_at: 20.minutes.ago,
  whatsapp_message_id: "DEMO_LONG_001")

# ---- Standalone leads (imported, no live conversation) ---------------------

Intake::Lead.create!(
  first_name: "Rebecca", last_name: "Solomon", phone: "+15556660001",
  age: 30, gender: "female", seeking_gender: "male",
  location_city: "Westchester", location_country: "USA",
  religiosity_level: "Modern Orthodox", relationship_goal: "marriage",
  about_me: "Architect, plays piano, big traveler",
  what_looking_for: "Established, family-focused, sense of humor",
  source: "airtable_import", status: "reviewed"
)

Intake::Lead.create!(
  first_name: "Joshua", last_name: "Mizrahi", phone: "+15556660002",
  age: 36, gender: "male", seeking_gender: "female",
  location_city: "Aventura", location_country: "USA",
  religiosity_level: "Traditional", relationship_goal: "marriage",
  about_me: "Family business owner, three brothers, very close with parents",
  what_looking_for: "Warm, grounded, wants family",
  source: "airtable_import", status: "vip_prospect"
)

puts "Done. Conversations: #{Intake::Conversation.count}.  Leads: #{Intake::Lead.count}."
puts "  Active: #{Intake::Conversation.where(status: 'active').count}  " \
     "Completed: #{Intake::Conversation.where(status: 'completed').count}  " \
     "Abandoned: #{Intake::Conversation.where(status: 'abandoned').count}"
puts "  Human takeover: #{Intake::Conversation.where(mode: 'human').count}"
