# ExLine

An Elixir client for the [LINE](https://developers.line.biz/) platform — Messaging
API today, LIFF / LINE Login planned.

A runnable example app lives at
[ex_line_demo](https://github.com/spreered/ex_line_demo).

## Design

- **Credentials are values, never global.** Build an `ExLine.Client` and pass it per
  call. Multi-channel / multi-tenant apps are first-class — there is no global
  registry to fight.
- **HTTP is swappable.** Requests go through the `ExLine.Client.Adapter` behaviour
  (default: `ExLine.Client.Req`), so you can mock the network in tests.
- **Webhooks verify and route.** `ExLine.Webhook.Signature` / `ExLine.Webhook.Plug`
  verify the `x-line-signature`; `ExLine.EventRouter` dispatches events to handlers.

## Installation

```elixir
def deps do
  [
    {:ex_line, "~> 0.1.0"}
  ]
end
```

`:plug` is an optional dependency, only needed if you use `ExLine.Webhook.Plug` /
`ExLine.Webhook.BodyReader`.

## Configuration

You need credentials from the [LINE Developers Console](https://developers.line.biz/console/):

| Credential | Where it's used | From |
| --- | --- | --- |
| **Channel access token** | sending messages (`ExLine.Client`) | Messaging API channel |
| **Channel secret** | webhook signature (`ExLine.Webhook`) | Messaging API channel |

ExLine never holds global credential state — you pass what each call needs. There
are three ways to supply them, pick per use case:

**1. Per-call value (default; multi-channel / multi-tenant friendly).** Build a
client from wherever you store the token (DB row, etc.) and pass it in:

```elixir
client = ExLine.Client.new(access_token: channel.access_token)
ExLine.Api.Messaging.push(client, user_id, message)
```

**2. From application config (single-channel convenience).**

```elixir
# config/runtime.exs
config :ex_line,
  access_token: System.fetch_env!("LINE_CHANNEL_ACCESS_TOKEN"),
  channel_id: System.get_env("LINE_CHANNEL_ID")
```

```elixir
client = ExLine.Client.from_env()
```

**3. Webhook secret via a resolver (kept separate from the client).** The channel
secret belongs to a different trust boundary, so it is passed directly — as a
static value, or a `fn conn -> secret end` resolver that picks the right channel
at request time (see [Receiving webhooks](#receiving-webhooks)):

```elixir
plug ExLine.Webhook.Plug, secret: System.fetch_env!("LINE_CHANNEL_SECRET")
# or, multi-channel:
plug ExLine.Webhook.Plug, secret: fn conn -> MyApp.secret_for(conn) end
```

> Never commit tokens or secrets — load them from the environment.

## Sending messages

```elixir
client = ExLine.Client.new(access_token: "CHANNEL_ACCESS_TOKEN")

# push
ExLine.Api.Messaging.push(client, "U123...", ExLine.Message.text("hello"))

# reply (using a webhook replyToken)
ExLine.Api.Messaging.reply(client, reply_token, [
  ExLine.Message.text("hi"),
  ExLine.Message.Template.buttons("Pick one", [
    ExLine.Message.Action.message("A", "a"),
    ExLine.Message.Action.postback("B", "action=b")
  ])
])
```

Push supports idempotent retries via `X-Line-Retry-Key`:

```elixir
ExLine.Api.Messaging.push(client, "U123...", msg, retry_key: "a-uuid")
```

Errors come back as `{:error, %ExLine.Error{kind: kind}}` where `kind` is one of
`:transient`, `:quota_exceeded`, `:permanent`, or `:network` (see
`ExLine.Error.retryable?/1`).

## Receiving webhooks

Verify the signature (works with or without Plug):

```elixir
ExLine.Webhook.Signature.valid?(raw_body, signature, channel_secret)
```

With Plug, preserve the raw body in your parser, then verify in the pipeline. The
`:secret` option takes a static binary or a `fn conn -> secret end` resolver so you
can pick the right channel per request:

```elixir
plug Plug.Parsers,
  parsers: [:json],
  body_reader: {ExLine.Webhook.BodyReader, :read_body, []},
  json_decoder: Jason

plug ExLine.Webhook.Plug, secret: &MyApp.line_secret/1
```

This is the framework-agnostic form (one `Plug` pipeline owns both the parser and
the verification). In **Phoenix** the parser lives in your Endpoint, not here — see
[Wiring it together (Phoenix)](#wiring-it-together-phoenix).

## Routing events

```elixir
defmodule MyApp.LineRouter do
  use ExLine.EventRouter

  text "hello", MyApp.HelpHandler, :hello
  postback "buy", MyApp.ShopHandler, :buy
  follow MyApp.OnboardHandler, :welcome
  default MyApp.FallbackHandler, :unknown

  @impl true
  def before_action(event, assigns), do: {event, Map.put(assigns, :client, MyApp.client())}
end

defmodule MyApp.HelpHandler do
  use ExLine.EventHandler

  @impl true
  def handle_event(:hello, %{"replyToken" => token}, %{client: client}) do
    ExLine.Api.Messaging.reply(client, token, text("Need help?"))
    :ok
  end
end
```

## Wiring it together (Phoenix)

The SDK gives you the verify plug, the parser (`ExLine.Webhook.parse/1`), and the
router DSL; the controller is yours. The flow is: **verify → parse → route →
return 200**. `parse/1` turns the request body into a list of `ExLine.Webhook`
event structs, and you hand each one to your router's `call/2`:

The raw body is needed to verify the signature, but Phoenix's `Plug.Parsers`
(in your **Endpoint**) consumes it first. So add the `body_reader` to the
`Plug.Parsers` your Endpoint *already* defines — don't add a second one in the
router (by the time the router runs, the body is already parsed):

```elixir
# lib/my_app_web/endpoint.ex — the Plug.Parsers Phoenix generated, with body_reader added
plug Plug.Parsers,
  parsers: [:urlencoded, :multipart, :json],
  pass: ["*/*"],
  body_reader: {ExLine.Webhook.BodyReader, :read_body, []},
  json_decoder: Phoenix.json_library()
```

The router pipeline then only verifies the signature; the parsing already happened
in the Endpoint:

```elixir
# lib/my_app_web/router.ex
pipeline :line_webhook do
  # rejects requests whose x-line-signature doesn't match the cached raw body (401)
  plug ExLine.Webhook.Plug, secret: &MyApp.line_secret/1
end

scope "/line", MyAppWeb do
  pipe_through :line_webhook
  post "/webhook", WebhookController, :handle
end
```

> `BodyReader` caches the raw body (a cheap prepend into `conn.assigns[:raw_body]`)
> for **every** request, since the Endpoint's parser is global — the same approach
> Stripe-style webhook verification uses in Phoenix. If you'd rather not cache
> globally, run a bare `Plug` pipeline scoped to the webhook path with its own
> `Plug.Parsers` + `ExLine.Webhook.Plug` instead (the framework-agnostic form shown
> under [Receiving webhooks](#receiving-webhooks)).

```elixir
# lib/my_app_web/controllers/webhook_controller.ex
defmodule MyAppWeb.WebhookController do
  use MyAppWeb, :controller

  def handle(conn, params) do
    params
    |> ExLine.Webhook.parse()
    |> Enum.each(&MyApp.LineRouter.call(&1, %{}))

    # Always 200 so LINE doesn't retry; the plug already rejected bad signatures.
    send_resp(conn, 200, "")
  end
end
```

LINE expects a prompt `200` and **retries on timeout**, so keep the request fast.
For handlers that do slow work (network calls, DB writes), process the events in a
supervised task and return `200` immediately — this also isolates a failing event
from the rest of the batch:

```elixir
def handle(conn, params) do
  events = ExLine.Webhook.parse(params)

  Task.Supervisor.start_child(MyApp.TaskSupervisor, fn ->
    Enum.each(events, fn event ->
      try do
        MyApp.LineRouter.call(event, %{})
      rescue
        e -> Logger.error("LINE event failed: #{Exception.message(e)}")
      end
    end)
  end)

  send_resp(conn, 200, "")
end
```

## Testing

Mock the adapter to assert outbound requests without hitting the network:

```elixir
# test_helper.exs
Mox.defmock(MyApp.LineAdapterMock, for: ExLine.Client.Adapter)

# in a test
client = ExLine.Client.new(access_token: "tok", adapter: MyApp.LineAdapterMock)

Mox.expect(MyApp.LineAdapterMock, :request, fn req ->
  assert req.url == "https://api.line.me/v2/bot/message/push"
  {:ok, %{status: 200, body: %{}}}
end)

ExLine.Api.Messaging.push(client, "U1", ExLine.Message.text("hi"))
```

## Status

Early. Implemented: client + adapter, message builders (text / sticker / buttons /
confirm + actions), `Messaging.reply` / `push`, webhook signature verification +
Plug, and the event routing DSL. Broader Messaging coverage (multicast / broadcast /
rich menu / content) and LIFF support are planned — see `notes/`.
