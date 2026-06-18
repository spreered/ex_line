defmodule ExLine.Webhook.Message.Unknown do
  @moduledoc "Fallback for an unrecognized message content type."
  defstruct [:type, :id, :raw]
  @type t :: %__MODULE__{}
end
