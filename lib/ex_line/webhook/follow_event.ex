defmodule ExLine.Webhook.FollowEvent do
  @moduledoc "A user added the bot as a friend (or unblocked it)."
  defstruct [
    :type,
    :mode,
    :timestamp,
    :source,
    :webhook_event_id,
    :delivery_context,
    :reply_token,
    :follow,
    :raw
  ]

  @type t :: %__MODULE__{}
end
