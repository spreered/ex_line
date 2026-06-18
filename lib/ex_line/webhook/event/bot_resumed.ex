defmodule ExLine.Webhook.Event.BotResumed do
  @moduledoc "The bot was resumed."
  defstruct [:type, :mode, :timestamp, :source, :webhook_event_id, :delivery_context, :raw]
  @type t :: %__MODULE__{}
end
