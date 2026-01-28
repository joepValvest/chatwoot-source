# == Schema Information
#
# Table name: channel_waha
#
#  id              :bigint           not null, primary key
#  phone_number    :string           not null
#  waha_api_url    :string           not null
#  waha_api_key    :string           not null
#  session_name    :string           default("default")
#  provider_config :jsonb
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :integer          not null
#
# Indexes
#
#  index_channel_waha_on_phone_number  (phone_number) UNIQUE
#

class Channel::Waha < ApplicationRecord
  include Channelable

  self.table_name = 'channel_waha'
  EDITABLE_ATTRS = [:phone_number, :waha_api_url, :waha_api_key, :session_name, { provider_config: {} }].freeze

  validates :phone_number, presence: true, uniqueness: true
  validates :waha_api_url, presence: true
  validates :waha_api_key, presence: true
  validates :session_name, presence: true

  before_save :ensure_valid_phone_number

  def name
    "WhatsApp (WAHA): #{phone_number}"
  end

  def messaging_window_enabled?
    true
  end

  # Send text message via WAHA
  def send_message(source_id, message)
    chat_id = "#{source_id}@s.whatsapp.net"

    response = HTTParty.post(
      "#{waha_api_url}/api/sendText",
      headers: {
        'X-Api-Key' => waha_api_key,
        'Content-Type' => 'application/json'
      },
      body: {
        session: session_name,
        chatId: chat_id,
        text: message.content
      }.to_json
    )

    if response.success?
      response.parsed_response['id']
    else
      Rails.logger.error "WAHA send message failed: #{response.body}"
      nil
    end
  end

  # Send media message via WAHA
  def send_media_message(source_id, media_url, caption = nil)
    chat_id = "#{source_id}@s.whatsapp.net"

    response = HTTParty.post(
      "#{waha_api_url}/api/sendImage",
      headers: {
        'X-Api-Key' => waha_api_key,
        'Content-Type' => 'application/json'
      },
      body: {
        session: session_name,
        chatId: chat_id,
        file: {
          url: media_url
        },
        caption: caption
      }.to_json
    )

    if response.success?
      response.parsed_response['id']
    else
      Rails.logger.error "WAHA send media failed: #{response.body}"
      nil
    end
  end

  private

  def ensure_valid_phone_number
    self.phone_number = phone_number.gsub(/\D/, '')
  end
end
