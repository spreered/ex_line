defmodule ExLine.MessagingTest do
  use ExUnit.Case, async: true

  import Mox
  import ExLine.Conformance

  alias ExLine.{Client, Error, Message}
  alias ExLine.Api.Messaging

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
      # apply/3 defeats the compile-time type check so we can assert the runtime guard.
      assert_raise FunctionClauseError, fn ->
        apply(Messaging, :multicast, [client(), "U1", Message.text("hi")])
      end
    end
  end

  describe "quota / count / loading" do
    test "quota/1 GETs the quota endpoint" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.method == :get
        assert req.url == "https://api.line.me/v2/bot/message/quota"
        {:ok, %{status: 200, body: %{"type" => "limited", "value" => 500}}}
      end)

      assert {:ok, %{"type" => "limited"}} = Messaging.quota(client())
    end

    test "quota_consumption/1 GETs consumption" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "https://api.line.me/v2/bot/message/quota/consumption"
        {:ok, %{status: 200, body: %{"totalUsage" => 42}}}
      end)

      assert {:ok, %{"totalUsage" => 42}} = Messaging.quota_consumption(client())
    end

    test "sent_count/3 hits the delivery endpoint with date" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "https://api.line.me/v2/bot/message/delivery/push"
        assert {:date, "20260101"} in req.query
        {:ok, %{status: 200, body: %{"status" => "ready", "success" => 10}}}
      end)

      assert {:ok, %{"success" => 10}} = Messaging.sent_count(client(), :push, "20260101")
    end

    test "display_loading_animation/3 POSTs chatId + loadingSeconds" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.method == :post
        assert req.url == "https://api.line.me/v2/bot/chat/loading/start"
        assert req.body == %{chatId: "U1", loadingSeconds: 10}
        {:ok, %{status: 202, body: %{}}}
      end)

      assert {:ok, %{}} = Messaging.display_loading_animation(client(), "U1", 10)
    end
  end

  describe "broadcast / narrowcast" do
    test "broadcast/3 posts to the broadcast endpoint without a recipient" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "https://api.line.me/v2/bot/message/broadcast"
        assert req.body == %{messages: [%{type: "text", text: "hi"}]}
        {:ok, %{status: 200, body: %{}}}
      end)

      assert {:ok, %{}} = Messaging.broadcast(client(), Message.text("hi"))
    end

    test "narrowcast/3 returns the request id from the X-Line-Request-Id header (202)" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "https://api.line.me/v2/bot/message/narrowcast"
        {:ok, %{status: 202, body: %{}, headers: %{"x-line-request-id" => ["req-123"]}}}
      end)

      assert {:ok, "req-123"} = Messaging.narrowcast(client(), Message.text("hi"))
    end

    test "narrowcast/3 includes recipient/filter/limit when given" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.body.recipient == %{type: "audience", audienceGroupId: 1}
        assert req.body.limit == %{max: 100}
        {:ok, %{status: 202, body: %{}, headers: %{"x-line-request-id" => ["r"]}}}
      end)

      Messaging.narrowcast(client(), Message.text("hi"),
        recipient: %{type: "audience", audienceGroupId: 1},
        limit: %{max: 100}
      )
    end

    test "narrowcast_progress/2 GETs the progress endpoint with requestId" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.method == :get
        assert req.url == "https://api.line.me/v2/bot/message/progress/narrowcast"
        assert {:requestId, "req-123"} in req.query
        {:ok, %{status: 200, body: %{"phase" => "succeeded", "successCount" => 10}}}
      end)

      assert {:ok, %{"phase" => "succeeded"}} = Messaging.narrowcast_progress(client(), "req-123")
    end
  end

  describe "validate / mark-as-read / push-by-phone" do
    test "validate/4 posts to the validate path for the kind" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "https://api.line.me/v2/bot/message/validate/push"
        assert req.body == %{messages: [%{type: "text", text: "hi"}]}
        {:ok, %{status: 200, body: ""}}
      end)

      assert {:ok, _} = Messaging.validate(client(), :push, Message.text("hi"))
    end

    test "mark_as_read/2 (partner) posts a chat reference" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "https://api.line.me/v2/bot/message/markAsRead"
        assert req.body == %{chat: %{userId: "U1"}}
        {:ok, %{status: 200, body: ""}}
      end)

      assert {:ok, _} = Messaging.mark_as_read(client(), "U1")
    end

    test "mark_as_read_by_token/2 posts the token" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "https://api.line.me/v2/bot/chat/markAsRead"
        assert req.body == %{markAsReadToken: "tok-1"}
        {:ok, %{status: 200, body: ""}}
      end)

      assert {:ok, _} = Messaging.mark_as_read_by_token(client(), "tok-1")
    end

    test "push_by_phone/4 (PNP) posts to /bot/pnp/push" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "https://api.line.me/bot/pnp/push"
        assert req.body == %{to: "phone-hash", messages: [%{type: "text", text: "hi"}]}
        {:ok, %{status: 200, body: %{}}}
      end)

      assert {:ok, _} = Messaging.push_by_phone(client(), "phone-hash", Message.text("hi"))
    end
  end

  # Conformance of the request envelopes against LINE's official OpenAPI spec.
  describe "conformance" do
    @describetag :conformance

    test "validate request → ValidateMessageRequest" do
      assert_conforms(%{messages: [Message.text("hi")]}, "ValidateMessageRequest")
    end

    test "pnp request → PnpMessagesRequest" do
      assert_conforms(%{to: "phone-hash", messages: [Message.text("hi")]}, "PnpMessagesRequest")
    end

    test "reply request → ReplyMessageRequest" do
      assert_conforms(%{replyToken: "rt", messages: [Message.text("hi")]}, "ReplyMessageRequest")
    end

    test "broadcast request → BroadcastRequest" do
      assert_conforms(%{messages: [Message.text("hi")]}, "BroadcastRequest")
    end

    test "narrowcast request → NarrowcastRequest" do
      body = %{
        messages: [Message.text("hi")],
        recipient: %{type: "audience", audienceGroupId: 1},
        limit: %{max: 100}
      }

      assert_conforms(body, "NarrowcastRequest")
    end

    test "push request → PushMessageRequest" do
      assert_conforms(%{to: "U1", messages: [Message.text("hi")]}, "PushMessageRequest")
    end

    test "push request with notificationDisabled → PushMessageRequest" do
      body = %{to: "U1", messages: [Message.text("hi")], notificationDisabled: true}
      assert_conforms(body, "PushMessageRequest")
    end

    test "multicast request → MulticastRequest" do
      assert_conforms(%{to: ["U1", "U2"], messages: [Message.text("hi")]}, "MulticastRequest")
    end
  end
end
