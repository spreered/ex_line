defmodule ExLine.Webhook.UnsendEvent do
  @moduledoc "A user unsent (withdrew) a message."
  defstruct [
    :type,
    :mode,
    :timestamp,
    :source,
    :webhook_event_id,
    :delivery_context,
    :unsend,
    :raw
  ]

  @type t :: %__MODULE__{}
end
