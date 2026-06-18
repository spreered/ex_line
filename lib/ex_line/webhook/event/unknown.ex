defmodule ExLine.Webhook.Event.Unknown do
  @moduledoc "Fallback for an event type ExLine does not model (a less common or newly added type). The envelope is still parsed; full payload is in `raw`."
  defstruct [:type, :mode, :timestamp, :source, :webhook_event_id, :delivery_context, :raw]
  @type t :: %__MODULE__{}
end
