defmodule ExLine.Webhook.MembershipEvent do
  @moduledoc "A change to a user's paid membership for the account."
  defstruct [
    :type,
    :mode,
    :timestamp,
    :source,
    :webhook_event_id,
    :delivery_context,
    :reply_token,
    :membership,
    :raw
  ]

  @type t :: %__MODULE__{}
end
