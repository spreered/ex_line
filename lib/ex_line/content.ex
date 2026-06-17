defmodule ExLine.Content do
  @moduledoc """
  Download media that users sent (image/video/audio/file) and check its status.

  These endpoints live on the `api-data.line.me` host, so requests use the client's
  `:data` host. `get/2` and `preview/2` return the raw binary body; `transcoding/2`
  returns a JSON status map.

  Ref: https://developers.line.biz/en/reference/messaging-api/#get-content
  """

  alias ExLine.{Client, Error}

  @doc """
  Downloads the content of a message (image/video/audio/file). Returns the raw bytes.

  Ref: https://developers.line.biz/en/reference/messaging-api/#get-content
  """
  @spec get(Client.t(), String.t()) :: {:ok, binary()} | {:error, Error.t()}
  def get(client, message_id) do
    client
    |> Client.request(method: :get, host: :data, path: "/v2/bot/message/#{message_id}/content")
    |> Client.decode()
  end

  @doc """
  Downloads a preview image of a message's content.

  Ref: https://developers.line.biz/en/reference/messaging-api/#get-image-or-video-preview
  """
  @spec preview(Client.t(), String.t()) :: {:ok, binary()} | {:error, Error.t()}
  def preview(client, message_id) do
    client
    |> Client.request(
      method: :get,
      host: :data,
      path: "/v2/bot/message/#{message_id}/content/preview"
    )
    |> Client.decode()
  end

  @doc """
  Gets the transcoding (preparation) status of a message's content.

  Ref: https://developers.line.biz/en/reference/messaging-api/#verify-video-or-audio-preparation-status
  """
  @spec transcoding(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def transcoding(client, message_id) do
    client
    |> Client.request(
      method: :get,
      host: :data,
      path: "/v2/bot/message/#{message_id}/content/transcoding"
    )
    |> Client.decode()
  end
end
