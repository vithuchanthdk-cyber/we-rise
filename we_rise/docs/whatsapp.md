# WhatsApp Intake Architecture (WE RISE)

To include residents who do not have smartphones or prefer messaging, WE RISE supports a WhatsApp intake channel.

## Demo Mode
- **No external network calls** are made in Demo Mode.
- Moderators can use the in-app **WhatsApp Intake Simulator** (`WhatsAppSimulatorScreen`) to test English and Tamil messages (`WhatsAppParser.parseToComplaint`).
- Every ingested message starts as `PENDING_REVIEW` and never goes public until a moderator approves it.

## Production Mode (Supabase Edge Function)
1. Configure a WhatsApp Business Cloud API webhook (free developer tier) pointing to a Supabase Edge Function (`whatsapp_webhook`).
2. The Edge Function:
   - Hashes the sender phone number into an anonymous `sender_token` (never stores raw phone numbers in public tables).
   - Extracts ward and category hints (English / Tamil).
   - Inserts a `complaints` row with `status = 'pending_review'` and `on_behalf_of = 'WhatsApp intake'`.
   - Replies to the user via WhatsApp with their `WR-CHE-YYYY-NNNNNN` tracking ID.
