# AcmeBot — AI WhatsApp Intake Bot in Rails 8 + Hotwire

A production-grade reference implementation of an AI-powered intake chatbot
that runs natively inside WhatsApp, parses conversations into structured
leads, and surfaces them in a real-time admin dashboard.

Built with **Rails 8.1 / Hotwire / Solid Queue / Anthropic Claude / Twilio**.
Extracted from a real production app — every pattern here ships in a
working SaaS.

## Why this exists

Service businesses — matchmakers, consultants, real-estate agents, lawyers,
fitness studios — get most of their leads via WhatsApp DMs and spend hours a
day on triage. This project does that triage automatically:

- Inbound WhatsApp message → Twilio webhook → Solid Queue job
- Claude Haiku conducts a natural conversation following a configurable
  intake script
- A structured `Intake::Lead` row is extracted and persisted, with
  service-tier priority (matchmaking → "High Priority" pink pill in admin)
- Admin dashboard shows conversations in real time, lets the human take
  over from the AI at any point, hands back to AI when done

## Architecture at a glance

```
       WhatsApp user
            │
            ▼  inbound message
     Twilio (WA Business)
            │
            ▼  POST + HMAC signature
  Webhooks::TwilioController
            │
            ▼  enqueue
  ProcessIntakeMessageJob   ──►  Solid Queue (Postgres-backed)
            │
            ▼
   IntakeOrchestrator
   ├── mode = paused?  → send paused_reply
   ├── shabbat window? → send shabbat_reply
   ├── mode = human?   → store inbound only (admin replies via dashboard)
   └── mode = ai:
        ├── AnthropicClient → Claude Haiku
        │     (system prompt built from Intake::ChatbotConfig)
        ├── LeadExtractor   → parse ---INTAKE_COMPLETE--- block
        │                     → create / update Intake::Lead
        └── WhatsappSender  → reply via Twilio REST
            │
            ▼  Turbo Streams broadcast
   Admin live updates (chat thread + summary card + sidebar)
```

## What's in the box

### Models (`app/models/intake/`)

| Model | Purpose |
|---|---|
| `Intake::Conversation` | One thread per phone number. Tracks mode (`ai`/`paused`/`human`), status, intake completion. |
| `Intake::Message` | Each inbound/outbound message. Idempotent on `whatsapp_message_id`. |
| `Intake::Lead` | Structured profile data extracted from the conversation. |
| `Intake::ChatbotConfig` | Singleton — brand name, system-prompt overrides, intake question list, auto-reply text. |
| `Intake::AppSetting` | Singleton — global pause toggle, Shabbat config. |

### Services (`app/services/`)

| Service | Responsibility |
|---|---|
| `AnthropicClient` | Thin wrapper over the official `anthropic` gem. |
| `WhatsappSender` | Twilio REST outbound. |
| `IntakeOrchestrator` | Mode routing + the call/persist/send sequence. Rescues AI failures with a configurable fallback message. |
| `SystemPromptBuilder` | Interpolates `ChatbotConfig` into a system prompt template (skip-friendly, gender-inference instructions, services qualifier). |
| `LeadExtractor` | Parses the `---INTAKE_COMPLETE---` marker block from the AI's reply, builds a `Lead`, strips the block before the message goes back to the user. |
| `ShabbatWindow` | Pure function — Friday 4pm → Saturday 9pm in a configurable timezone. |

### Admin UI (`app/views/admin/intake/`)

- **Conversations index** — sortable + filterable + Turbo-Frame typeahead
  search across phone / message text / lead name; multi-channel "Platform"
  widget hinting at future channels (Instagram, SMS, etc.)
- **Conversation detail** — tight CRM-style chat transcript (not a
  consumer messaging UI), live Turbo Streams broadcasts of new messages,
  Take Over / Release / Mark Complete / Mark Abandoned actions, inline
  reply textarea when in human mode, in-thread Intake Summary card on
  completion with a services-priority pill, right-side editable Lead
  sidebar that also live-updates on completion
- **Leads index + detail** — filterable list, editable lead form,
  Services priority pill, admin notes field
- **Settings split** — General (global mode + paused reply), Shabbat
  (toggle + timezone), Chatbot Configuration (super-admin only — brand,
  welcome/completion text, prompt additions, auto-reply text)
- **Placeholders for adjacency** — Billing and Email Lists "Coming Soon"
  cards that read as intentional roadmap, not unfinished work
- **Mobile** — full hamburger panel below 768px

### Stimulus controllers (`app/javascript/controllers/`)

- `dismissible_details_controller.js` — close-on-outside-click + single-open
  behavior for native `<details>` dropdowns
- `debounced_form_controller.js` — 250 ms debounce on input + instant
  on select-change, for typeahead filtering inside a Turbo Frame
- `password_toggle_controller.js` — eye toggle on Devise password fields

## Design decisions worth calling out

**Solid Queue, not Sidekiq.** No Redis to operate; tables live in the same
Postgres database. One dedicated `worker` dyno on Heroku costs $7/mo. Solid
Queue's per-worker process supervisor is plenty for hundreds of webhook
events/minute.

**Namespaced models.** `Intake::Conversation` not `Conversation`. The same
codebase might later host a customer↔staff messaging system (which is what
the parent app does) — naming the WhatsApp domain explicitly keeps that
future without ambiguity. Module-level `table_name_prefix = "intake_"`
keeps the SQL tidy.

**The "structured block" extraction pattern.** Instead of forcing the AI to
emit JSON (fragile, slows replies, model-specific), the system prompt asks
it to append a plain-text `---INTAKE_COMPLETE---` block at the very end of
the closing message. `LeadExtractor` regex-parses it, persists the lead,
and strips the block before the user-facing reply is sent. Works
identically on Haiku / Sonnet / Opus / any future model.

**Infer gender from first name, don't ask.** Asking "are you a man or
woman?" right after the user said "Adam" reads as robotic. The system
prompt instructs the AI to infer from name when confident, and only ask
the seeking-gender question. Falls back to asking both for genuinely
ambiguous names (Pat, Sam, Jordan).

**Skip-friendly intake.** The welcome message tells the user upfront they
can say "skip" to any question. The AI accepts skip/pass/next gracefully
and records `[skipped]` in the structured block. Reduces drop-off
mid-intake.

**Services qualifier as a priority signal.** The intake asks early
which service tier the lead wants (matchmaking / coaching / database).
A pink "Matchmaking · High Priority" pill in the admin makes the
hottest leads scan-able at a glance — eliminates triage overhead.

**Graceful AI failure.** When the Anthropic call raises (no credits,
timeout, rate limit), the orchestrator catches it, logs the error class +
message, and sends a configurable "technical hiccup, please retry"
message. The user never sees silence.

**Twilio signature validation, not skipped.** Many tutorials skip
webhook signature validation for "simplicity." This implementation
validates every Twilio request via `Twilio::Security::RequestValidator`,
with an explicit `X-Skip-Twilio-Validation` header bypass for test
requests only.

## Setup

```sh
# Ruby + dependencies
bin/setup

# Database
bin/rails db:create db:migrate db:seed

# Credentials (interactive — opens $EDITOR)
bin/rails credentials:edit
# Add:
#   anthropic:
#     api_key: sk-ant-...
#   twilio:
#     account_sid: AC...
#     auth_token: ...
#     whatsapp_number: whatsapp:+14155238886   # Twilio sandbox to start

# Local dev server
bin/dev
```

Default admin login (from `db/seeds.rb`):

```
email:    admin@example.com
password: password123
```

## Tests

```sh
bin/rails test          # Minitest, parallel, 92 specs
bin/rubocop             # Omakase style
```

The test suite stubs Anthropic + Twilio via WebMock — no live API calls
ever fire from tests.

## Deploy to Fly.io ($5–20/mo)

The repo ships a `fly.toml` configured for two `shared-cpu-1x / 512MB`
machines (web + worker), `min_machines_running = 1` on the web side so
Twilio webhooks never hit a cold start.

```sh
# One-time setup
brew install flyctl
fly auth login
fly launch --copy-config --no-deploy   # creates the app, attaches Postgres
fly secrets set \
  RAILS_MASTER_KEY="$(cat config/master.key)" \
  ANTHROPIC_API_KEY="sk-ant-..." \
  TWILIO_ACCOUNT_SID="AC..." \
  TWILIO_AUTH_TOKEN="..." \
  TWILIO_WHATSAPP_NUMBER="whatsapp:+14155238886"

fly deploy
```

The `release_command` (`./bin/rails db:prepare`) runs migrations on every
deploy.

Optional — seed demo data so the admin pages look populated for visitors:

```sh
fly ssh console -C "env ALLOW_DEMO_SEED=true bin/rails runner db/seeds/dev_demo.rb"
```

Expected costs: ~$5/mo idle (two tiny Fly machines + Fly Postgres dev
plan), peak ~$20/mo with light Twilio + Anthropic usage assuming spend
caps are set on both providers.

## Connecting WhatsApp

1. Create a Twilio account → Messaging → Try It Out → **Send a WhatsApp
   Message**. Note the "join" sandbox phrase.
2. From your phone, send the join phrase via WhatsApp to `+1 415 523 8886`.
3. In Sandbox Settings, set the inbound webhook URL to your deployed app:
   `https://your-app.example.com/webhooks/twilio/whatsapp` (method POST).
4. Send another message to the sandbox number — you'll get an AI reply
   within ~2 seconds.

For production, migrate a real phone number into Twilio's WhatsApp Business
Platform (1–3 weeks Meta review, then swap `twilio.whatsapp_number` in your
credentials).

## Operational

```sh
bin/rails intake:wipe_conversations            # reset for clean demo (local)
heroku run rake intake:wipe_conversations \
  CONFIRM=app-name -a app-name                 # same on Heroku, gated
```

## Cost at scale

At ~50 intakes/day (typical small service business):

| Provider | $/mo | Notes |
|---|---|---|
| Heroku (web + worker dyno, Basic) | $14 | Both 512 MB, never sleep |
| Heroku Postgres (essential-0) | $5 | 1 GB cap, more than enough |
| Twilio WhatsApp | ~$180 | ~$0.01 per outbound message |
| Anthropic Haiku | ~$30 | ~$0.02 per complete intake |
| **Total** | **~$230/mo** | For an AI bot handling 50 leads/day |

Cost optimization: when Anthropic spend gets meaningful, enable
[prompt caching](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching)
on the system prompt + early conversation history. The system re-sends the
full context every turn — caching can drop input-token billing ~90% for
the cached portion.

## What you'd customize for your domain

The intake script and seeded `ChatbotConfig` are flavored as a generic
service-business intake. To repurpose:

1. Edit `db/seeds.rb` — change `brand_name`, `brand_tagline`,
   `welcome_message`, `completion_message`, `intake_questions`,
   `service_info` to your fields.
2. Run `bin/rails db:seed` (or use the Chatbot Configuration admin page
   if you've already seeded once — note `first_or_create!` won't
   overwrite an existing row).
3. The intake question schema is fully configurable JSON — no code
   changes needed to add/remove/reorder questions.

## License

MIT.

## Credits

Extracted and generalized from a production AI matchmaker app. Patterns
ported as-is; brand identifiers generalized.
