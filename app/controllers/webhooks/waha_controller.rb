class Webhooks::WahaController < ActionController::API
  skip_before_action :verify_authenticity_token

  def process_payload
    # Verify API key from header
    api_key = request.headers['X-Api-Key']
    channel = Channel::Waha.find_by(waha_api_key: api_key)

    if channel.blank?
      Rails.logger.warn("Rejected WAHA webhook: Invalid API key")
      render json: { error: 'Unauthorized' }, status: :unauthorized
      return
    end

    # Process the webhook asynchronously
    Webhooks::WahaEventsJob.perform_later(params.to_unsafe_hash, channel.inbox.id)
    head :ok
  end
end
