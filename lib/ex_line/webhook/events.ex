defmodule ExLine.Webhook.Events do
  @moduledoc """
  Parsed webhook event structs.

  High-frequency events are modelled as distinct structs (so routers can pattern
  match on them); any other event type degrades to `ExLine.Webhook.UnknownEvent` so a
  new LINE event type never breaks parsing. Every struct carries the original `raw`
  map plus the common envelope (`type`/`mode`/`timestamp`/`source`/`webhook_event_id`/
  `delivery_context`).

  Ref: https://developers.line.biz/en/reference/messaging-api/#webhook-event-objects
  """
end

defmodule ExLine.Webhook.MessageEvent do
  @moduledoc "A user sent a message. `message` is an `ExLine.Webhook.Message` struct."
  defstruct [
    :type,
    :mode,
    :timestamp,
    :source,
    :webhook_event_id,
    :delivery_context,
    :reply_token,
    :message,
    :raw
  ]

  @type t :: %__MODULE__{}
end

defmodule ExLine.Webhook.PostbackEvent do
  @moduledoc "A postback action fired. `postback` is `%{data: ..., params: ...}`."
  defstruct [
    :type,
    :mode,
    :timestamp,
    :source,
    :webhook_event_id,
    :delivery_context,
    :reply_token,
    :postback,
    :raw
  ]

  @type t :: %__MODULE__{}
end

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

defmodule ExLine.Webhook.UnfollowEvent do
  @moduledoc "A user blocked the bot."
  defstruct [:type, :mode, :timestamp, :source, :webhook_event_id, :delivery_context, :raw]

  @type t :: %__MODULE__{}
end

defmodule ExLine.Webhook.JoinEvent do
  @moduledoc "The bot joined a group or room."
  defstruct [
    :type,
    :mode,
    :timestamp,
    :source,
    :webhook_event_id,
    :delivery_context,
    :reply_token,
    :raw
  ]

  @type t :: %__MODULE__{}
end

defmodule ExLine.Webhook.LeaveEvent do
  @moduledoc "The bot was removed from a group or room."
  defstruct [:type, :mode, :timestamp, :source, :webhook_event_id, :delivery_context, :raw]

  @type t :: %__MODULE__{}
end

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

defmodule ExLine.Webhook.MemberLeftEvent do
  @moduledoc "A user left a group/room the bot is in. `left` is `%{members: [Source]}`."
  defstruct [:type, :mode, :timestamp, :source, :webhook_event_id, :delivery_context, :left, :raw]

  @type t :: %__MODULE__{}
end

defmodule ExLine.Webhook.UnknownEvent do
  @moduledoc """
  Fallback for an event type ExLine does not model (a long-tail or newly added type).

  The common envelope is still parsed; the full payload is in `raw`.
  """
  defstruct [:type, :mode, :timestamp, :source, :webhook_event_id, :delivery_context, :raw]

  @type t :: %__MODULE__{}
end
