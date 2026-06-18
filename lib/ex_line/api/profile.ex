defmodule ExLine.Api.Profile do
  @moduledoc """
  Fetch user profiles and follower IDs via the Messaging API.

  Note: this is the **Messaging API** profile (`/v2/bot/profile/{userId}`), distinct
  from the LINE Login profile used in LIFF flows.

  Ref: https://developers.line.biz/en/reference/messaging-api/#get-profile
  """

  alias ExLine.{Client, Error}

  @doc """
  Gets a user's profile (displayName, userId, pictureUrl, statusMessage, language).

  Ref: https://developers.line.biz/en/reference/messaging-api/#get-profile
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def get(client, user_id) do
    client
    |> Client.request(method: :get, path: "/v2/bot/profile/#{user_id}")
    |> Client.decode()
  end

  @doc """
  Gets user IDs of users who added the bot as a friend (paginated).

  Options: `:limit` (max 1000), `:start` (continuation token).

  Ref: https://developers.line.biz/en/reference/messaging-api/#get-follower-ids
  """
  @spec followers(Client.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def followers(client, opts \\ []) do
    query =
      []
      |> maybe_param(:limit, opts[:limit])
      |> maybe_param(:start, opts[:start])

    client
    |> Client.request(method: :get, path: "/v2/bot/followers/ids", query: query)
    |> Client.decode()
  end

  defp maybe_param(query, _key, nil), do: query
  defp maybe_param(query, key, value), do: [{key, value} | query]
end
