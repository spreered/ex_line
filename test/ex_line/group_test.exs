defmodule ExLine.GroupTest do
  use ExUnit.Case, async: true

  import Mox

  alias ExLine.Api.Group
  alias ExLine.Client

  setup :verify_on_exit!

  defp client, do: Client.new(access_token: "tok", adapter: ExLine.AdapterMock)
  @api "https://api.line.me"

  defp expect_get(url, response \\ %{}) do
    expect(ExLine.AdapterMock, :request, fn req ->
      assert req.method == :get
      assert req.url == url
      {:ok, %{status: 200, body: response}}
    end)
  end

  test "group endpoints hit the right paths" do
    expect_get("#{@api}/v2/bot/group/G1/summary")
    assert {:ok, _} = Group.group_summary(client(), "G1")

    expect_get("#{@api}/v2/bot/group/G1/members/count")
    assert {:ok, _} = Group.group_member_count(client(), "G1")

    expect_get("#{@api}/v2/bot/group/G1/member/U1")
    assert {:ok, _} = Group.group_member_profile(client(), "G1", "U1")

    expect(ExLine.AdapterMock, :request, fn req ->
      assert req.method == :post
      assert req.url == "#{@api}/v2/bot/group/G1/leave"
      {:ok, %{status: 200, body: ""}}
    end)

    assert {:ok, _} = Group.leave_group(client(), "G1")
  end

  test "member_ids passes the start continuation token" do
    expect(ExLine.AdapterMock, :request, fn req ->
      assert req.url == "#{@api}/v2/bot/group/G1/members/ids"
      assert {:start, "tok2"} in req.query
      {:ok, %{status: 200, body: %{"memberIds" => []}}}
    end)

    Group.group_member_ids(client(), "G1", start: "tok2")
  end

  test "room endpoints hit the right paths" do
    expect_get("#{@api}/v2/bot/room/R1/members/count")
    assert {:ok, _} = Group.room_member_count(client(), "R1")

    expect_get("#{@api}/v2/bot/room/R1/member/U1")
    assert {:ok, _} = Group.room_member_profile(client(), "R1", "U1")

    expect_get("#{@api}/v2/bot/room/R1/members/ids")
    assert {:ok, _} = Group.room_member_ids(client(), "R1")

    expect(ExLine.AdapterMock, :request, fn req ->
      assert req.url == "#{@api}/v2/bot/room/R1/leave"
      {:ok, %{status: 200, body: ""}}
    end)

    assert {:ok, _} = Group.leave_room(client(), "R1")
  end
end
