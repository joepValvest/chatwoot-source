class Api::V1::Accounts::Channels::WahaChannelsController < Api::V1::Accounts::BaseController
  before_action :authorize_request

  def create
    process_create
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  def update
    @waha_channel = Current.account.channel_waha.find(params[:id])
    @waha_channel.update!(permitted_params)
    render json: { inbox: @waha_channel.inbox }, status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def authorize_request
    authorize ::Inbox
  end

  def process_create
    ActiveRecord::Base.transaction do
      validate_waha_connection
      build_inbox
    end
  end

  def validate_waha_connection
    # Test connection to WAHA API
    response = HTTParty.get(
      "#{permitted_params[:waha_api_url]}/api/sessions",
      headers: { 'X-Api-Key' => permitted_params[:waha_api_key] }
    )

    unless response.success?
      raise "Failed to connect to WAHA API: #{response.code} - #{response.body}"
    end
  end

  def build_inbox
    @waha_channel = Current.account.channel_waha.create!(
      phone_number: permitted_params[:phone_number],
      waha_api_url: permitted_params[:waha_api_url],
      waha_api_key: permitted_params[:waha_api_key],
      session_name: permitted_params[:session_name] || 'default'
    )

    @inbox = Current.account.inboxes.create!(
      name: permitted_params[:name] || "WAHA: #{permitted_params[:phone_number]}",
      channel: @waha_channel
    )

    render json: {
      inbox: @inbox,
      webhook_url: webhook_url
    }, status: :ok
  end

  def webhook_url
    "#{ENV.fetch('FRONTEND_URL', nil)}/webhooks/waha"
  end

  def permitted_params
    params.require(:waha_channel).permit(
      :phone_number,
      :waha_api_url,
      :waha_api_key,
      :session_name,
      :name
    )
  end
end
