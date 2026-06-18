defmodule ExLine.Webhook.Event.Unfollow do
  @moduledoc "A user blocked the bot."
  defstruct [:type, :mode, :timestamp, :source, :webhook_event_id, :delivery_context, :raw]
  @type t :: %__MODULE__{}
end
