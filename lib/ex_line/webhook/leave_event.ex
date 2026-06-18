defmodule ExLine.Webhook.LeaveEvent do
  @moduledoc "The bot was removed from a group or room."
  defstruct [:type, :mode, :timestamp, :source, :webhook_event_id, :delivery_context, :raw]
  @type t :: %__MODULE__{}
end
