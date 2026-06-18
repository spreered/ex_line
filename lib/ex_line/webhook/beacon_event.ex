defmodule ExLine.Webhook.BeaconEvent do
  @moduledoc "A user entered the range of a LINE Beacon."
  defstruct [
    :type,
    :mode,
    :timestamp,
    :source,
    :webhook_event_id,
    :delivery_context,
    :reply_token,
    :beacon,
    :raw
  ]

  @type t :: %__MODULE__{}
end
