defmodule ExLine.Webhook.Event.MemberLeft do
  @moduledoc "A user left a group/room the bot is in. `left` is `%{members: [Source]}`."
  defstruct [:type, :mode, :timestamp, :source, :webhook_event_id, :delivery_context, :left, :raw]
  @type t :: %__MODULE__{}
end
