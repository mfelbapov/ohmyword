# Ticketing & Roadmap System — Design Discussion

## What exists today

- **Auth**: Scope-based, `users.role` enum (`:member`, `:admin`), LetMe policy framework
- **Admin**: Kaffy at `/admin/kaffy`, custom dashboard at `/admin/dashboard`, three-layer defense (plug → RequireAdmin → Kaffy authorize)
- **Flag system**: Does not exist yet — mentioned as a separate data-quality feature that feeds into this system
- **Data model**: `vocabulary_words`, `search_terms`, `sentences`, `sentence_words`

## Proposed feature set (as stated)

1. Public roadmap page (admin-managed, navbar link)
2. Ticket submission (auth-gated): feature requests, bug reports, feedback
3. Tickets private by default, admin promotes to public, public tickets support upvoting
4. Flag → ticket promotion
5. API endpoints for LLM agent integration
6. LLM agent layer: auto-triage, duplicate detection, proposed fixes for linguistic data
7. `ticket_events` audit log
8. Tiered automation: auto-triage yes, auto-resolve only with human approval

---

## 1. The roadmap-vs-tickets identity question

**The core tension**: Are roadmap items and tickets the same entity in different states, or separate entities?

### Option A: Unified model (tickets are everything)
A ticket moves through states: `submitted → triaged → planned → in_progress → done`. The roadmap page is just a filtered view of tickets in `planned`/`in_progress`/`done` states.

- **Pro**: One table, one set of queries, no sync issues
- **Con**: Roadmap items that were never tickets (e.g. "Redesign homepage" that you planned yourself) need to be created as tickets by an admin, which feels awkward. Roadmap items carry ticket baggage (reporter, category, etc.) that doesn't apply.

### Option B: Separate entities
`roadmap_items` table with its own schema (`title`, `description`, `status`, `sort_order`). Tickets can be *linked* to a roadmap item but aren't the same row.

- **Pro**: Clean separation. Roadmap items are lightweight. Admin creates them freely without the ticket machinery.
- **Con**: Two models to maintain. A promoted ticket needs a manual link step.

### Option C: Hybrid — tickets with a `roadmap` boolean/promotion
Tickets table, but roadmap items that don't originate from user submissions are created by admin as "internal tickets" with a flag like `source: :internal`. Roadmap page filters on `roadmap_visible: true`.

- **Pro**: Single table but flexible. Internal items don't need a reporter.
- **Con**: The ticket schema accumulates nullable fields that only apply to some rows.

**Recommendation**: Option B (separate entities) is cleanest for your use case. Your roadmap is an admin-curated communication tool — it shouldn't be constrained by ticket schema. A simple `roadmap_items` table with a nullable `ticket_id` FK gives you linking without coupling. You can always query "tickets linked to roadmap items" without making every roadmap item a ticket.

**Open question**: Do you want users to see which roadmap items came from community tickets? That affects whether the link is exposed in the UI or is just internal bookkeeping.

---

## 2. Ticket lifecycle and states

Proposed state machine:

```
submitted → triaged → [planned | wont_fix | duplicate]
                          ↓
                     in_progress → done
```

**Questions to resolve**:

- **Who triages?** If the LLM agent auto-triages, does it set the state to `triaged` immediately, or does it suggest a triage that an admin confirms? If auto-triage sets state directly, then `submitted` is a transient state that most tickets pass through instantly.

- **What does "triaged" mean concretely?** Is it just "an admin or agent has looked at this and assigned a category/priority"? Or does it imply a commitment to act? If it's just "acknowledged," you might want `acknowledged` as a state name to set user expectations correctly.

- **`wont_fix` vs `closed`**: A `wont_fix` state is useful for audit trail, but do users see this? If a user's private ticket is marked `wont_fix`, do they get notified? Consider whether you want `closed` with a `resolution` enum (`fixed`, `wont_fix`, `duplicate`, `invalid`) instead of encoding resolution in the state.

- **Reopening**: Can a `wont_fix` ticket be reopened? By the user? By the admin? This matters for the state machine.

**Suggestion**: Keep states simple (`open`, `in_progress`, `closed`) and use a separate `resolution` field for the outcome. Fewer states = simpler queries, simpler UI, less confusion for users.

---

## 3. Ticket schema design

```
tickets
  id
  title                   - string, required
  body                    - text, required (markdown?)
  category                - enum: feature_request | bug_report | feedback | data_quality
  status                  - enum: open | in_progress | closed
  resolution              - enum (nullable): fixed | wont_fix | duplicate | invalid
  priority                - enum (nullable): low | medium | high | critical (admin/agent-set)
  visibility              - enum: private | public (default: private)
  source                  - enum: user | flag | agent (where did this ticket originate?)
  user_id                 - FK to users (reporter), nullable if source is agent
  duplicate_of_id         - FK to tickets (self-referential, nullable)
  flag_id                 - FK to flags (nullable, if promoted from flag)
  upvote_count            - integer, default 0 (denormalized counter)
  agent_summary           - text (nullable, LLM-generated triage summary)
  inserted_at / updated_at
```

**Decisions embedded here**:

### 3a. `category` — is `data_quality` a ticket category or should flags stay separate?

Flags are about specific data issues on specific words/sentences. Tickets are about the product. These feel fundamentally different:

- A flag says "the genitive plural of 'knjiga' is wrong" — it's tied to a `vocabulary_word` or `sentence` row
- A ticket says "add a dark mode" or "the flashcard timer is too fast"

**If flags are a ticket category**, you need `flaggable_type` + `flaggable_id` polymorphic fields on tickets, which muddies the schema. You also lose the ability to have lightweight flags that don't need titles, priorities, or the full ticket lifecycle.

**Recommendation**: Keep flags as a separate lightweight table. Add a `ticket_id` FK on the flag for when it's promoted. The flag table is simple:

```
flags
  id
  reason              - enum: incorrect_form | missing_form | wrong_translation | other
  description         - text (optional user note)
  status              - enum: pending | resolved | promoted | dismissed
  flaggable_type      - string: "word" | "sentence"
  flaggable_id        - integer
  user_id             - FK to users
  ticket_id           - FK to tickets (nullable, set on promotion)
  inserted_at / updated_at
```

This way flags are cheap to create (no title required, minimal fields), and promotion to a ticket is an explicit admin/agent action that creates a proper ticket and backlinks the flag.

### 3b. `user_id` nullability

If an agent creates a ticket (e.g. from analyzing flag patterns), who is the reporter? Options:
- Nullable `user_id` with `source: :agent`
- A system user row in the `users` table
- A separate `agent_id` field

**Recommendation**: Nullable `user_id`. Don't create fake user rows. The `source` field tells you it's agent-created. Simpler, no phantom users polluting queries.

### 3c. `upvote_count` denormalization

A counter cache avoids `COUNT(*)` on every roadmap page load. But it means you need to maintain it carefully (increment on upvote, decrement on un-upvote, handle user deletion).

**Alternative**: Just do the join. With your user base size, `COUNT(*)` on an indexed `ticket_upvotes` table will be sub-millisecond. Premature optimization adds maintenance burden.

**Recommendation**: Skip the counter cache for now. Add it later if you have performance evidence.

### 3d. Markdown in ticket body?

If you allow markdown, you need to sanitize it (XSS). Phoenix has `Phoenix.HTML.raw/1` but you'd need a markdown parser + sanitizer. If tickets are mostly short text feedback, plain text with line breaks might be sufficient.

**Recommendation**: Start with plain text. Add markdown later if users actually need formatting.

---

## 4. The upvoting model

```
ticket_upvotes
  id
  ticket_id     - FK to tickets
  user_id       - FK to users
  inserted_at

  unique_index: [ticket_id, user_id]
```

**Questions**:

- **Can the original reporter upvote their own ticket?** Most systems don't allow this (it's implicit). But it's simpler to allow it and not special-case. Your call.

- **Upvote visibility**: Can users see who upvoted? Or just the count? If just the count, you might not even need a table — but you need deduplication, so you do need the table.

- **Un-upvoting**: Toggle behavior (click again to remove)? Or once upvoted, always upvoted? Toggle is more user-friendly.

- **Only on public tickets**: Upvoting only makes sense on public tickets. Enforce this at the context level, not just the UI.

---

## 5. The `ticket_events` audit log

```
ticket_events
  id
  ticket_id       - FK to tickets
  action          - string: "created" | "status_changed" | "visibility_changed" |
                    "priority_set" | "comment_added" | "promoted_from_flag" |
                    "duplicate_marked" | "agent_triaged" | "agent_fix_proposed" |
                    "upvoted" | ...
  actor_type      - enum: user | admin | agent | system
  actor_id        - integer (nullable, FK to users if user/admin)
  metadata        - jsonb (flexible payload: old_status, new_status, comment text, etc.)
  inserted_at
```

**Design questions**:

### 5a. Are comments a separate table or events with `action: "comment_added"`?

If comments are events, they live in `metadata.body`. This is elegant for the audit trail — everything is one stream. But it makes querying "show me all comments on this ticket" require filtering the events table.

If comments are a separate `ticket_comments` table, you have cleaner queries but two places to look for ticket activity.

**Recommendation**: Separate `ticket_comments` table. Comments are a first-class feature that users interact with directly. The audit log can still record a `comment_added` event pointing to the comment ID. Mixing user-facing content with system audit events in one table leads to awkward queries and UI logic.

### 5b. `actor_type` for agents

If you have multiple LLM agents in the future (triage agent, fix-proposal agent, notification agent), do you need to distinguish them? A simple `actor_type: :agent` might be enough now, with `metadata.agent_name` for future differentiation.

### 5c. Event granularity

Do you log every field change? Or just meaningful state transitions? Logging every change creates noise. Logging only transitions misses context.

**Recommendation**: Log state transitions and explicit actions (comments, promotions, assignments). Don't log field edits like "admin changed title from X to Y" — that's noise for a small app.

---

## 6. Flag → ticket promotion flow

When an admin (or agent) promotes a flag to a ticket:

1. Create a new ticket with `source: :flag`, `category: :data_quality`
2. Set `flag.ticket_id` to the new ticket
3. Set `flag.status` to `:promoted`
4. Log a `ticket_event` with `action: "promoted_from_flag"` and `metadata: %{flag_id: ...}`

**Edge cases**:

- **Multiple flags on the same word**: If three users flag the same word's genitive plural, do you create three tickets or one? You probably want one ticket with all three flags linked. But your schema has `flag.ticket_id`, not `ticket.flag_id`, so multiple flags can point to one ticket. Good.

- **Flag on a deleted word**: If a word is deleted after being flagged but before promotion, the flag's `flaggable_id` points to nothing. Use `ON DELETE SET NULL` or `ON DELETE CASCADE`? Cascade is probably right — if the word is gone, the flag is moot.

- **Re-flagging after resolution**: Can a user flag the same word again after their flag was dismissed? You probably want to allow it (maybe the admin was wrong), but consider a cooldown or "you already flagged this" notice.

---

## 7. API endpoints for LLM agent integration

### 7a. Authentication

How does the agent authenticate? Options:

1. **API key in header**: Simple, but you need a key management system. Where do keys live? A new `api_keys` table with scopes?
2. **Service token**: A long-lived token tied to a system identity. Simpler than a full API key system.
3. **Same session auth as users**: Agent logs in as a special user. But this couples agent auth to the user auth flow, which feels wrong.

**Recommendation for now**: A single API key stored as an environment variable, checked via a plug. No table, no key rotation UI. You can build that later. Something like:

```elixir
# In router
pipeline :api_authenticated do
  plug :verify_api_key
end

# Simple plug
defp verify_api_key(conn, _opts) do
  case get_req_header(conn, "x-api-key") do
    [key] when key == Application.get_env(:ohmyword, :agent_api_key) -> conn
    _ -> conn |> send_resp(401, "Unauthorized") |> halt()
  end
end
```

### 7b. Endpoint design

What does the agent need to do?

- **Read**: List tickets, get ticket details, list flags, get word/sentence data
- **Write**: Create tickets, add comments, update status (within automation tier rules), propose fixes
- **Triage**: Set category, priority, detect duplicates, generate summary

**Suggested endpoints** (REST):

```
GET    /api/tickets              - List tickets (filterable)
GET    /api/tickets/:id          - Get ticket with events
POST   /api/tickets              - Create ticket
PATCH  /api/tickets/:id          - Update ticket (status, priority, category)
POST   /api/tickets/:id/comments - Add comment
GET    /api/flags                - List flags (filterable by status)
PATCH  /api/flags/:id            - Update flag status
GET    /api/words/:id            - Get word with inflection data (for cross-referencing)
```

**Open question**: Does the agent need to call the inflection engine directly? If it's proposing fixes to inflection data, it might need `GET /api/words/:id/inflect` to see what the engine currently produces vs. what's in the seed data.

### 7c. Rate limiting

Even for your own agent, rate limiting prevents runaway loops. A simple in-memory rate limiter (or even just a log warning) is worth having from day one.

---

## 8. LLM agent layer — scope and boundaries

### 8a. Auto-triage: what does it actually do?

Define concretely what "triage" means for the agent:

- **Category assignment**: Given ticket title + body, classify as feature_request/bug_report/feedback/data_quality. This is straightforward.
- **Priority suggestion**: Low/medium/high/critical. More subjective. Does the admin review this before it sticks?
- **Duplicate detection**: Compare new ticket against existing open tickets. How? Embedding similarity? Keyword matching? This is the hardest part and has the most false-positive risk.
- **Summary generation**: TL;DR of the ticket for admin dashboard. Low risk, high value.

**Recommendation**: Start with category assignment + summary generation. These are low-risk, high-value. Add duplicate detection later — it's hard to get right and annoying when wrong ("Your ticket was marked as a duplicate of something unrelated").

### 8b. Linguistic data fixes

This is the most interesting and domain-specific part. The agent could:

1. Receive a flag saying "genitive plural of 'knjiga' is wrong"
2. Look up the word in `vocabulary_seed.json`
3. Run the inflection engine to see what it produces
4. Compare against the flagged form
5. Propose a fix (change to seed metadata, or identify an engine pattern bug)

**But**: This requires the agent to understand Serbian morphology deeply enough to know what the correct form *should be*. Can the LLM do this reliably? For common words, probably. For edge cases with palatalization and fleeting vowels, maybe not.

**Recommendation**: The agent proposes, a human confirms. Never auto-apply linguistic fixes. The proposal should include:
- What the engine currently produces
- What the user flagged as incorrect
- The agent's suggested correct form with reasoning
- Whether the fix is a seed metadata change or an engine code change

### 8c. Automation tiers — making them enforceable

"Auto-triage yes, auto-resolve only with human approval" needs to be enforced in code, not just convention. Consider:

```elixir
# In the ticket context
def agent_update_ticket(ticket, attrs, :auto) do
  allowed_auto_fields = [:category, :priority, :agent_summary]
  restricted_fields = Map.keys(attrs) -- allowed_auto_fields

  if restricted_fields != [] do
    {:error, :requires_human_approval, restricted_fields}
  else
    update_ticket(ticket, attrs)
  end
end
```

This way even if the agent code has a bug, the context layer prevents unauthorized state changes.

---

## 9. Visibility and privacy

### 9a. What's visible when a ticket goes public?

When admin promotes a ticket to public:
- Title: yes
- Body: yes? Or does admin write a sanitized version?
- Reporter username: configurable? Some users might not want attribution.
- Comments: all of them? Only admin responses? Only after promotion?
- Status/resolution: yes
- Priority: probably not (internal concern)
- Agent triage notes: probably not

**Recommendation**: Add `public_title` and `public_description` fields (nullable). When null, fall back to original title/body. This lets the admin rewrite for public consumption without losing the original submission.

Actually, this is over-engineering. Simpler: admin edits the title/body before making it public. The original is preserved in `ticket_events` as a `"edited"` event with the old values in metadata. No extra columns needed.

### 9b. Privacy on deletion

If a user deletes their account:
- Their private tickets: delete (cascade) or anonymize?
- Their upvotes: remove (and decrement counts if you have counter cache)
- Their flags: anonymize (keep the data quality signal, remove user attribution)
- Their comments: anonymize? Delete?

**Recommendation**: Anonymize rather than delete. Set `user_id` to NULL, keep the content. The ticket/flag data has value independent of who reported it. But check GDPR implications if you have EU users — anonymization may need to remove the text content too if it contains personal information.

---

## 10. UI considerations

### 10a. Roadmap page

Three columns (Kanban-style): Planned | In Progress | Done. Each card shows title, description snippet, upvote count (if linked to a public ticket), and category badge.

**Question**: Is the roadmap chronological within columns, or manually ordered? If manually ordered, you need a `sort_order` integer on roadmap items.

### 10b. Ticket submission

Simple form: title, body, category dropdown. No priority (that's admin/agent territory). Character limits? Max title length? Required fields?

**Question**: Do you want a "search before submitting" flow to reduce duplicates? E.g., as the user types a title, show similar existing public tickets. This is a UX choice — it reduces duplicates but adds friction.

### 10c. User's ticket list

A "My Tickets" page showing the user's submitted tickets with status badges. Can they edit tickets after submission? Close their own tickets?

### 10d. Admin ticket management

Kaffy resource for tickets? Or a custom admin LiveView? Kaffy is quick to set up but limited in UX. A custom LiveView gives you the triage workflow you want (bulk actions, agent suggestions inline, one-click promote-to-public).

**Recommendation**: Custom admin LiveView for tickets. Kaffy is great for simple CRUD but a triage workflow needs custom UX. You already have the pattern with `AdminDashboardLive`.

---

## 11. Things you haven't mentioned but should consider

### 11a. Notifications

When a ticket's status changes, does the reporter get notified? Email? In-app? Both? If you don't have notifications, users submit tickets into a void and never hear back. That's worse than not having a ticket system at all.

**Minimum viable**: Email notification on status change. You already have email infrastructure (user confirmation emails).

### 11b. Rate limiting on ticket submission

Without rate limiting, a single user could flood the system. Simple approach: max 5 tickets per user per day. Enforce in the context, not just the UI.

### 11c. Spam / abuse

Ticket body content moderation. For a small app, manual review is fine. But if you have the LLM agent anyway, it could flag obviously abusive submissions before they hit admin review.

### 11d. Ticket search

Can admins search tickets? Full-text search on title + body? PostgreSQL's built-in `tsvector` would work well here and you're already on Postgres.

### 11e. Metrics / analytics

- Average time from submission to resolution
- Tickets by category over time
- Flag-to-ticket conversion rate
- Most-upvoted unresolved tickets

These are easy to derive from the `ticket_events` table if you log timestamps on state transitions. Worth considering the queries you'll want when designing the event schema.

### 11f. Build order / phasing

You're describing a large system. Consider building in phases:

**Phase 1 — Foundation**:
- `tickets` table + context + basic CRUD
- Ticket submission LiveView (auth-gated)
- Admin ticket list + detail view (custom LiveView)
- `ticket_events` audit log (write-only for now)

**Phase 2 — Public layer**:
- Roadmap items table + public roadmap page
- Ticket → public promotion flow
- Upvoting on public tickets
- Link roadmap items to tickets

**Phase 3 — Data quality**:
- `flags` table + context
- Flag submission UI on word detail / sentence pages
- Flag → ticket promotion flow
- Admin flag management

**Phase 4 — Agent layer**:
- API endpoints (tickets + flags + words)
- API key auth
- Auto-triage (category + summary)
- Linguistic fix proposals

**Phase 5 — Polish**:
- Email notifications
- Duplicate detection
- Ticket search
- Analytics dashboard

---

## 12. Schema summary (proposed)

```
roadmap_items
  id            bigserial PK
  title         varchar NOT NULL
  description   text
  status        enum: planned | in_progress | done
  sort_order    integer NOT NULL DEFAULT 0
  ticket_id     FK to tickets (nullable)
  inserted_at   utc_datetime
  updated_at    utc_datetime

tickets
  id            bigserial PK
  title         varchar NOT NULL
  body          text NOT NULL
  category      enum: feature_request | bug_report | feedback | data_quality
  status        enum: open | in_progress | closed
  resolution    enum (nullable): fixed | wont_fix | duplicate | invalid
  priority      enum (nullable): low | medium | high | critical
  visibility    enum: private | public (default: private)
  source        enum: user | flag | agent
  user_id       FK to users (nullable)
  duplicate_of_id  FK to tickets (nullable, self-ref)
  agent_summary text (nullable)
  inserted_at   utc_datetime
  updated_at    utc_datetime

ticket_comments
  id            bigserial PK
  body          text NOT NULL
  ticket_id     FK to tickets
  user_id       FK to users (nullable, null = agent/system)
  author_type   enum: user | admin | agent
  inserted_at   utc_datetime

ticket_events
  id            bigserial PK
  ticket_id     FK to tickets
  action        varchar NOT NULL
  actor_type    enum: user | admin | agent | system
  actor_id      FK to users (nullable)
  metadata      jsonb DEFAULT '{}'
  inserted_at   utc_datetime

ticket_upvotes
  id            bigserial PK
  ticket_id     FK to tickets
  user_id       FK to users
  inserted_at   utc_datetime
  unique_index: [ticket_id, user_id]

flags
  id            bigserial PK
  reason        enum: incorrect_form | missing_form | wrong_translation | other
  description   text
  status        enum: pending | resolved | promoted | dismissed
  flaggable_type  varchar NOT NULL ("word" | "sentence")
  flaggable_id    bigint NOT NULL
  user_id       FK to users
  ticket_id     FK to tickets (nullable, set on promotion)
  inserted_at   utc_datetime
  updated_at    utc_datetime
```

---

## 13. Open questions for you to decide

1. **Roadmap identity**: Separate table (recommended) or unified with tickets?
2. **Ticket states**: Simple (open/in_progress/closed + resolution) or granular (submitted/triaged/planned/...)?
3. **Auto-triage scope**: Category + summary only? Or also priority and duplicate detection from the start?
4. **Public ticket content**: Show original submission or let admin curate a public version?
5. **Reporter attribution**: Show username on public tickets, or anonymous?
6. **Comments on public tickets**: Open to all authenticated users, or only reporter + admin?
7. **Notifications**: Email-only, in-app, or skip for MVP?
8. **Markdown support**: In ticket body and comments, or plain text?
9. **Flag scope**: Words only, or also sentences and search terms?
10. **Agent auth**: Env var API key (recommended for now) or something more structured?
11. **Build order**: Agree with the phasing above, or different priorities?
