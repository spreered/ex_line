defmodule ExLine.Webhook.Event.VideoPlayComplete do
  @moduledoc "A user finished playing a video message (with a tracking id)."
  defstruct [
    :type,
    :mode,
    :timestamp,
    :source,
    :webhook_event_id,
    :delivery_context,
    :reply_token,
    :video_play_complete,
    :raw
  ]

  @type t :: %__MODULE__{}
end
