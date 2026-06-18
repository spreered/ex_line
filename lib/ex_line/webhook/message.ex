defmodule ExLine.Webhook.Message do
  @moduledoc """
  Parsed message content of a `ExLine.Webhook.MessageEvent`.

  Each content type is its own struct (`Text`, `Image`, `Video`, `Audio`, `File`,
  `Location`, `Sticker`); an unrecognized content type degrades to `Unknown` so a new
  LINE message type never breaks parsing. Every struct keeps the original `raw` map,
  so fields not yet modelled are still reachable.

  Ref: https://developers.line.biz/en/reference/messaging-api/#message-event
  """

  defmodule Text do
    @moduledoc "Text message content."
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

  defmodule Image do
    @moduledoc "Image message content."
    defstruct [:id, :content_provider, :image_set, :quote_token, :mark_as_read_token, :raw]
    @type t :: %__MODULE__{}
  end

  defmodule Video do
    @moduledoc "Video message content."
    defstruct [:id, :duration, :content_provider, :quote_token, :mark_as_read_token, :raw]
    @type t :: %__MODULE__{}
  end

  defmodule Audio do
    @moduledoc "Audio message content."
    defstruct [:id, :duration, :content_provider, :mark_as_read_token, :raw]
    @type t :: %__MODULE__{}
  end

  defmodule File do
    @moduledoc "File message content."
    defstruct [:id, :file_name, :file_size, :mark_as_read_token, :raw]
    @type t :: %__MODULE__{}
  end

  defmodule Location do
    @moduledoc "Location message content."
    defstruct [:id, :title, :address, :latitude, :longitude, :mark_as_read_token, :raw]
    @type t :: %__MODULE__{}
  end

  defmodule Sticker do
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

  defmodule Unknown do
    @moduledoc "Fallback for an unrecognized message content type."
    defstruct [:type, :id, :raw]
    @type t :: %__MODULE__{}
  end

  @doc false
  def parse(%{"type" => "text"} = m) do
    %Text{
      id: m["id"],
      text: m["text"],
      emojis: m["emojis"],
      mention: m["mention"],
      quote_token: m["quoteToken"],
      quoted_message_id: m["quotedMessageId"],
      mark_as_read_token: m["markAsReadToken"],
      raw: m
    }
  end

  def parse(%{"type" => "image"} = m) do
    %Image{
      id: m["id"],
      content_provider: m["contentProvider"],
      image_set: m["imageSet"],
      quote_token: m["quoteToken"],
      mark_as_read_token: m["markAsReadToken"],
      raw: m
    }
  end

  def parse(%{"type" => "video"} = m) do
    %Video{
      id: m["id"],
      duration: m["duration"],
      content_provider: m["contentProvider"],
      quote_token: m["quoteToken"],
      mark_as_read_token: m["markAsReadToken"],
      raw: m
    }
  end

  def parse(%{"type" => "audio"} = m) do
    %Audio{
      id: m["id"],
      duration: m["duration"],
      content_provider: m["contentProvider"],
      mark_as_read_token: m["markAsReadToken"],
      raw: m
    }
  end

  def parse(%{"type" => "file"} = m) do
    %File{
      id: m["id"],
      file_name: m["fileName"],
      file_size: m["fileSize"],
      mark_as_read_token: m["markAsReadToken"],
      raw: m
    }
  end

  def parse(%{"type" => "location"} = m) do
    %Location{
      id: m["id"],
      title: m["title"],
      address: m["address"],
      latitude: m["latitude"],
      longitude: m["longitude"],
      mark_as_read_token: m["markAsReadToken"],
      raw: m
    }
  end

  def parse(%{"type" => "sticker"} = m) do
    %Sticker{
      id: m["id"],
      package_id: m["packageId"],
      sticker_id: m["stickerId"],
      sticker_resource_type: m["stickerResourceType"],
      keywords: m["keywords"],
      text: m["text"],
      quote_token: m["quoteToken"],
      quoted_message_id: m["quotedMessageId"],
      mark_as_read_token: m["markAsReadToken"],
      raw: m
    }
  end

  def parse(%{"type" => type} = m), do: %Unknown{type: type, id: m["id"], raw: m}
  def parse(_), do: nil
end
