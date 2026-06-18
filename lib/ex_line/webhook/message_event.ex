defmodule ExLine.Webhook.MessageEvent do
  @moduledoc "A user sent a message. `message` is an `ExLine.Webhook.Message` struct."
  defstruct [
    :type,
    :mode,
    :timestamp,
    :source,
    :webhook_event_id,
    :delivery_context,
    :reply_token,
    :message,
    :raw
  ]

  @type t :: %__MODULE__{}
end
