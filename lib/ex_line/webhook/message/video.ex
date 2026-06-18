defmodule ExLine.Webhook.Message.Video do
  @moduledoc "Video message content."
  defstruct [:id, :duration, :content_provider, :quote_token, :mark_as_read_token, :raw]
  @type t :: %__MODULE__{}
end
