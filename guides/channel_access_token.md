# Channel access tokens

A **channel access token** is the Bearer credential every Messaging API call needs:

```elixir
client = ExLine.Client.new(access_token: token)
ExLine.Api.Messaging.push(client, user_id, ExLine.Message.text("hi"))
```

You have two choices for where that token comes from:

1. **Just paste one.** In the LINE Developers Console, issue a long-lived token and
   put it in config. Done — you can ignore the rest of this guide.

   ```elixir
   config :ex_line, access_token: System.get_env("LINE_CHANNEL_ACCESS_TOKEN")
   ```

2. **Issue tokens programmatically** with `ExLine.Api.ChannelAccessToken`, and
   optionally keep one warm with `ExLine.ChannelAccessToken.Cache`. This is the rest
   of the guide.

## The three token types

| Type | Issue with | Auth | Lifetime | How many active | Verify/revoke |
| --- | --- | --- | --- | --- | --- |
| Long-lived (v1) | `issue/3` | channel id + secret | ~30 days fixed | 1 | `verify/2`, `revoke/2` |
| Stateless | `issue_stateless/3` or `issue_stateless_with_jwt/2` | secret **or** JWT | ~15 min | unlimited (not stored) | — |
| v2.1 (custom expiry) | `issue_jwt/2` | JWT assertion | up to 30 days | up to 30 | `verify_jwt/2`, `revoke_jwt/4`, `key_ids/2` |

Rules of thumb:

- **One bot, simplest setup** → paste a Console long-lived token, or `issue/3`.
- **Short bursts / serverless** → stateless. Issue one, send, forget. No state to manage.
- **Need to rotate without downtime, or many short-lived tokens** → v2.1 (up to 30
  active tokens with independent expiries).

All of these take a **transport-only** client — they authenticate through the
request body, not a Bearer header, so there is no `access_token` to provide:

```elixir
client = ExLine.Client.transport()
```

## Issuing without JWT (channel secret)

The simplest programmatic path. No keys to generate.

```elixir
client = ExLine.Client.transport()

{:ok, %{"access_token" => token, "expires_in" => secs}} =
  ExLine.Api.ChannelAccessToken.issue_stateless(client, channel_id, channel_secret)
```

(`issue/3` is the same call shape for a long-lived v1 token.)

## Issuing with a JWT assertion (stateless or v2.1)

The JWT-based endpoints prove channel ownership with a JWT you sign with a private
key, whose public key LINE knows.

### 1. Generate a key pair

```sh
# Private key (keep this secret, give it to ExLine)
openssl genrsa -out line_assertion.pem 2048
# Public key (register this with LINE)
openssl rsa -in line_assertion.pem -pubout -out line_assertion.pub.pem
```

LINE accepts the public key as a **JWK**. Convert the PEM to a JWK (one option):

```elixir
{_, jwk_map} =
  "line_assertion.pub.pem"
  |> File.read!()
  |> JOSE.JWK.from_pem()
  |> JOSE.JWK.to_map()

# add "alg" and "use" as the Console expects
jwk_map = Map.merge(jwk_map, %{"alg" => "RS256", "use" => "sig"})
IO.puts(Jason.encode!(jwk_map))
```

### 2. Register the public key in the Console

In the LINE Developers Console, open your **Messaging API channel → Basic settings
→ Assertion Signing Key → Register a public key**, paste the JWK, and save. The
Console returns a **`kid`** (key id). Keep it.

### 3. Sign assertions with the private key + kid

`ExLine.ChannelAccessToken.Assertion.sign/1` builds the RS256 JWT for you:

```elixir
assertion =
  ExLine.ChannelAccessToken.Assertion.sign(
    channel_id: channel_id,        # used as iss/sub
    kid: kid,                      # from the Console
    private_key: File.read!("line_assertion.pem"),
    token_exp: 2_592_000           # desired token lifetime in seconds (v2.1 only, max 30 days)
  )

client = ExLine.Client.transport()

# v2.1 token (keep key_id to list/inspect later)
{:ok, %{"access_token" => token, "key_id" => key_id}} =
  ExLine.Api.ChannelAccessToken.issue_jwt(client, assertion)

# or a stateless token (sign without :token_exp)
{:ok, %{"access_token" => token}} =
  ExLine.Api.ChannelAccessToken.issue_stateless_with_jwt(client, assertion)
```

List the valid v2.1 key ids (also JWT-authenticated):

```elixir
{:ok, %{"kids" => kids}} = ExLine.Api.ChannelAccessToken.key_ids(client, assertion)
```

## Caching and auto-refresh

`ExLine.ChannelAccessToken.Cache` keeps a token warm and refreshes it before it
expires. ExLine owns no processes, so you add it to **your** supervision tree:

```elixir
children = [
  {ExLine.ChannelAccessToken.Cache,
   name: :my_channel,
   issue: fn ->
     ExLine.Api.ChannelAccessToken.issue_stateless(
       ExLine.Client.transport(),
       System.fetch_env!("LINE_CHANNEL_ID"),
       System.fetch_env!("LINE_CHANNEL_SECRET")
     )
   end,
   refresh_before: 600}
]

Supervisor.start_link(children, strategy: :one_for_one)
```

Read the cached token wherever you send messages:

```elixir
{:ok, token} = ExLine.ChannelAccessToken.Cache.token(:my_channel)
client = ExLine.Client.new(access_token: token)
ExLine.Api.Messaging.push(client, user_id, ExLine.Message.text("hi"))
```

For multiple channels, start one `Cache` per channel under different `:name`s. For a
v2.1 token, make `:issue` sign an assertion and call `issue_jwt/2` instead.
