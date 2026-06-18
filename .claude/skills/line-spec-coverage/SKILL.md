---
name: line-spec-coverage
description: Update the vendored LINE OpenAPI spec and/or audit how much of it ExLine implements. Use when the user asks to "update the line spec", "re-vendor the openapi", "check API coverage", "what's missing from the LINE API", "盤點覆蓋率", "更新 yml", or wants a coverage report of ExLine vs LINE's official spec.
---

# LINE spec coverage & vendoring

This skill keeps ExLine aligned with LINE's official OpenAPI spec
(<https://github.com/line/line-openapi>) and reports implementation coverage.

The vendored spec lives in `test/support/line_openapi/` with the pinned commit
recorded in `test/support/line_openapi/README.md`. Conformance tests
(`ExLine.Conformance`) validate against it.

Two tasks — do whichever the user asked for (or both).

## Task A — Update the vendored spec

1. Find the target commit (default: latest `main`):
   ```sh
   curl -s "https://api.github.com/repos/line/line-openapi/commits/main" \
     | python3 -c "import sys,json;d=json.load(sys.stdin);print(d['sha'], d['commit']['author']['date'])"
   ```
2. For each spec file ExLine vendors (currently `messaging-api.yml` and
   `webhook.yml`; later also `channel-access-token.yml`, `insight.yml`,
   `manage-audience.yml`, `liff.yml`), download at the target commit:
   ```sh
   COMMIT=<sha>
   for f in messaging-api.yml webhook.yml; do
     curl -s "https://raw.githubusercontent.com/line/line-openapi/$COMMIT/$f" \
       -o "test/support/line_openapi/$f"
   done
   ```
3. `git diff test/support/line_openapi/` — summarize what changed (new/changed
   endpoints, new message types, new/changed constraints like maxLength/required).
4. Update the pinned commit + date in `test/support/line_openapi/README.md`.
5. Run `mix test --only conformance`. Any red test = our code now violates the new
   spec; report it (do NOT silently change builders — surface it for a decision).

## Task B — Coverage audit

Extract what the spec defines, compare to what `lib/ex_line/` implements, output a
coverage table mapped to namespaces.

**1. Extract from the spec** (`F=test/support/line_openapi/messaging-api.yml`):
```sh
# endpoints
grep -oE 'operationId: [a-zA-Z0-9]+' $F | sed 's/operationId: //' | sort -u
# message subtypes (from the Message discriminator mapping)
sed -n '/^    Message:/,/^    [A-Z][a-zA-Z]*:/p' $F | grep -oE '/[A-Za-z]+Message"?' | tr -d '/"' | sort -u
# action subtypes
sed -n '/^    Action:/,/^    [A-Z][a-zA-Z]*:/p' $F | grep -oE '/[A-Za-z]+Action"?' | tr -d '/"' | sort -u
# template subtypes
sed -n '/^    Template:/,/^    [A-Z][a-zA-Z]*:/p' $F | grep -oE '/[A-Za-z]+Template"?' | tr -d '/"' | sort -u
```

Webhook side (`W=test/support/line_openapi/webhook.yml`):
```sh
# event types (Event discriminator)
sed -n '/^    Event:/,/^    [A-Z][a-zA-Z]*:/p' $W | grep -oE '/[A-Za-z]+Event"?' | tr -d '/"' | sort -u
# message content types (MessageContent discriminator)
sed -n '/^    MessageContent:/,/^    [A-Z][a-zA-Z]*:/p' $W | grep -oE '/[A-Za-z]+MessageContent"?' | tr -d '/"' | sort -u
```

**2. Detect what's implemented:**
```sh
# request paths wired up
grep -rhoE '"/v2/bot[^"]*"' lib/ex_line | sort -u
# message/action/template type tags we build
grep -rhoE 'type: "[a-zA-Z]+"' lib/ex_line/message* | sort -u
# webhook event/content structs + parse clauses
grep -rhoE 'defmodule ExLine.Webhook\.[A-Za-z.]+' lib/ex_line/webhook
grep -rhoE '"type" => "[a-zA-Z]+"' lib/ex_line/webhook.ex lib/ex_line/webhook/message.ex | sort -u
# public functions per module
grep -rnE '^  def [a-z]' lib/ex_line
```

**3. Cross-reference and emit a table** using this namespace map (the canonical
mapping for ExLine — keep in sync with `notes/plan_message_api.md`):

| spec area | namespace |
| --- | --- |
| reply/push/multicast/broadcast/narrowcast/markAsRead/loadingAnimation | `ExLine.Api.Messaging` |
| validate* (messages) | `ExLine.Api.Messaging` (validate_*) |
| quota / sent-count / narrowcast-progress / PNP stats | `ExLine.Api.Messaging` |
| message content (download/preview/transcoding) | `ExLine.Api.Content` (api-data host) |
| getProfile / getFollowers | `ExLine.Api.Profile` |
| getBotInfo | `ExLine.Api.Bot` |
| group/room | `ExLine.Api.Group` |
| rich menu (all) | `ExLine.Api.RichMenu` |
| webhook endpoint settings (get/set/test) | `ExLine.Api.Webhook` (distinct from `ExLine.Webhook`, which parses incoming events) |
| issueLinkToken | `ExLine.Api.AccountLink` |
| membership | `ExLine.Api.Membership` |
| coupon | `ExLine.Api.Coupon` |
| aggregation unit / insight | `ExLine.Api.Insight` |
| message/template/action/flex builders | `ExLine.Message.*` |
| webhook event types (webhook.yml) | `ExLine.Webhook.Event.*` (parsed by `ExLine.Webhook.parse/1`) |
| webhook message content (webhook.yml) | `ExLine.Webhook.Message.*` |

Output: per-area counts (implemented / total), the list of missing items, and which
milestone (`notes/milestone.md`) they belong to. Flag any spec item that has no
namespace mapping yet (it may be a newly added API area).

**4. Other line-openapi specs** not yet vendored, and their target namespace:
`channel-access-token.yml` → `ExLine.Auth.*` (M3); `insight.yml` → `ExLine.Api.Insight`,
`manage-audience.yml` → `ExLine.Api.Audience` (M4); `liff.yml` → `ExLine.Liff.Apps`
(Plan 2). Note if any are now relevant to current work.
(`messaging-api.yml` and `webhook.yml` are already vendored.)

## Notes

- The audit is heuristic (grep-based); when in doubt, read the module to confirm an
  endpoint/type is really implemented vs just referenced.
- Keep the coverage snapshot in `notes/milestone.md` (M1.5) updated if asked.
