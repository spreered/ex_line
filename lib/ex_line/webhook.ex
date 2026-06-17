defmodule ExLine.Webhook do
  @moduledoc """
  Parse incoming LINE webhook payloads into event structs.

  `parse/1` is **total — it never raises**. This is required for forward
  compatibility: LINE adds new event/message types, enum values, and fields without
  notice, and the server must keep working
  ([dev guidelines](https://developers.line.biz/en/docs/messaging-api/development-guidelines/)).
  Accordingly:

    * an unrecognized event/message `type` degrades to `ExLine.Webhook.UnknownEvent` /
      `ExLine.Webhook.Message.Unknown` (mirroring the official SDKs),
    * unknown fields are ignored (the original payload is kept in each struct's `raw`),
    * a single malformed event degrades to `UnknownEvent` rather than failing the batch.

  Verify the signature first with `ExLine.Webhook.Signature` / `ExLine.Webhook.Plug`.

  ## Example

      body |> Jason.decode!() |> ExLine.Webhook.parse() |> Enum.each(&MyRouter.call/1)

  Ref: https://developers.line.biz/en/reference/messaging-api/#webhook-event-objects
  """

  alias ExLine.Webhook.{
    FollowEvent,
    JoinEvent,
    LeaveEvent,
    MemberJoinedEvent,
    MemberLeftEvent,
    Message,
    MessageEvent,
    PostbackEvent,
    Source,
    UnfollowEvent,
    UnknownEvent
  }

  @type event ::
          MessageEvent.t()
          | PostbackEvent.t()
          | FollowEvent.t()
          | UnfollowEvent.t()
          | JoinEvent.t()
          | LeaveEvent.t()
          | MemberJoinedEvent.t()
          | MemberLeftEvent.t()
          | UnknownEvent.t()

  @doc """
  Parses a decoded webhook request (`%{"events" => [...]}`) or a list of raw events
  into a list of event structs.
  """
  @spec parse(map() | [map()]) :: [event()]
  def parse(%{"events" => events}) when is_list(events), do: Enum.map(events, &parse_event/1)
  def parse(events) when is_list(events), do: Enum.map(events, &parse_event/1)
  def parse(_), do: []

  @doc """
  Parses a single raw event map into an event struct. Never raises — anything it
  can't model becomes an `UnknownEvent`.
  """
  @spec parse_event(map()) :: event()
  def parse_event(raw) when is_map(raw) do
    do_parse_event(raw)
  rescue
    _ -> %UnknownEvent{type: Map.get(raw, "type"), raw: raw}
  end

  def parse_event(raw), do: %UnknownEvent{type: nil, raw: raw}

  defp do_parse_event(%{"type" => "message"} = raw) do
    struct(MessageEvent, [
      {:reply_token, raw["replyToken"]},
      {:message, Message.parse(raw["message"])} | common(raw)
    ])
  end

  defp do_parse_event(%{"type" => "postback"} = raw) do
    struct(PostbackEvent, [
      {:reply_token, raw["replyToken"]},
      {:postback, postback(raw["postback"])} | common(raw)
    ])
  end

  defp do_parse_event(%{"type" => "follow"} = raw) do
    struct(FollowEvent, [
      {:reply_token, raw["replyToken"]},
      {:follow, raw["follow"]} | common(raw)
    ])
  end

  defp do_parse_event(%{"type" => "unfollow"} = raw), do: struct(UnfollowEvent, common(raw))

  defp do_parse_event(%{"type" => "join"} = raw) do
    struct(JoinEvent, [{:reply_token, raw["replyToken"]} | common(raw)])
  end

  defp do_parse_event(%{"type" => "leave"} = raw), do: struct(LeaveEvent, common(raw))

  defp do_parse_event(%{"type" => "memberJoined"} = raw) do
    struct(MemberJoinedEvent, [
      {:reply_token, raw["replyToken"]},
      {:joined, members(raw["joined"])} | common(raw)
    ])
  end

  defp do_parse_event(%{"type" => "memberLeft"} = raw) do
    struct(MemberLeftEvent, [{:left, members(raw["left"])} | common(raw)])
  end

  defp do_parse_event(%{"type" => type} = raw),
    do: struct(UnknownEvent, [{:type, type} | common(raw)])

  defp do_parse_event(raw), do: %UnknownEvent{type: nil, raw: raw}

  # Common envelope shared by every event. `type` is included so concrete structs
  # carry it too.
  defp common(raw) do
    [
      type: raw["type"],
      mode: raw["mode"],
      timestamp: raw["timestamp"],
      source: Source.parse(raw["source"]),
      webhook_event_id: raw["webhookEventId"],
      delivery_context: raw["deliveryContext"],
      raw: raw
    ]
  end

  defp postback(%{"data" => data} = pb), do: %{data: data, params: pb["params"]}
  defp postback(pb), do: pb

  defp members(%{"members" => members}) when is_list(members) do
    %{members: Enum.map(members, &Source.parse/1)}
  end

  defp members(other), do: other
end
