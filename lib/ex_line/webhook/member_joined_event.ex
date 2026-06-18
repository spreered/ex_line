defmodule ExLine.Webhook.MemberJoinedEvent do
  @moduledoc "A user joined a group/room the bot is in. `joined` is `%{members: [Source]}`."
  defstruct [
    :type,
    :mode,
    :timestamp,
    :source,
    :webhook_event_id,
    :delivery_context,
    :reply_token,
    :joined,
    :raw
  ]

  @type t :: %__MODULE__{}
end
