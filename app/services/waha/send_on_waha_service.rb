class Waha::SendOnWahaService < Base::SendOnChannelService
  private

  def channel_class
    Channel::Waha
  end

  def perform_reply
    # Send text or media message based on attachments
    if message.attachments.present?
      send_message_with_attachments
    else
      send_text_message
    end
  end

  def send_text_message
    source_id = message.conversation.contact_inbox.source_id
    message_id = channel.send_message(source_id, message)

    if message_id.present?
      message.update!(source_id: message_id, status: :sent)
    else
      message.update!(status: :failed, external_error: 'Failed to send message via WAHA')
    end
  rescue StandardError => e
    Rails.logger.error "WAHA send error: #{e.message}"
    message.update!(status: :failed, external_error: e.message)
  end

  def send_message_with_attachments
    source_id = message.conversation.contact_inbox.source_id

    # Send each attachment
    message.attachments.each do |attachment|
      send_attachment(source_id, attachment)
    end

    # Send text if there's content along with attachments
    send_text_message if message.content.present?
  end

  def send_attachment(source_id, attachment)
    # Get the public URL for the attachment
    media_url = attachment.download_url

    message_id = channel.send_media_message(source_id, media_url, message.content)

    if message_id.present?
      message.update!(source_id: message_id, status: :sent)
    else
      message.update!(status: :failed, external_error: 'Failed to send media via WAHA')
    end
  rescue StandardError => e
    Rails.logger.error "WAHA media send error: #{e.message}"
    message.update!(status: :failed, external_error: e.message)
  end
end
