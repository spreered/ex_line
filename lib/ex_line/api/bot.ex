defmodule ExLine.Api.Bot do
  @moduledoc """
  Information about the bot / LINE Official Account.

  Ref: https://developers.line.biz/en/reference/messaging-api/#get-bot-info
  """

  alias ExLine.{Client, Error}

  @doc """
  Gets the bot's info (userId, basicId, displayName, chatMode, markAsReadMode, ...).

  Ref: https://developers.line.biz/en/reference/messaging-api/#get-bot-info
  """
  @spec info(Client.t()) :: {:ok, map()} | {:error, Error.t()}
  def info(client) do
    client
    |> Client.request(method: :get, path: "/v2/bot/info")
    |> Client.decode()
  end
end
