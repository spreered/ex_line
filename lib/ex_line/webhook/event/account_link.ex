defmodule ExLine.Webhook.Event.AccountLink do
  @moduledoc "Result of an account link (link token flow)."
  defstruct [
    :type,
    :mode,
    :timestamp,
    :source,
    :webhook_event_id,
    :delivery_context,
    :reply_token,
    :link,
    :raw
  ]

  @type t :: %__MODULE__{}
end
