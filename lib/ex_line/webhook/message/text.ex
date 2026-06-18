defmodule ExLine.Webhook.Message.Text do
  @moduledoc "Text message content (`ExLine.Webhook.MessageEvent`)."
  defstruct [
    :id,
    :text,
    :emojis,
    :mention,
    :quote_token,
    :quoted_message_id,
    :mark_as_read_token,
    :raw
  ]

  @type t :: %__MODULE__{}
end
