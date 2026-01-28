# WAHA WhatsApp Integration for Chatwoot

This guide explains how to use the WAHA (WhatsApp HTTP API) channel that has been added to Chatwoot.

## What Was Implemented

### Backend Components

1. **Model**: `app/models/channel/waha.rb`
   - Handles WAHA channel configuration
   - Manages phone number, API URL, API key, and session name
   - Provides methods to send messages via WAHA API

2. **Migration**: `db/migrate/20260128160954_create_channel_waha.rb`
   - Creates `channel_waha` table with necessary fields

3. **Webhook Controller**: `app/controllers/webhooks/waha_controller.rb`
   - Receives incoming message webhooks from WAHA
   - Validates API key and queues processing job

4. **Webhook Job**: `app/jobs/webhooks/waha_events_job.rb`
   - Processes incoming WAHA webhooks asynchronously
   - Filters out outgoing and group messages

5. **Incoming Message Service**: `app/services/waha/incoming_message_service.rb`
   - Creates/updates contacts in Chatwoot
   - Creates conversations
   - Processes incoming messages and attachments

6. **Outgoing Message Service**: `app/services/waha/send_on_waha_service.rb`
   - Sends agent replies from Chatwoot to WhatsApp via WAHA
   - Handles text messages and media attachments

7. **API Controller**: `app/controllers/api/v1/accounts/channels/waha_channels_controller.rb`
   - REST API for creating and managing WAHA channels
   - Validates WAHA connection before creating channel

8. **Routes**: Updated `config/routes.rb`
   - Added webhook endpoint: `POST /webhooks/waha`
   - Added API endpoints: `POST /api/v1/accounts/:account_id/channels/waha_channels`

9. **Send Reply Integration**: Updated `app/jobs/send_reply_job.rb`
   - Registered WAHA channel in the send reply routing

## Setup Instructions

### 1. Run Database Migration

```bash
cd /Users/macbook/Documents/Valvest/Development/chatwoot-source
bundle install
bundle exec rails db:migrate
```

### 2. Configure WAHA Server

Ensure your WAHA server is running and accessible. You'll need:
- WAHA API URL (e.g., `https://waha.yourdomain.com`)
- WAHA API Key
- Session name (default: "default")
- Phone number associated with the WAHA session

### 3. Create WAHA Channel via API

```bash
curl -X POST "https://your-chatwoot.com/api/v1/accounts/{account_id}/channels/waha_channels" \
  -H "api_access_token: YOUR_CHATWOOT_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "waha_channel": {
      "name": "WhatsApp Business",
      "phone_number": "1234567890",
      "waha_api_url": "https://waha.yourdomain.com",
      "waha_api_key": "your-waha-api-key",
      "session_name": "default"
    }
  }'
```

The response will include the `webhook_url` you need to configure in WAHA.

### 4. Configure WAHA Webhooks

In your WAHA server, configure the webhook to send events to:

```
https://your-chatwoot.com/webhooks/waha
```

**Important**: Make sure WAHA sends the `X-Api-Key` header with the same API key you configured in the channel.

#### Example WAHA Webhook Configuration

```bash
curl -X POST "https://waha.yourdomain.com/api/default/webhooks" \
  -H "X-Api-Key: your-waha-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://your-chatwoot.com/webhooks/waha",
    "events": ["message"],
    "hmac": null,
    "retries": null,
    "customHeaders": [
      {
        "name": "X-Api-Key",
        "value": "your-waha-api-key"
      }
    ]
  }'
```

## How It Works

### Incoming Messages Flow

1. Customer sends message via WhatsApp
2. WAHA receives message and sends webhook to Chatwoot
3. `Webhooks::WahaController` validates API key and queues job
4. `Webhooks::WahaEventsJob` processes the webhook
5. `Waha::IncomingMessageService` creates/updates contact, conversation, and message
6. Message appears in Chatwoot inbox

### Outgoing Messages Flow

1. Agent replies in Chatwoot
2. `SendReplyJob` routes message to `Waha::SendOnWahaService`
3. Service sends message to WAHA API
4. WAHA sends message via WhatsApp
5. Message status is updated in Chatwoot

## Message Format

### WAHA Webhook Payload

```json
{
  "event": "message",
  "session": "default",
  "payload": {
    "id": "true_1234567890@s.whatsapp.net_ABCDEF",
    "timestamp": "2024-01-28T10:00:00.000Z",
    "from": "1234567890@s.whatsapp.net",
    "fromMe": false,
    "body": "Hello from customer",
    "hasMedia": false,
    "type": "chat"
  }
}
```

## Troubleshooting

### Messages showing "401 not authorized"

This was the original problem you had with the API channel approach. With this native WAHA channel integration, messages should now appear correctly because:

1. Messages are properly associated with the WAHA channel
2. Contact and conversation creation is handled correctly
3. Message direction (incoming/outgoing) is properly set

### Webhook not being received

- Verify WAHA webhook URL is correctly configured
- Check that `X-Api-Key` header matches the channel's `waha_api_key`
- Check Chatwoot logs: `tail -f log/development.log`

### Messages not sending

- Verify WAHA API URL and key are correct
- Check that WAHA session is active
- Review Chatwoot logs for error messages

## Building and Deploying

### Build Docker Image

```bash
cd /Users/macbook/Documents/Valvest/Development/chatwoot-source
docker build -t your-registry/chatwoot-waha:latest .
docker push your-registry/chatwoot-waha:latest
```

### Update Your Deployment

Update your existing Chatwoot deployment repository to use the new custom image:

```dockerfile
# In /Users/macbook/Documents/Valvest/Development/chatwoot/Dockerfile
FROM your-registry/chatwoot-waha:latest
```

## Next Steps

1. **Test the Integration**: Create a test channel and send/receive messages
2. **UI Components**: Add frontend components for easier channel management (currently API-only)
3. **Media Support**: Test image, video, and document attachments
4. **Templates**: Add support for WhatsApp message templates if needed

## Differences from API Channel

Your previous setup using the API channel had limitations:

- ❌ Messages showed as "401 not authorized"
- ❌ Required manual syncing via your backend API
- ❌ Wasn't a "native" integration

With this WAHA channel:

- ✅ Messages appear correctly in inbox
- ✅ Real-time message syncing via webhooks
- ✅ Native channel type in Chatwoot
- ✅ Proper contact and conversation management
- ✅ Agent replies work seamlessly

## Support

If you encounter issues:

1. Check Chatwoot logs: `bundle exec rails logs:tail`
2. Check WAHA logs
3. Verify webhook configuration
4. Test API connection to WAHA

