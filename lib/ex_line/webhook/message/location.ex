defmodule ExLine.Webhook.Message.Location do
  @moduledoc "Location message content."
  defstruct [:id, :title, :address, :latitude, :longitude, :mark_as_read_token, :raw]
  @type t :: %__MODULE__{}
end
