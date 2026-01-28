class Webhooks::WahaEventsJob < ApplicationJob
  queue_as :low

  def perform(params = {}, inbox_id = nil)
    return if params.blank?

    @inbox = Inbox.find_by(id: inbox_id)
    return unless @inbox

    # WAHA webhook format:
    # {
    #   "event": "message",
    #   "session": "default",
    #   "payload": {
    #     "id": "...",
    #     "timestamp": "...",
    #     "from": "1234567890@s.whatsapp.net",
    #     "fromMe": false,
    #     "body": "Hello",
    #     "hasMedia": false,
    #     ...
    #   }
    # }

    return unless params['event'] == 'message'

    payload = params['payload']
    return if payload.blank?

    # Skip messages sent by us
    return if payload['fromMe']

    # Skip group messages if needed
    return if payload['from']&.include?('@g.us')

    # Process the incoming message
    Waha::IncomingMessageService.new(inbox: @inbox, params: params).perform
  end
end
