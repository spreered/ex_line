defmodule ExLine.ApiTest do
  @moduledoc "Mock-adapter tests for the read-oriented API modules."
  use ExUnit.Case, async: true

  import Mox

  alias ExLine.Api.{Bot, Content, Profile}
  alias ExLine.Client

  setup :verify_on_exit!

  defp client, do: Client.new(access_token: "tok", adapter: ExLine.AdapterMock)

  describe "ExLine.Api.Content" do
    test "get/2 hits the api-data host and returns raw bytes" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.method == :get
        assert req.url == "https://api-data.line.me/v2/bot/message/m1/content"
        {:ok, %{status: 200, body: <<1, 2, 3>>}}
      end)

      assert {:ok, <<1, 2, 3>>} = Content.get(client(), "m1")
    end

    test "preview/2 hits the preview path on api-data" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "https://api-data.line.me/v2/bot/message/m1/content/preview"
        {:ok, %{status: 200, body: <<9>>}}
      end)

      assert {:ok, <<9>>} = Content.preview(client(), "m1")
    end

    test "transcoding/2 returns the status map" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "https://api-data.line.me/v2/bot/message/m1/content/transcoding"
        {:ok, %{status: 200, body: %{"status" => "succeeded"}}}
      end)

      assert {:ok, %{"status" => "succeeded"}} = Content.transcoding(client(), "m1")
    end
  end

  describe "ExLine.Api.Profile" do
    test "get/2 fetches a user profile" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "https://api.line.me/v2/bot/profile/U1"
        {:ok, %{status: 200, body: %{"userId" => "U1", "displayName" => "A"}}}
      end)

      assert {:ok, %{"userId" => "U1"}} = Profile.get(client(), "U1")
    end

    test "followers/2 passes pagination params" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "https://api.line.me/v2/bot/followers/ids"
        assert {:limit, 100} in req.query
        assert {:start, "tok2"} in req.query
        {:ok, %{status: 200, body: %{"userIds" => []}}}
      end)

      assert {:ok, %{"userIds" => []}} = Profile.followers(client(), limit: 100, start: "tok2")
    end
  end

  describe "ExLine.Api.Bot" do
    test "info/1 fetches bot info" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "https://api.line.me/v2/bot/info"
        {:ok, %{status: 200, body: %{"userId" => "U", "displayName" => "Bot"}}}
      end)

      assert {:ok, %{"displayName" => "Bot"}} = Bot.info(client())
    end
  end
end
