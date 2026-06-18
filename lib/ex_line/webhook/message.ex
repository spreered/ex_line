defmodule ExLine.Webhook.Message do
  @moduledoc """
  Parses the message content of an `ExLine.Webhook.Event.Message`.

  Each content type is its own struct (`ExLine.Webhook.Message.Text`, `.Image`,
  `.Video`, `.Audio`, `.File`, `.Location`, `.Sticker`); an unrecognized content type
  degrades to `ExLine.Webhook.Message.Unknown` so a new LINE message type never breaks
  parsing. Every struct keeps the original `raw` map, so fields not yet modelled are
  still reachable.

  Ref: https://developers.line.biz/en/reference/messaging-api/#message-event
  """

  alias ExLine.Webhook.Message.{Audio, File, Image, Location, Sticker, Text, Unknown, Video}

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
