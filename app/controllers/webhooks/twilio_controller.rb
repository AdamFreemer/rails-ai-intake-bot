module Webhooks
  class TwilioController < ApplicationController
    # Twilio posts form-encoded data and signs the request with the
    # account's auth_token. We verify the signature before doing any work.
    skip_before_action :verify_authenticity_token
    before_action :verify_twilio_signature

    def whatsapp
      ProcessIntakeMessageJob.perform_later(
        phone: normalized_phone,
        body: params[:Body].to_s,
        message_sid: params[:MessageSid],
        num_media: params[:NumMedia].to_i,
        media_url: params[:MediaUrl0]
      )

      head :ok
    end

    private

    def normalized_phone
      params[:From].to_s.sub(/\Awhatsapp:/, "")
    end

    def verify_twilio_signature
      return if Rails.env.test? && request.headers["X-Skip-Twilio-Validation"] == "true"

      auth_token = Rails.application.credentials.dig(:twilio, :auth_token)
      return head :forbidden if auth_token.blank?

      validator = Twilio::Security::RequestValidator.new(auth_token)
      signature = request.headers["X-Twilio-Signature"].to_s
      url = request.original_url
      ok = validator.validate(url, request.POST, signature)

      head :forbidden unless ok
    end
  end
end
