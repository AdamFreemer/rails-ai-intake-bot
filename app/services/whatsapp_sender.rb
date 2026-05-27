class WhatsappSender
  def self.send_message(to:, body:)
    new.send_message(to: to, body: body)
  end

  def initialize
    creds = Rails.application.credentials.twilio || {}
    @from = ENV["TWILIO_WHATSAPP_NUMBER"].presence || creds[:whatsapp_number]
    sid   = ENV["TWILIO_ACCOUNT_SID"].presence    || creds[:account_sid]
    token = ENV["TWILIO_AUTH_TOKEN"].presence     || creds[:auth_token]

    raise "Missing TWILIO_WHATSAPP_NUMBER" if @from.blank?
    raise "Missing TWILIO_ACCOUNT_SID"    if sid.blank?
    raise "Missing TWILIO_AUTH_TOKEN"     if token.blank?

    @client = Twilio::REST::Client.new(sid, token)
  end

  def send_message(to:, body:)
    to_address = to.to_s.start_with?("whatsapp:") ? to : "whatsapp:#{to}"
    @client.messages.create(from: @from, to: to_address, body: body)
  end
end
