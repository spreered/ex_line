defmodule ExLine.Api.Membership do
  @moduledoc """
  LINE Official Account membership (paid subscription) information.

  Ref: https://developers.line.biz/en/docs/messaging-api/membership/
  """

  alias ExLine.{Client, Error}

  @doc """
  Gets the list of membership plans on the account.

  Returns `{:ok, %{"memberships" => [...]}}`.

  Ref: https://developers.line.biz/en/reference/messaging-api/#get-membership-plans
  """
  @spec list(Client.t()) :: {:ok, map()} | {:error, Error.t()}
  def list(client) do
    client
    |> Client.request(method: :get, path: "/v2/bot/membership/list")
    |> Client.decode()
  end

  @doc """
  Gets a user's membership subscription status.

  Ref: https://developers.line.biz/en/reference/messaging-api/#get-a-users-membership-subscription-status
  """
  @spec subscription(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def subscription(client, user_id) do
    client
    |> Client.request(method: :get, path: "/v2/bot/membership/subscription/#{user_id}")
    |> Client.decode()
  end

  @doc """
  Gets the user IDs who joined the given `membership_id`.

  `opts[:start]` is the continuation token from a previous page; `opts[:limit]`
  caps the page size. Returns `{:ok, %{"memberUserIds" => [...], "next" => ...}}`.

  Ref: https://developers.line.biz/en/reference/messaging-api/#get-a-list-of-users-who-joined-the-membership
  """
  @spec joined_users(Client.t(), integer() | String.t(), keyword()) ::
          {:ok, map()} | {:error, Error.t()}
  def joined_users(client, membership_id, opts \\ []) do
    query =
      []
      |> maybe(:start, opts[:start])
      |> maybe(:limit, opts[:limit])

    client
    |> Client.request(
      method: :get,
      path: "/v2/bot/membership/#{membership_id}/users/ids",
      query: query
    )
    |> Client.decode()
  end

  defp maybe(query, _key, nil), do: query
  defp maybe(query, key, value), do: [{key, value} | query]
end
