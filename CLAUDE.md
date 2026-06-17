# ex_line

An independent, standalone Elixir hex for the LINE platform. Package `ex_line`,
top-level module `ExLine`.

## Project context

- **Standalone hex.** This is NOT integrated into hawk and does NOT involve any
  hawk refactoring. hawk's `lib/line/*` is reference material only.
- **Scope order:** finish the **Messaging API** first, then add **LIFF**.
- **Naming:** package `ex_line`, base module `ExLine` (e.g. `ExLine.Messaging`,
  `ExLine.Webhook`, `ExLine.Liff`).
- Planning lives in `notes/`: see [milestone.md](notes/milestone.md),
  [plan_message_api.md](notes/plan_message_api.md),
  [plan_liff.md](notes/plan_liff.md), and the API inventories
  [line_message_api.md](notes/line_message_api.md) / [line_liff.md](notes/line_liff.md).

## Architecture principles

- **Credentials are passed as values, never global.** Each API function takes
  only the credential it needs; do not bundle multiple channels into one struct.
  `app env` is only a convenience default for the single-channel case; multi-channel
  is the default supported scenario.
- **Split credentials by channel concern.** Messaging access token, Messaging
  channel secret (webhook signature), and LINE Login channel id/token are distinct
  trust boundaries — keep them separate (`%ExLine.Client{}` vs `%ExLine.Login{}`).
- **Plugs / runtime channel selection take a resolver function.** The SDK never
  owns a channel registry.
- **Pure routing DSLs use `use` macros** (`ExLine.EventRouter`, `ExLine.EventHandler`).
  App glue (controllers, router wiring) belongs to the host app or a generator.
- **HTTP via Req.** HTTP calls go through an `ExLine.Client.Adapter` behaviour so
  consumers can mock it; default impl is `ExLine.Client.Req`.
- **Message objects are map builders** (light, easy to serialize), with `@spec`s
  and validation — not structs.

## Documentation conventions

Baseline is **full ExDoc** — modern ExDoc auto-generates `llms.txt` and a
"Copy Markdown" button, so ExDoc IS the LLM-friendly path. Apply these on top:

1. **Every public function gets `@doc` + `@spec`.** Every public module gets
   `@moduledoc`.
2. **Examples are doctests where possible.** Pure functions (builders, signature
   verification, webhook parsing) MUST have runnable `iex>` doctests — they double
   as verified examples and tests. Functions that hit the network show an
   illustrative `iex>` example (mocked or not run as a doctest); state this clearly.
3. **Examples are self-contained.** Show the full flow (build client → call →
   return shape). Never rely on "see above" cross-references — an LLM extracting a
   single doc block loses that context.
4. **Spell out return and error shapes** explicitly, e.g.
   `{:ok, map()} | {:error, ExLine.Error.t()}`, and document the keys in the map.
5. **Maintain one `cheatsheet.cheatmd`** as a condensed API map (good for humans
   and LLMs). Keep task-oriented guides in `extras`.

### LINE API reference links (required)

Any module or function that wraps a LINE API endpoint MUST cite the official LINE
documentation link in its `@doc`/`@moduledoc`, with the section anchor where one
exists. Example:

    @doc \"\"\"
    Sends reply messages using a reply token.

    Ref: https://developers.line.biz/en/reference/messaging-api/#send-reply-message
    \"\"\"

The verified reference links (with anchors) are already collected in
`notes/line_message_api.md` and `notes/line_liff.md` — copy from there rather than
guessing anchors.

## Testing

- Mock the `ExLine.Client.Adapter` (Mox) to assert request body/headers/host
  without network access.
- Pure functions: fixture comparison + doctests.
- Real-API smoke tests use a personal test channel, credentials from env, tagged
  `@tag :external` and excluded by default (`ExUnit.start(exclude: [:external])`).
- Never commit channel tokens or secrets.

## Conformance (format matches LINE's spec)

The source of truth for "our output matches LINE's expected format" is LINE's
official OpenAPI spec, vendored under `test/support/line_openapi/` (pinned to a
commit). Validate builder/request output with `ExLine.Conformance.assert_conforms/2`
(backed by `open_api_spex`; the helper strips discriminators because LINE uses a
`parent + allOf` polymorphism shape that open_api_spex's discriminator cast can't
handle, and we always validate against a concrete schema name).

- **Spec-driven TDD loop** for anything that maps to a LINE schema (message types,
  templates, actions, request bodies): write the `assert_conforms(..., "SchemaName")`
  test first (red), then implement until green.
- **When LINE updates the spec:** re-vendor the YAML (bump the pinned commit),
  `git diff` to see what changed, re-run `mix test`. Code that violates a new
  constraint turns its conformance test red — fix, then commit. No regeneration.
- **Test structure:** conformance tests live in each module's own test file inside a
  `describe "conformance" do @describetag :conformance ... end` block (not a separate
  file), so adding a type touches one file. Run all of them with
  `mix test --only conformance`. The shared helper stays in `test/support/`.
- Conformance validates the structure of the *sample* you pass; it does not prove
  builders reject invalid input (e.g. over-length text). Input validation is a
  separate, explicit decision.

## Commit 
Don't write co-authored by in the commit message
