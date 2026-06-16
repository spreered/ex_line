# ExLine

An Elixir client for the [LINE](https://developers.line.biz/) platform — Messaging
API today, LIFF / LINE Login planned.

> Unofficial. Not affiliated with or endorsed by LY Corporation.

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

## Sending messages

```elixir
client = ExLine.Client.new(access_token: "CHANNEL_ACCESS_TOKEN")

# push
ExLine.Messaging.push(client, "U123...", ExLine.Message.text("hello"))

# reply (using a webhook replyToken)
ExLine.Messaging.reply(client, reply_token, [
  ExLine.Message.text("hi"),
  ExLine.Message.Template.buttons("Pick one", [
    ExLine.Message.Action.message("A", "a"),
    ExLine.Message.Action.postback("B", "action=b")
  ])
])
```

Push supports idempotent retries via `X-Line-Retry-Key`:

```elixir
ExLine.Messaging.push(client, "U123...", msg, retry_key: "a-uuid")
```

Errors come back as `{:error, %ExLine.Error{kind: kind}}` where `kind` is one of
`:transient`, `:quota_exceeded`, `:permanent`, or `:network` (see
`ExLine.Error.retryable?/1`).

For a multi-channel app, build the client from whatever you store per channel:

```elixir
client = ExLine.Client.new(access_token: channel.access_token)
```

Or, for a single channel, from config:

```elixir
config :ex_line, access_token: "...", channel_id: "..."
ExLine.Client.from_env()
```

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
    ExLine.Messaging.reply(client, token, text("Need help?"))
    :ok
  end
end

# in your webhook controller, for each event:
MyApp.LineRouter.call(event, %{})
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

ExLine.Messaging.push(client, "U1", ExLine.Message.text("hi"))
```

## Status

Early. Implemented: client + adapter, message builders (text / sticker / buttons /
confirm + actions), `Messaging.reply` / `push`, webhook signature verification +
Plug, and the event routing DSL. Broader Messaging coverage (multicast / broadcast /
rich menu / content) and LIFF support are planned — see `notes/`.
