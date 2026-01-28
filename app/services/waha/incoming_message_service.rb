class Waha::IncomingMessageService
  pattr_initialize [:inbox!, :params!]

  def perform
    return unless message_payload.present?
    return if message_payload['fromMe']

    ActiveRecord::Base.transaction do
      set_contact
      return unless @contact

      set_conversation
      create_message
    end
  end

  private

  def message_payload
    @message_payload ||= params['payload']
  end

  def phone_number
    @phone_number ||= begin
      # Extract phone number from WAHA format: "1234567890@s.whatsapp.net"
      from = message_payload['from']
      from.split('@').first if from.present?
    end
  end

  def set_contact
    return if phone_number.blank?

    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: phone_number,
      inbox: inbox,
      contact_attributes: {
        name: message_payload['notifyName'] || phone_number,
        phone_number: "+#{phone_number}"
      }
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def set_conversation
    # If lock to single conversation is disabled, we will create a new conversation if previous conversation is resolved
    @conversation = if @inbox.lock_to_single_conversation
                      @contact_inbox.conversations.last
                    else
                      @contact_inbox.conversations.where.not(status: :resolved).last
                    end
    return if @conversation

    @conversation = ::Conversation.create!(
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id
    )
  end

  def create_message
    content = message_content

    @message = @conversation.messages.create!(
      content: content,
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: message_payload['id'].to_s
    )

    attach_files if message_payload['hasMedia']
  end

  def message_content
    body = message_payload['body']

    # Handle different message types
    case message_payload['type']
    when 'chat'
      body || ''
    when 'image', 'video', 'audio', 'document'
      message_payload['caption'] || '[Media message]'
    when 'location'
      location = message_payload['location']
      "📍 Location: #{location['latitude']}, #{location['longitude']}" if location
    else
      '[Unsupported message type]'
    end
  end

  def attach_files
    return unless message_payload['hasMedia']

    # WAHA provides media info in the payload
    media_data = message_payload.dig('_data', 'media') || message_payload['media']
    return if media_data.blank?

    begin
      # Download the media file from WAHA
      channel = @inbox.channel
      media_url = "#{channel.waha_api_url}/api/files/#{message_payload['id']}"

      file = download_media_file(media_url, channel.waha_api_key)
      return if file.blank?

      @message.attachments.new(
        account_id: @message.account_id,
        file_type: determine_file_type,
        file: {
          io: file,
          filename: file.original_filename,
          content_type: file.content_type
        }
      )
      @message.save!
    rescue StandardError => e
      Rails.logger.error "Failed to attach WAHA media: #{e.message}"
    end
  end

  def download_media_file(url, api_key)
    response = HTTParty.get(
      url,
      headers: { 'X-Api-Key' => api_key }
    )

    return nil unless response.success?

    file = Tempfile.new(['waha', File.extname(url)])
    file.binmode
    file.write(response.body)
    file.rewind

    # Add metadata to file
    file.define_singleton_method(:original_filename) { File.basename(url) }
    file.define_singleton_method(:content_type) { response.headers['content-type'] || 'application/octet-stream' }

    file
  end

  def determine_file_type
    case message_payload['type']
    when 'image'
      :image
    when 'video'
      :video
    when 'audio'
      :audio
    else
      :file
    end
  end
end
