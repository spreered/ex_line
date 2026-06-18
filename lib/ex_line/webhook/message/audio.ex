defmodule ExLine.Webhook.Message.Audio do
  @moduledoc "Audio message content."
  defstruct [:id, :duration, :content_provider, :mark_as_read_token, :raw]
  @type t :: %__MODULE__{}
end
