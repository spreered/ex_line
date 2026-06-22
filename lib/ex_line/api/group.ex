defmodule ExLine.Api.Group do
  @moduledoc """
  Group and multi-person room APIs: summary, member counts/ids/profiles, and leaving.

  (Rooms have no summary endpoint.) Member-id listing is paginated via `opts[:start]`
  (a continuation token returned as `"next"`).

  Ref: https://developers.line.biz/en/reference/messaging-api/#get-group-summary
  """

  alias ExLine.{Client, Error}

  # ── Group ────────────────────────────────────────────────────────────────────

  @doc "Group summary (name, picture). Ref: #get-group-summary"
  @spec group_summary(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def group_summary(client, group_id) do
    client
    |> Client.request(method: :get, path: "/v2/bot/group/#{group_id}/summary")
    |> Client.decode()
  end

  @doc "Number of members in a group. Ref: #get-members-group-count"
  @spec group_member_count(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def group_member_count(client, group_id) do
    client
    |> Client.request(method: :get, path: "/v2/bot/group/#{group_id}/members/count")
    |> Client.decode()
  end

  @doc "User ids of group members (paginated via `opts[:start]`). Ref: #get-group-member-user-ids"
  @spec group_member_ids(Client.t(), String.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def group_member_ids(client, group_id, opts \\ []) do
    client
    |> Client.request(
      method: :get,
      path: "/v2/bot/group/#{group_id}/members/ids",
      query: start_query(opts)
    )
    |> Client.decode()
  end

  @doc "Profile of a group member. Ref: #get-group-member-profile"
  @spec group_member_profile(Client.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Error.t()}
  def group_member_profile(client, group_id, user_id) do
    client
    |> Client.request(method: :get, path: "/v2/bot/group/#{group_id}/member/#{user_id}")
    |> Client.decode()
  end

  @doc "Leaves a group. Ref: #leave-group"
  @spec leave_group(Client.t(), String.t()) :: {:ok, term()} | {:error, Error.t()}
  def leave_group(client, group_id) do
    client
    |> Client.request(method: :post, path: "/v2/bot/group/#{group_id}/leave")
    |> Client.decode()
  end

  # ── Room ─────────────────────────────────────────────────────────────────────

  @doc "Number of members in a room. Ref: #get-members-room-count"
  @spec room_member_count(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def room_member_count(client, room_id) do
    client
    |> Client.request(method: :get, path: "/v2/bot/room/#{room_id}/members/count")
    |> Client.decode()
  end

  @doc "User ids of room members (paginated via `opts[:start]`). Ref: #get-room-member-user-ids"
  @spec room_member_ids(Client.t(), String.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def room_member_ids(client, room_id, opts \\ []) do
    client
    |> Client.request(
      method: :get,
      path: "/v2/bot/room/#{room_id}/members/ids",
      query: start_query(opts)
    )
    |> Client.decode()
  end

  @doc "Profile of a room member. Ref: #get-room-member-profile"
  @spec room_member_profile(Client.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Error.t()}
  def room_member_profile(client, room_id, user_id) do
    client
    |> Client.request(method: :get, path: "/v2/bot/room/#{room_id}/member/#{user_id}")
    |> Client.decode()
  end

  @doc "Leaves a room. Ref: #leave-room"
  @spec leave_room(Client.t(), String.t()) :: {:ok, term()} | {:error, Error.t()}
  def leave_room(client, room_id) do
    client
    |> Client.request(method: :post, path: "/v2/bot/room/#{room_id}/leave")
    |> Client.decode()
  end

  defp start_query(opts) do
    case opts[:start] do
      nil -> []
      start -> [start: start]
    end
  end
end
