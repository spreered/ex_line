defmodule ExLine.Webhook.Event.PnpDeliveryCompletion do
  @moduledoc "Delivery completion for a LINE notification message (PNP)."
  defstruct [
    :type,
    :mode,
    :timestamp,
    :source,
    :webhook_event_id,
    :delivery_context,
    :delivery,
    :raw
  ]

  @type t :: %__MODULE__{}
end
