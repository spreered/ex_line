defmodule ExLine.Webhook.Message.Sticker do
  @moduledoc "Sticker message content."
  defstruct [
    :id,
    :package_id,
    :sticker_id,
    :sticker_resource_type,
    :keywords,
    :text,
    :quote_token,
    :quoted_message_id,
    :mark_as_read_token,
    :raw
  ]

  @type t :: %__MODULE__{}
end
