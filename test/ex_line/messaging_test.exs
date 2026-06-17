defmodule ExLine.MessagingTest do
  use ExUnit.Case, async: true

  import Mox

  alias ExLine.{Client, Error, Message, Messaging}

  setup :verify_on_exit!

  defp client, do: Client.new(access_token: "tok", adapter: ExLine.AdapterMock)

  describe "reply/4" do
    test "posts to the reply endpoint with the right body and auth header" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.method == :post
        assert req.url == "https://api.line.me/v2/bot/message/reply"
        assert req.body == %{replyToken: "rt", messages: [%{type: "text", text: "hi"}]}
        assert {"authorization", "Bearer tok"} in req.headers
        {:ok, %{status: 200, body: %{"sentMessages" => []}}}
      end)

      assert {:ok, %{"sentMessages" => []}} =
               Messaging.reply(client(), "rt", Message.text("hi"))
    end

    test "wraps a single message into a list" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert is_list(req.body.messages)
        {:ok, %{status: 200, body: %{}}}
      end)

      Messaging.reply(client(), "rt", Message.text("hi"))
    end
  end

  describe "push/4" do
    test "posts to the push endpoint" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "https://api.line.me/v2/bot/message/push"
        assert req.body == %{to: "U1", messages: [%{type: "text", text: "hi"}]}
        refute Enum.any?(req.headers, fn {k, _} -> k == "x-line-retry-key" end)
        {:ok, %{status: 200, body: %{}}}
      end)

      assert {:ok, %{}} = Messaging.push(client(), "U1", Message.text("hi"))
    end

    test "sends X-Line-Retry-Key header when retry_key given" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert {"x-line-retry-key", "uuid-1"} in req.headers
        {:ok, %{status: 200, body: %{}}}
      end)

      Messaging.push(client(), "U1", Message.text("hi"), retry_key: "uuid-1")
    end

    test "409 (deduplicated retry) is treated as success" do
      expect(ExLine.AdapterMock, :request, fn _req -> {:ok, %{status: 409, body: %{}}} end)
      assert {:ok, %{}} = Messaging.push(client(), "U1", Message.text("hi"))
    end

    test "429 maps to quota_exceeded error" do
      expect(ExLine.AdapterMock, :request, fn _req -> {:ok, %{status: 429, body: %{}}} end)

      assert {:error, %Error{kind: :quota_exceeded}} =
               Messaging.push(client(), "U1", Message.text("hi"))
    end

    test "5xx maps to transient error" do
      expect(ExLine.AdapterMock, :request, fn _req -> {:ok, %{status: 503, body: %{}}} end)

      assert {:error, %Error{kind: :transient, status: 503}} =
               Messaging.push(client(), "U1", Message.text("hi"))
    end

    test "transport failure surfaces as a network error" do
      expect(ExLine.AdapterMock, :request, fn _req -> {:error, Error.network(:closed)} end)
      assert {:error, %Error{kind: :network}} = Messaging.push(client(), "U1", Message.text("hi"))
    end

    test "notification_disabled adds the flag to the body" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.body.notificationDisabled == true
        {:ok, %{status: 200, body: %{}}}
      end)

      Messaging.push(client(), "U1", Message.text("hi"), notification_disabled: true)
    end
  end

  describe "multicast/4" do
    test "posts to the multicast endpoint with a list of recipients" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "https://api.line.me/v2/bot/message/multicast"
        assert req.body == %{to: ["U1", "U2"], messages: [%{type: "text", text: "hi"}]}
        {:ok, %{status: 200, body: %{}}}
      end)

      assert {:ok, %{}} = Messaging.multicast(client(), ["U1", "U2"], Message.text("hi"))
    end

    test "sends X-Line-Retry-Key when given and treats 409 as success" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert {"x-line-retry-key", "uuid-2"} in req.headers
        {:ok, %{status: 409, body: %{}}}
      end)

      assert {:ok, %{}} =
               Messaging.multicast(client(), ["U1"], Message.text("hi"), retry_key: "uuid-2")
    end

    test "429 maps to quota_exceeded" do
      expect(ExLine.AdapterMock, :request, fn _req -> {:ok, %{status: 429, body: %{}}} end)

      assert {:error, %Error{kind: :quota_exceeded}} =
               Messaging.multicast(client(), ["U1"], Message.text("hi"))
    end

    test "requires a list of recipients" do
      assert_raise FunctionClauseError, fn ->
        Messaging.multicast(client(), "U1", Message.text("hi"))
      end
    end
  end
end
