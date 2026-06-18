defmodule ExLine.Webhook.Event.Deactivated do
  @moduledoc "A module channel was deactivated (lost chat control)."
  defstruct [:type, :mode, :timestamp, :source, :webhook_event_id, :delivery_context, :raw]
  @type t :: %__MODULE__{}
end
