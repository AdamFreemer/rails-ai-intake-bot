class WhatsappSender
  def self.send_message(to:, body:)
    new.send_message(to: to, body: body)
  end

  def initialize
    creds = Rails.application.credentials.twilio
    raise "Missing Rails.application.credentials.twilio" if creds.blank?
    @from = creds[:whatsapp_number]
    raise "Missing twilio.whatsapp_number credential" if @from.blank?
    @client = Twilio::REST::Client.new(creds[:account_sid], creds[:auth_token])
  end

  def send_message(to:, body:)
    to_address = to.to_s.start_with?("whatsapp:") ? to : "whatsapp:#{to}"
    @client.messages.create(from: @from, to: to_address, body: body)
  end
end
