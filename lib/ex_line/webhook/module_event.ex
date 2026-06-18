defmodule ExLine.Webhook.ModuleEvent do
  @moduledoc "A module channel event (attach/detach, etc.)."
  defstruct [
    :type,
    :mode,
    :timestamp,
    :source,
    :webhook_event_id,
    :delivery_context,
    :module,
    :raw
  ]

  @type t :: %__MODULE__{}
end
