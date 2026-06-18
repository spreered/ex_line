defmodule ExLine.Webhook.Event.Join do
  @moduledoc "The bot joined a group or room."
  defstruct [
    :type,
    :mode,
    :timestamp,
    :source,
    :webhook_event_id,
    :delivery_context,
    :reply_token,
    :raw
  ]

  @type t :: %__MODULE__{}
end
