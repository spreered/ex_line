defmodule ExLine.WebhookFieldsTest do
  @moduledoc """
  Field-completeness: a maximal instance generated from webhook.yml is parsed and
  every spec field must land in a non-nil struct field (see `ExLine.Conformance`).
  """
  use ExUnit.Case, async: true

  import ExLine.Conformance

  alias ExLine.Webhook
  alias ExLine.Webhook.Message

  @content [
    {"TextMessageContent", "text"},
    {"ImageMessageContent", "image"},
    {"VideoMessageContent", "video"},
    {"AudioMessageContent", "audio"},
    {"FileMessageContent", "file"},
    {"LocationMessageContent", "location"},
    {"StickerMessageContent", "sticker"}
  ]

  @events [
    {"MessageEvent", "message"},
    {"PostbackEvent", "postback"},
    {"FollowEvent", "follow"},
    {"UnfollowEvent", "unfollow"},
    {"JoinEvent", "join"},
    {"LeaveEvent", "leave"},
    {"MemberJoinedEvent", "memberJoined"},
    {"MemberLeftEvent", "memberLeft"},
    {"UnsendEvent", "unsend"},
    {"VideoPlayCompleteEvent", "videoPlayComplete"},
    {"BeaconEvent", "beacon"},
    {"AccountLinkEvent", "accountLink"},
    {"MembershipEvent", "membership"}
  ]

  describe "conformance" do
    @describetag :conformance

    for {schema, type} <- @content do
      test "message content #{schema} captures all spec fields" do
        assert_fields_covered(unquote(schema), unquote(type), &Message.parse/1)
      end
    end

    for {schema, type} <- @events do
      test "event #{schema} captures all spec fields" do
        assert_fields_covered(unquote(schema), unquote(type), &Webhook.parse_event/1)
      end
    end
  end
end
