defmodule ExLine.Webhook.Message.Image do
  @moduledoc "Image message content."
  defstruct [:id, :content_provider, :image_set, :quote_token, :mark_as_read_token, :raw]
  @type t :: %__MODULE__{}
end
