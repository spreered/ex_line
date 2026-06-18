defmodule ExLine.Webhook.Message.File do
  @moduledoc "File message content."
  defstruct [:id, :file_name, :file_size, :mark_as_read_token, :raw]
  @type t :: %__MODULE__{}
end
