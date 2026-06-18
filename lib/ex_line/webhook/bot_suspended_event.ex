defmodule ExLine.Webhook.BotSuspendedEvent do
  @moduledoc "The bot was suspended (e.g. a chat was handed to a human operator)."
  defstruct [:type, :mode, :timestamp, :source, :webhook_event_id, :delivery_context, :raw]
  @type t :: %__MODULE__{}
end
