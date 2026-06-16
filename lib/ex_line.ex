defmodule ExLine do
  @moduledoc """
  An Elixir client for the [LINE](https://developers.line.biz/) platform.

  `ExLine` wraps the LINE **Messaging API** (with LIFF / LINE Login planned). It is
  built around a few small ideas:

    * **Credentials are values.** Build an `ExLine.Client` and pass it per call;
      there is no global state, so multi-channel / multi-tenant apps are first-class.
    * **HTTP is swappable.** Calls go through `ExLine.Client.Adapter`, so tests can
      mock the network.
    * **Webhooks verify and route.** `ExLine.Webhook.Signature` / `ExLine.Webhook.Plug`
      verify the `x-line-signature`; `ExLine.EventRouter` dispatches events.

  ## Quick start

      client = ExLine.Client.new(access_token: "CHANNEL_ACCESS_TOKEN")
      ExLine.Messaging.push(client, "U123...", ExLine.Message.text("hello"))

  See `ExLine.Messaging`, `ExLine.Message`, `ExLine.Webhook.Signature`, and
  `ExLine.EventRouter`.
  """
end
