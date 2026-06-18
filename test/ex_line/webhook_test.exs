defmodule ExLine.WebhookTest do
  use ExUnit.Case, async: true

  import ExLine.Conformance

  alias ExLine.Webhook
  alias ExLine.Webhook.{FollowEvent, MessageEvent, PostbackEvent, Source, UnknownEvent}
  alias ExLine.Webhook.Message

  # A realistic webhook payload (shape from a real LINE delivery).
  @callback_request %{
    "destination" => "U6530ef1cde6cd27462f60bdcb43bfd13",
    "events" => [
      %{
        "type" => "message",
        "mode" => "active",
        "timestamp" => 1_732_783_608_322,
        "source" => %{"type" => "user", "userId" => "Ub1aa80a72fcb226a35acbef3188dff89"},
        "replyToken" => "c9af99042d37482eba79ad00aac170ad",
        "webhookEventId" => "01JDRZ74J283628H97Z0B9B02Z",
        "deliveryContext" => %{"isRedelivery" => false},
        "message" => %{
          "id" => "536790891910660261",
          "type" => "text",
          "text" => "你好",
          "quoteToken" => "qt"
        }
      }
    ]
  }

  describe "parse/1" do
    test "parses a message event with source and content" do
      assert [event] = Webhook.parse(@callback_request)
      assert %MessageEvent{} = event
      assert event.reply_token == "c9af99042d37482eba79ad00aac170ad"
      assert event.webhook_event_id == "01JDRZ74J283628H97Z0B9B02Z"
      assert %Source{type: "user", user_id: "Ub1aa80a72fcb226a35acbef3188dff89"} = event.source

      assert %Message.Text{text: "你好", quote_token: "qt", id: "536790891910660261"} =
               event.message
    end

    test "keeps the raw map on the event and message" do
      [event] = Webhook.parse(@callback_request)
      assert event.raw["type"] == "message"
      assert event.message.raw["text"] == "你好"
    end

    test "parses postback data and params" do
      raw = %{
        "type" => "postback",
        "postback" => %{"data" => "a=1", "params" => %{"date" => "2026-01-01"}}
      }

      assert %PostbackEvent{postback: %{data: "a=1", params: %{"date" => "2026-01-01"}}} =
               Webhook.parse_event(raw)
    end

    test "parses follow event" do
      assert %FollowEvent{reply_token: "r"} =
               Webhook.parse_event(%{"type" => "follow", "replyToken" => "r"})
    end

    test "parses group/room sources" do
      assert %Source{type: "group", group_id: "G1"} =
               Webhook.parse_event(%{
                 "type" => "leave",
                 "source" => %{"type" => "group", "groupId" => "G1"}
               }).source
    end
  end

  describe "parse/1 is total (forward compatibility)" do
    test "unknown event type → UnknownEvent (keeps envelope + raw)" do
      raw = %{"type" => "things", "things" => %{"x" => 1}, "mode" => "active"}
      assert %UnknownEvent{type: "things", mode: "active", raw: ^raw} = Webhook.parse_event(raw)
    end

    test "unknown message content type → Message.Unknown" do
      raw = %{"type" => "message", "message" => %{"type" => "flexish", "id" => "1"}}

      assert %MessageEvent{message: %Message.Unknown{type: "flexish", id: "1"}} =
               Webhook.parse_event(raw)
    end

    test "malformed event does not raise" do
      assert %UnknownEvent{type: nil} = Webhook.parse_event(%{"no" => "type"})
      assert %UnknownEvent{type: nil} = Webhook.parse_event("not a map")
    end

    test "one bad event does not fail the batch" do
      body = %{
        "events" => [
          %{"type" => "follow"},
          "garbage",
          %{"type" => "message", "message" => %{"type" => "text", "text" => "hi"}}
        ]
      }

      assert [%FollowEvent{}, %UnknownEvent{}, %MessageEvent{}] = Webhook.parse(body)
    end

    test "non-webhook input returns []" do
      assert Webhook.parse(%{"foo" => "bar"}) == []
    end
  end

  describe "parse/1 additional event types" do
    @additional_events [
      {%{"type" => "unsend", "unsend" => %{"messageId" => "m"}}, Webhook.UnsendEvent},
      {%{"type" => "videoPlayComplete", "videoPlayComplete" => %{"trackingId" => "t"}},
       Webhook.VideoPlayCompleteEvent},
      {%{"type" => "beacon", "beacon" => %{"hwid" => "h"}}, Webhook.BeaconEvent},
      {%{"type" => "accountLink", "link" => %{"result" => "ok", "nonce" => "n"}},
       Webhook.AccountLinkEvent},
      {%{"type" => "membership", "membership" => %{"membershipId" => 1}},
       Webhook.MembershipEvent},
      {%{"type" => "activated", "chatControl" => %{"expireAt" => 1}}, Webhook.ActivatedEvent},
      {%{"type" => "deactivated"}, Webhook.DeactivatedEvent},
      {%{"type" => "botSuspended"}, Webhook.BotSuspendedEvent},
      {%{"type" => "botResumed"}, Webhook.BotResumedEvent},
      {%{"type" => "module", "module" => %{"type" => "attached"}}, Webhook.ModuleEvent},
      {%{"type" => "delivery", "delivery" => %{"data" => "d"}},
       Webhook.PnpDeliveryCompletionEvent}
    ]

    test "each additional event type parses to its own struct, keeping raw" do
      for {raw, mod} <- @additional_events do
        event = Webhook.parse_event(raw)
        assert event.__struct__ == mod
        assert event.raw == raw
      end
    end

    test "payload fields are mapped" do
      assert %Webhook.UnsendEvent{unsend: %{"messageId" => "m"}} =
               Webhook.parse_event(%{"type" => "unsend", "unsend" => %{"messageId" => "m"}})

      assert %Webhook.BeaconEvent{beacon: %{"hwid" => "h"}} =
               Webhook.parse_event(%{"type" => "beacon", "beacon" => %{"hwid" => "h"}})
    end
  end

  describe "conformance" do
    @describetag :conformance

    test "sample payload conforms to CallbackRequest (it's what LINE sends)" do
      assert_conforms(@callback_request, "CallbackRequest")
    end
  end
end
