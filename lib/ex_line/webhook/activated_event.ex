defmodule ExLine.Webhook.ActivatedEvent do
  @moduledoc "A module channel was activated (gained chat control)."
  defstruct [
    :type,
    :mode,
    :timestamp,
    :source,
    :webhook_event_id,
    :delivery_context,
    :chat_control,
    :raw
  ]

  @type t :: %__MODULE__{}
end
