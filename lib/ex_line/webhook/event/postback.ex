defmodule ExLine.Webhook.Event.Postback do
  @moduledoc "A postback action fired. `postback` is `%{data: ..., params: ...}`."
  defstruct [
    :type,
    :mode,
    :timestamp,
    :source,
    :webhook_event_id,
    :delivery_context,
    :reply_token,
    :postback,
    :raw
  ]

  @type t :: %__MODULE__{}
end
